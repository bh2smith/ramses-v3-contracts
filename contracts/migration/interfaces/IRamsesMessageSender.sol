// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IRamsesMessageSender {
    /// @dev parameters of the x-chain msg
    struct LocalParameters {
        address user;
        uint256 amountAirdropped;
    }
    /// @notice function to go to HyperEVM
    function shuttle(uint256 _veID) external payable;
    
    /// @notice function to collect veNFTs from migration for burning
    function collect(address[] calldata _to, uint256[] calldata _veIDs) external;
    
    /// @notice function to populate users with their locked and virtual amounts
    /// @param _users Array of user addresses
    /// @param _lockedAmounts Array of minimum veRAM locked amounts for validation
    /// @param _virtualAmounts Array of virtual amounts to migrate (can include bonuses)
    function populate(
        address[] memory _users,
        uint256[] memory _lockedAmounts,
        uint256[] memory _virtualAmounts
    ) external;
    
    /// @notice function to pause the shuttle
    function pause(bool _paused) external;
    
    /// @notice function to override the end time
    function overrideEndTime(uint256 _endTime) external;
    
    /// @notice function to set the default gas
    function setDefaultGas(uint128 _defaultGas) external;
}
