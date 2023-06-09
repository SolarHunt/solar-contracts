// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Charity ID Contract
 * @author SolarHunt Team @ ETHCC23 Prague Hackathon
 */
contract CharityID is ERC721, AccessControl {
    using Counters for Counters.Counter;

    uint8 constant MIN_HANDLE_LENGTH = 5;
    uint8 constant MAX_HANDLE_LENGTH = 31;

    // =========================== Structs ==============================

    /// @notice Charity information struct
    /// @param id the ID of the charity
    /// @param name the name of the charity
    /// @param cid the IPFS CID of the charity metadata
    /// @param charityGain the percentage of the pool that the charity will receive
    struct Charity {
        uint256 id;
        string name;
        string cid;
        uint256 charityGain;
    }

    /**
     * @notice Taken Charity name
     */
    mapping(string => bool) public takenCharityNames;

    /**
     * @notice Charity ID to Charity struct
     */
    mapping(uint256 => Charity) public charities;

    /**
     * @notice Address to CharityId
     */
    mapping(address => uint256) public ids;

    /**
     * @notice Charity Id counter
     */
    Counters.Counter private _nextCharityId;

    /**
     * @notice Role granting Minting permission
     */
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    // =========================== Errors ==============================

    /**
     * @notice error thrown when input handle is 0 or more than 31 characters long.
     */
    error HandleLengthInvalid();

    /**
     * @notice error thrown when input handle contains restricted characters.
     */
    error HandleContainsInvalidCharacters();

    /**
     * @notice error thrown when input handle has an invalid first character.
     */
    error HandleFirstCharInvalid();

    // =========================== Constructor ==============================

    constructor() ERC721("CharityID", "CHID") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINT_ROLE, msg.sender);

        _nextCharityId.increment(); // we start the CharityID at 1
    }

    // =========================== View functions ==============================

    function getCharity(uint256 _charityId) external view returns (Charity memory) {
        isValid(_charityId);
        return charities[_charityId];
    }

    /**
     * @dev Returns the total number of Charity ID in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _nextCharityId.current() - 1;
    }

    // =========================== User functions ==============================

    function updateProfileData(uint256 _charityId, string memory _newCid) public onlyCharityOwner(_charityId) {
        require(bytes(_newCid).length == 46, "Invalid cid");
        isValid(_charityId);
        charities[_charityId].cid = _newCid;

        emit CidUpdated(_charityId, _newCid);
    }

    /**
     * @notice Allows a Charity to update the
     * @param _charityId Charity ID to update
     * @param _charityGain New charity gain
     */
    function updatecharityGain(uint256 _charityId, uint256 _charityGain) public onlyCharityOwner(_charityId) {
        charities[_charityId].charityGain = _charityGain;
        emit CharityGainUpdated(_charityId, _charityGain);
        // TODO : possible only of the TH status is closed
    }

    // =========================== SolarFund functions ==============================

    /**
     * @notice Mint a new Charity ID for Charity
     * @dev You need to have MINT_ROLE to use this function
     * @param _charityName Charity name
     * @param _charityAddress Address to assign the Charity Id to
     */

    function mintForAddress(
        string calldata _charityName,
        address _charityAddress
    ) public payable canMint(_charityName, _charityAddress) onlyRole(MINT_ROLE) returns (uint256) {
        _mint(_charityAddress, _nextCharityId.current());
        return _afterMint(_charityName, _charityAddress);
    }

    // TODO : add a function to add differnte to the MintRoll and remove from Mint Role

    // =========================== Private functions ==============================

    /**
     * @notice Update Platform name mapping and emit event after mint.
     * @param _charityName Name of the platform
     */
    function _afterMint(string memory _charityName, address _charityAddress) private returns (uint256) {
        uint256 charityId = _nextCharityId.current();
        _nextCharityId.increment();
        Charity storage charity = charities[charityId];
        charity.name = _charityName;
        charity.id = charityId;
        takenCharityNames[_charityName] = true;
        ids[_charityAddress] = charityId;

        emit Mint(_charityAddress, charityId, _charityName);

        return charityId;
    }

    /**
     * @notice Validate characters used in the handle, only alphanumeric, only lowercase characters, - and _ are allowed but as first one
     * @param handle Handle to validate
     */
    function _validateHandle(string calldata handle) private pure {
        bytes memory byteHandle = bytes(handle);
        uint256 byteHandleLength = byteHandle.length;
        if (byteHandleLength < MIN_HANDLE_LENGTH || byteHandleLength > MAX_HANDLE_LENGTH) revert HandleLengthInvalid();

        bytes1 firstByte = bytes(handle)[0];
        if (firstByte == "-" || firstByte == "_") revert HandleFirstCharInvalid();

        for (uint256 i = 0; i < byteHandleLength; ) {
            if (
                (byteHandle[i] < "0" || byteHandle[i] > "z" || (byteHandle[i] > "9" && byteHandle[i] < "a")) &&
                byteHandle[i] != "-" &&
                byteHandle[i] != "_"
            ) revert HandleContainsInvalidCharacters();
            ++i;
        }
    }

    // =========================== External functions ==============================

    /**
     * @notice Check whether the Charity Id is valid.
     * @param _charityId Charity ID to validate
     */
    function isValid(uint256 _charityId) public view {
        require(_charityId > 0 && _charityId < _nextCharityId.current(), "Invalid platform ID");
    }

    // =========================== Overrides ==============================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721) {
        revert("Not allowed");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721) {
        revert("Not allowed");
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        return _buildTokenURI(tokenId);
    }

    /**
     * @notice Builds the token URI
     * @param id The ID of the token
     */
    function _buildTokenURI(uint256 id) internal view returns (string memory) {
        string memory charityName = string.concat(charities[id].name, ".fund");
        string memory fontSizeStr = bytes(charities[id].name).length <= 20 ? "60" : "40";

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg xmlns="http://www.w3.org/2000/svg" width="720" height="720"><rect width="100%" height="100%"/><svg xmlns="http://www.w3.org/2000/svg" width="150" height="150" version="1.2" viewBox="-200 -50 1000 1000"><path fill="#FFFFFF" d="M264.5 190.5c0-13.8 11.2-25 25-25H568c13.8 0 25 11.2 25 25v490c0 13.8-11.2 25-25 25H289.5c-13.8 0-25-11.2-25-25z"/><path fill="#FFFFFF" d="M265 624c0-13.8 11.2-25 25-25h543c13.8 0 25 11.2 25 25v56.5c0 13.8-11.2 25-25 25H290c-13.8 0-25-11.2-25-25z"/><path fill="#FFFFFF" d="M0 190.5c0-13.8 11.2-25 25-25h543c13.8 0 25 11.2 25 25V247c0 13.8-11.2 25-25 25H25c-13.8 0-25-11.2-25-25z"/></svg><text x="30" y="670" style="font: ',
                        fontSizeStr,
                        'px sans-serif;fill:#fff">',
                        charityName,
                        "</text></svg>"
                    )
                )
            )
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                charityName,
                                '", "image":"',
                                image,
                                unicode'", "description": "Charity ID"}'
                            )
                        )
                    )
                )
            );
    }

    // =========================== Modifiers ==============================

    /**
     * @notice Check if Platform is able to mint a new Platform ID.
     * @param _charityName name of the charity associated with the ID
     * @param _charityAddress address of the charity associated with the ID
     */
    modifier canMint(string calldata _charityName, address _charityAddress) {
        require(balanceOf(_charityAddress) == 0, "Charity already has a Charity ID");
        require(!takenCharityNames[_charityName], "Name already taken");

        _validateHandle(_charityName);
        _;
    }

    /**
     * @notice Check if msg sender is the owner of a platform
     * @param _charityId The ID of the Charity
     */
    modifier onlyCharityOwner(uint256 _charityId) {
        require(ownerOf(_charityId) == msg.sender, "Not the owner");
        _;
    }

    // =========================== Events ==============================

    /**
     * Emit when Cid is updated for a platform.
     * @param _tokenId Platform ID concerned
     * @param _newCid New URI
     */
    event CidUpdated(uint256 indexed _tokenId, string _newCid);

    /**
     * Emit after the arbitration fee timeout is updated for a platform
     * @param _charityId The ID of the Charity
     * @param _charityGain The new charity gain in %
     */
    event CharityGainUpdated(uint256 _charityId, uint256 _charityGain);

    /**
     * @notice Emit when new Platform ID is minted.
     * @param _charityAddress Address of the owner of the PlatformID
     * @param charityId The Platform ID
     * @param _charityName Name of the platform
     */
    event Mint(address indexed _charityAddress, uint256 charityId, string _charityName);
}
