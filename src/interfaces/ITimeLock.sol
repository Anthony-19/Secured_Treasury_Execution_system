// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface ITimeLock {
   function getLockTime() external view returns (uint);
}