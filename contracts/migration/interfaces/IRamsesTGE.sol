// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IRamsesTGE {
    /// @notice Claim operation types
    enum OperationType {
        EXIT,        // 0: exit xRAM and claim underlying RAM
        CLAIM_XRAM   // 1: claim as xRAM
    }

    /// @dev parameters of the x-chain msg
    struct LocalParameters {
        address user;
        uint256 amountAirdropped;
    }

    function claimVe(OperationType _operationType) external;

    function claimRXP(OperationType _operationType) external;

    function claimHypurrs(OperationType _operationType) external;

    function rescue(address tokenAddress, uint256 amount) external;

    function rescueAll() external;

    function setXRam(address _xRam) external;

    function veRamClaimable(address) external view returns (uint256);

    function populateRXP(address[] memory _users, uint256[] memory _amounts) external;

    function populateHypurrs(address[] memory _users, uint256[] memory _amounts) external;

    function rxpClaimable(address) external view returns (uint256);

    function hypurrsClaimable(address) external view returns (uint256);

    function userAirdroppedTotal(address) external view returns (uint256);
}
