// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICharityID {
    struct Charity {
        uint256 id;
        string name;
        string cid;
        uint256 charityGain;
    }

    function takenCharityNames(string calldata) external view returns (bool);

    function charities(uint256) external view returns (Charity memory);

    function ids(address) external view returns (uint256);

    function getCharity(uint256 _charityId) external view returns (Charity memory);

    function totalSupply() external view returns (uint256);

    function updateProfileData(uint256 _charityId, string memory _newCid) external;

    function updatecharityGain(uint256 _charityId, uint256 _charityGain) external;

    function mintForAddress(string calldata _charityName, address _charityAddress) external payable returns (uint256);

    function isValid(uint256 _charityId) external view;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    event CidUpdated(uint256 indexed _tokenId, string _newCid);
    event CharityGainUpdated(uint256 _charityId, uint256 _charityGain);
    event Mint(address indexed _charityAddress, uint256 charityId, string _charityName);
}
