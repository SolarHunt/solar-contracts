// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ICharityID} from "./interfaces/ICharityID.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TreasureHunt Contract
 * @author SolarHunt Team @ ETHCC23 Prague Hackathon
 */
contract TreasureHunt is AccessControl, ReentrancyGuard {
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
        uint256 numParticipants;
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
    function createTreasureHunt(
        uint256 _charityId,
        string calldata _treasureHuntCid,
        uint256 _depositAmount,
        bytes32 _secretCodeHash
    ) public onlyCharityOwner(_charityId) returns (uint256) {
        charityIdContrat.isValid(_charityId);

        return _createTreasureHunt(Status.Opened, _charityId, _depositAmount, _treasureHuntCid, _secretCodeHash);
    }

    // update createTreasureHuntFromCharity to allow the charity to update the bounty amount
    function updateTreasureHunt(
        uint256 _charityId,
        uint256 _treasureHuntId,
        string calldata _newTreasureHuntCid
    ) public onlyCharityOwner(_charityId) returns (uint256) {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");
        require(bytes(_newTreasureHuntCid).length == 46, "Invalid cid");

        require(
            treasureHunts[_treasureHuntId].charityId == charityIdContrat.ids(msg.sender),
            "You're not the owner of this TreasureHunt"
        );

        treasureHunts[_treasureHuntId].cid = _newTreasureHuntCid;

        emit TreasureHuntDetailedUpdated(_treasureHuntId, _newTreasureHuntCid);
    }

    function closeTreasureHunt(uint256 _charityId, uint256 _treasureHuntId) public onlyCharityOwner(_charityId) {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");

        require(
            treasureHunts[_treasureHuntId].charityId == charityIdContrat.ids(msg.sender),
            "You're not the owner of this TreasureHunt"
        );

        treasureHunts[_treasureHuntId].status = Status.Closed;

        emit TreasureHuntClosed(_treasureHuntId);
    }

    /**
     * @notice Update handle address mapping and emit event after mint.
     * @param _treasureHuntId the id of the TreasureHunt
     * @param _secretCodeHash the secret code for the TreasureHunt
     * @return uint256 returns the id of the newly created Treasure Hunt
     */

    function claimTreasureHunt(uint256 _treasureHuntId, bytes32 _secretCodeHash) public nonReentrant returns (uint256) {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");

        require(_secretCodeHash == treasureHunts[_treasureHuntId].secretCodeHash, "The secret code is not correct");

        treasureHunts[_treasureHuntId].status = Status.Closed;

        // calculate and transfer the bounty to the charity and the player and the contract
        uint256 totalBounty = treasureHunts[_treasureHuntId].totalTreasureHuntDeposit;

        // Calculate the contract's gain (1% of the total bounty)
        uint256 contractAmount = totalBounty / 100;
        totalBounty -= contractAmount; // subtract contract's share from total bounty

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
     * @param secretCodeHash The hashed version of the secret code for the TreasureHunt
     * @return uint256 The id of the newly created TreasureHunt
     */

    function _createTreasureHunt(
        Status _status,
        uint256 _charityId,
        uint256 _depositAmount,
        string calldata _treasureHuntCid,
        bytes32 secretCodeHash
    ) private returns (uint256) {
        require(bytes(_treasureHuntCid).length == 46, "Invalid cid");

        uint256 id = nextTreasureHuntId;
        nextTreasureHuntId++;

        TreasureHunt storage treasureHunt = treasureHunts[id];
        treasureHunt.status = Status.Opened;
        treasureHunt.charityId = _charityId;
        treasureHunt.depositAmount = _depositAmount;
        treasureHunt.cid = _treasureHuntCid;
        treasureHunt.secretCodeHash = secretCodeHash;

        emit treasureHuntCreated(Status.Opened, id, _charityId, _depositAmount, _treasureHuntCid, secretCodeHash);

        return id;
    }

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
        require(msg.value > 0, "You must deposit more than 0");

        // require(msg.value == treasureHunts[_treasureHuntId].depositAmount, "Incorrect deposit amount"); DEPRECATED
        // we don't want limited the amount of the donation

        // Add the deposit to the total bounty amount
        treasureHunts[_treasureHuntId].totalTreasureHuntDeposit += msg.value;

        // Keep track of the player's deposit for this treasure hunt
        treasureHuntPlayerDeposit[_treasureHuntId][msg.sender] += msg.value;

        treasureHunts[_treasureHuntId].numParticipants++;

        emit DepositToParticipateDone(msg.sender, msg.value, _treasureHuntId);
    }

    // Fallback function to prevent from sending ether to the contract
    receive() external payable {
        revert("Please use the depositBountyAmount function to deposit ethers");
    }

    /**
     * Withdraws the contract balance to the admin.
     */
    function withdraw(address _solarFundAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool sent, ) = payable(_solarFundAddress).call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");

        emit WithdrawDone(_solarFundAddress, address(this).balance);
    }

    // =========================== Modifiers ==============================

    /**
     * @notice Check if msg sender is the owner of a platform
     * @param _charityId The ID of the Charity
     */
    modifier onlyCharityOwner(uint256 _charityId) {
        require(charityIdContrat.ownerOf(_charityId) == msg.sender, "Not the owner");
        _;
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

    /// @notice Emitted when a player makes a deposit to participate in a treasure hunt
    /// @param playerAddress The address of the player
    /// @param amountDeposit The amount deposited by the player
    /// @param treasureHuntId The ID of the treasure hunt
    event DepositToParticipateDone(address indexed playerAddress, uint256 amountDeposit, uint256 treasureHuntId);

    /// @notice Emitted when the details of a treasure hunt are updated
    /// @param treasureHuntId The ID of the treasure hunt
    /// @param newTreasureHuntCid The new content identifier (CID) of the treasure hunt
    event TreasureHuntDetailedUpdated(uint256 indexed treasureHuntId, string newTreasureHuntCid);

    /// @notice Emitted when a treasure hunt is claimed by a player
    /// @param treasureHuntId The ID of the treasure hunt
    /// @param player The address of the player who claimed the treasure hunt
    event TreasureHuntClaimed(uint256 indexed treasureHuntId, address indexed player);

    /// @notice Emitted when a treasure hunt is closed
    /// @param treasureHuntId The ID of the treasure hunt
    event TreasureHuntClosed(uint256 indexed treasureHuntId);

    /// @notice Emitted when an amount is withdrawn from the solar fund
    /// @param solarFundAddress The address of the solar fund
    /// @param amountWithdrawn The amount withdrawn from the solar fund
    event WithdrawDone(address indexed solarFundAddress, uint256 amountWithdrawn);
}
