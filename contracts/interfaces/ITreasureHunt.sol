// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITreasureHunt {
    // =========================== Struct ==============================
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

    // =========================== Events ==============================
    event treasureHuntCreated(
        Status status,
        uint256 id,
        uint256 charityId,
        uint256 bountyAmount,
        string treasureHuntCid,
        bytes32 secretCodeHash
    );

    event DepositToParticipateDone(address playerAddress, uint256 amountDeposit, uint256 treasureHuntId);

    event TreasureHuntDetailedUpdated(uint256 indexed treasureHuntId, string newTreasureHuntCid);

    event TreasureHuntClaimed(uint256 indexed treasureHuntId, address indexed player);

    event TreasureHuntClosed(uint256 indexed treasureHuntId);

    // =========================== View functions ==============================
    function getTreasureHunt(uint256 _treasureHuntId) external view returns (TreasureHunt memory);

    // =========================== User functions ==============================
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

    function claimTreasureHunt(uint256 _treasureHuntId, bytes32 _secretCodeHash) external returns (uint256);

    // =========================== Player function ==============================
    function depositAmountToParticipate(uint256 _treasureHuntId) external payable;

    // Withdraw the contract balance to the admin.
    function withdraw(address _solarFundAddress) external;
}
