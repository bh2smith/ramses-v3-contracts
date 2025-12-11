// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

abstract contract IRewardValidator {
    function validateReward(address x, address y, bytes32 z, address a, uint256 _a, int24 _b, int24 _c, address _d) public virtual returns (bool);
    function setNfpManager(address x) public virtual;
}
