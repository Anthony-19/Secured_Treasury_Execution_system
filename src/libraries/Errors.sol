//SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Errors {
    error NotApprover(address caller);
    error InvalidProposalFee(uint sent);
    error ProposalFeeNotPaid();
    error ProposerCannotApprove();
    error TransactionAlreadyQueued(uint id);
    error TransactionAlreadyExecuted(uint id);
    error TransactionAlreadyCancelled(uint id);
    error TransactionAlreadyApproved(uint id, address approver);
    error TransactionNotQueued(uint id);
    error TimelockNotExpired(uint stopTime);
    error RefundFailed();
    error InvalidLockTime(uint providedLockTime);
    error ZeroAddress();
    error InvalidAmount(uint amount);
    error InsufficientBalance(uint available, uint required);
    error TreasuryInsufficientBalance(uint available, uint required);
    error TokenTransferFailed();
    error UnauthorizedCaller(address caller);
}
