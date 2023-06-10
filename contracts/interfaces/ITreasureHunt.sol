// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITreasureHunt {
    enum Status {
        Opened,
        Closed
    }

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

    function nextTreasureHuntId() external view returns (uint256);

    function getTreasureHunt(uint256 _treasureHuntId) external view returns (TreasureHunt memory);

    function createTreasureHunt(
        uint256 _charityId,
        string calldata _treasureHuntCid,
        uint256 _depositAmount,
        bytes32 _secretCodeHash
    ) external returns (uint256);

    function updateTreasureHunt(
        uint256 _charityId,
        uint256 _treasureHuntId,
        string calldata _newTreasureHuntCid
    ) external returns (uint256);

    function closeTreasureHunt(uint256 _charityId, uint256 _treasureHuntId) external;

    function checkIfWin(uint256 _treasureHuntId, bytes32 _secretCodeHash) external view returns (bool);

    function customClaimTreasureHunt(
        uint256 _treasureHuntId,
        bytes32 _secretCodeHash,
        uint256 _amountPlayerGive
    ) external;

    function depositAmountToParticipate(uint256 _treasureHuntId) external payable;

    function withdraw(address _solarFundAddress) external;
}
