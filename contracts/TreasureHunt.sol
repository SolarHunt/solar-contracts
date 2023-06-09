// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ICharityID} from "./interfaces/ICharityID.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title TreasureHunt Contract
 * @author SolarHunt Team @ ETHCC23 Prague Hackathon
 */
contract TreasureHunt is AccessControl {
    // =========================== Enum ==============================

    /// @notice Enum Treasure Hunt
    enum Status {
        Opened,
        Closed
    }

    // =========================== Struct ==============================

    /// @notice TreasureHunt information struct
    /// @param id The unique ID for a TreasureHunt
    /// @param charityId The unique ID associated with the charity for this TreasureHunt
    /// @param depositAmount the amout a user must deposit to participate to the TreasureHunt
    /// @param cid Content Identifier on IPFS for this TreasureHunt
    /// @param totalDeposit The total amount of deposit made for this TreasureHunt
    /// @param secretCode The secret code hash for this TreasureHunt (keccak256(secretCode)
    struct TreasureHunt {
        Status status;
        uint256 id;
        uint256 charityId;
        uint256 depositAmount;
        string cid;
        uint256 totalTreasureHuntDeposit;
        bytes32 secretCodeHash;
    }

    /// @notice incremental service Id
    uint256 public nextTreasureHuntId = 1;

    /// Charity  ID contarct instance
    ICharityID public charityIdContrat;

    /// @notice Treasure Hunt mappings index by ID
    mapping(uint256 => TreasureHunt) public treasureHunts;

    // Treasure hunt -> Player -> Deposit
    mapping(uint256 => mapping(address => uint256)) public treasureHuntPlayerDeposit;

    /**
     * @param _charityContractAddress TalentLayerId address
     */
    constructor(address _charityContractAddress) {
        charityIdContrat = ICharityID(_charityContractAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================== View functions ==============================

    /**
     * @notice Return the whole service data information
     * @param _treasureHuntId Treasure Hunt identifier
     * @return TreasureHunt returns the TreasureHunt struct
     */
    function getTreasureHunt(uint256 _treasureHuntId) external view returns (TreasureHunt memory) {
        require(_treasureHuntId < nextTreasureHuntId, "This treasure Hunt doesn't exist");
        return treasureHunts[_treasureHuntId];
    }

    // =========================== User functions ==============================

    /**
     * @notice Update handle address mapping and emit event after mint.
     * @param _charityId the charityId of the charity
     * @param _depositAmount the bounty amount for the Treasure Hunt
     * @param _treasureHuntCid Content Identifier on IPFS for this TreasureHunt
     * @param _secretCodeHash Hashed version of the secret code for this TreasureHunt
     * @return uint256 returns the id of the newly created Treasure Hunt
     */
    function createTreasureHuntFromCharity(
        uint256 _charityId,
        string calldata _treasureHuntCid,
        uint256 _depositAmount,
        string memory _secretCodeHash
    ) public returns (uint256) {
        charityIdContrat.isValid(_charityId);

        return _createTreasureHunt(Status.Opened, _charityId, _depositAmount, _treasureHuntCid, _secretCodeHash);
    }

    // create an update createTreasureHuntFromCharity to allow the charity to update the bounty amount
    function updateTreasureHuntFromCharity(
        uint256 _treasureHuntId,
        string calldata _newTreasureHuntCid
    ) public returns (uint256) {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");

        require(
            treasureHunts[_treasureHuntId].charityId == charityIdContrat.ids(msg.sender),
            "You're not the owner of this TreasureHunt"
        );

        treasureHunts[_treasureHuntId].cid = _newTreasureHuntCid;

        emit TreasureHuntDetailedUpdated(_treasureHuntId, _newTreasureHuntCid);
    }

    // i want to make a function that if the user propose a secretHash that match with the secret hash of the treasure hunt then the user can claim a % of the bouty based on the amount of deposit he made and the % the charity set up in the CharityId contract

    /**
     * @notice Update handle address mapping and emit event after mint.
     * @param _treasureHuntId the id of the TreasureHunt
     * @param _secretCode the secret code for the TreasureHunt
     * @return uint256 returns the id of the newly created Treasure Hunt
     */
    // TODO reeantranycy attack add OZ
    function claimTreasureHunt(uint256 _treasureHuntId, string memory _secretCode) public returns (uint256) {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");

        require(
            keccak256(abi.encodePacked(_secretCode)) ==
                keccak256(abi.encodePacked(treasureHunts[_treasureHuntId].secretCodeHash)),
            "The secret code is not correct"
        );

        treasureHunts[_treasureHuntId].status = Status.Closed;

        // calculate and transfer the bounty to the charity and the player
        uint256 totalBounty = treasureHunts[_treasureHuntId].totalTreasureHuntDeposit;
        uint256 charityGain = charityIdContrat.charities(treasureHunts[_treasureHuntId].charityId).charityGain;
        uint256 charityAmount = (totalBounty * charityGain) / 100;
        uint256 playerAmount = totalBounty - charityAmount;

        (bool charitySent, ) = payable(charityIdContrat.ownerOf(treasureHunts[_treasureHuntId].charityId)).call{
            value: charityAmount
        }("");
        require(charitySent, "Failed to send bounty to charity");

        (bool playerSent, ) = payable(msg.sender).call{value: playerAmount}("");
        require(playerSent, "Failed to send bounty to player");

        // Reset the totalTreasureHuntDeposit to 0 as the funds have been distributed
        treasureHunts[_treasureHuntId].totalTreasureHuntDeposit = 0;

        emit TreasureHuntClaimed(_treasureHuntId, msg.sender);
    }

    // =========================== Private functions ==============================

    /**
     * @notice Creates a new TreasureHunt and emits the TreasureHuntCreated event.
     * @param _status The status of the TreasureHunt
     * @param _charityId The id of the associated charity
     * @param _depositAmount The amount of the deposit for the TreasureHunt
     * @param _treasureHuntCid The IPFS content identifier for the TreasureHunt
     * @param _secretCode The hashed version of the secret code for the TreasureHunt
     * @return uint256 The id of the newly created TreasureHunt
     */
    // TODO need to hash the secret code in the front end all tyhe secret here are bytes32
    function _createTreasureHunt(
        Status _status,
        uint256 _charityId,
        uint256 _depositAmount,
        string calldata _treasureHuntCid,
        string memory _secretCode
    ) private returns (uint256) {
        // TODO check the length of the cid 42 or 46
        require(bytes(_treasureHuntCid).length > 0, "Should provide a valid IPFS URI");

        uint256 id = nextTreasureHuntId;
        nextTreasureHuntId++;

        TreasureHunt storage treasureHunt = treasureHunts[id];
        treasureHunt.status = Status.Opened;
        treasureHunt.charityId = _charityId;
        treasureHunt.depositAmount = _depositAmount;
        treasureHunt.cid = _treasureHuntCid;
        treasureHunt.secretCodeHash = keccak256(abi.encodePacked(_secretCode));

        //TODO : do i need to pass the status in the event
        emit treasureHuntCreated(
            Status.Opened,
            id,
            _charityId,
            _depositAmount,
            _treasureHuntCid,
            treasureHunt.secretCodeHash
        );

        return id;
    }

    // TODO : add a close TH button the a claim back button for player

    // =========================== Player function ==============================

    /**
     * @notice Allows a player to deposit a specified amount of Ether to participate in a Treasure Hunt.
     * The deposited amount is added to the total bounty of the Treasure Hunt and recorded as the player's contribution.
     * @dev This function is payable, allowing it to receive Ether along with the transaction.
     * The value sent is in Wei, and it gets added to the total bounty of the Treasure Hunt and to the player's contribution for this Treasure Hunt.
     * @param _treasureHuntId The unique ID of the Treasure Hunt that the player wishes to participate in.
     */
    function depositAmountToParticipate(uint256 _treasureHuntId) public payable {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");
        require(msg.value == treasureHunts[_treasureHuntId].depositAmount, "Incorrect deposit amount");

        //TODO make possible to deposit whatever amount you want
        // Add the deposit to the total bounty amount
        treasureHunts[_treasureHuntId].totalTreasureHuntDeposit += msg.value;

        // Keep track of the player's deposit for this treasure hunt
        treasureHuntPlayerDeposit[_treasureHuntId][msg.sender] += msg.value;
    }

    // Fallback function to prevent from sending ether to the contract
    receive() external payable {
        revert("Please use the depositBountyAmount function to deposit ethers");
    }

    // TODO add the 1% of the total bounty to the charity

    /**
     * Withdraws the contract balance to the admin.
     */
    function withdraw(address _solarFundAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool sent, ) = payable(_solarFundAddress).call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");
    }

    // =========================== Events ==============================

    /// @notice Emitted after a new TreasureHunt is created
    /// @param id The TreasureHunt ID (incremental)
    /// @param status The current status of the TreasureHunt
    /// @param charityId The unique ID associated with the charity for this TreasureHunt
    /// @param bountyAmount The amount of bounty for the TreasureHunt
    /// @param treasureHuntCid Content Identifier on IPFS for this TreasureHunt
    /// @param secretCodeHash Hashed version of the secret code for this TreasureHunt
    event treasureHuntCreated(
        Status status,
        uint256 id,
        uint256 charityId,
        uint256 bountyAmount,
        string treasureHuntCid,
        bytes32 secretCodeHash
    );

    ///Emit when Cid is updated for a Service
    ///@param treasureHuntId The service ID
    ///@param newTreasureHuntCid The new IPFS CID for the TreasureHunt

    event TreasureHuntDetailedUpdated(uint256 indexed treasureHuntId, string newTreasureHuntCid);

    event TreasureHuntClaimed(uint256 indexed treasureHuntId, address indexed player);
}
