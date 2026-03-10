// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TimeLock {
    uint public lockTime;

    function setLockTime(uint _lockTime) external {
        require(_lockTime > 0, "Lock time must be greater than 0");
        lockTime = _lockTime;
       
    }

    function getLockTime() external view returns (uint) {
        return lockTime;
    }
}
