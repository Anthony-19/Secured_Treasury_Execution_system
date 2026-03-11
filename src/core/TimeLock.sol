// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {Errors} from "src/libraries/Errors.sol";

contract TimeLock {
    uint public lockTime;

    function setLockTime(uint _lockTime) external {
        if (_lockTime == 0) revert Errors.InvalidLockTime(_lockTime);
        lockTime = _lockTime;
       
    }

    function getLockTime() external view returns (uint) {
        return lockTime;
    }
}
