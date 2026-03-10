// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {Treasury} from "src/Treasury.sol";
import {ITimeLock} from "src/interfaces/ITimeLock.sol";

contract ProposeTransaction {

    Treasury public treasury;
    ITimeLock public timeLock;

    event  TransactionProposed(uint indexed proposalCounts, address indexed from, address _recipient, uint _value, uint _amount);
    event TransactionApproved(uint indexed transactionId, address indexed approver);
    event TransactionExecuted(uint indexed transactionId);
    event TransactionCancelled(uint indexed transactionId);

    struct Transaction {
        uint id;

        uint nonce;

        uint value;

        address recipient;

        address proposer;

        uint amount; 

        uint proposalFee;

        uint noOfApprovals;

        uint threshold;

        bool queue;

        bool executed;

        bool cancelled;

        uint timeProposed;

        uint startTime;

        uint stopTime;
    }

    address[] public approvers;

    uint public proposalCounts;

    uint noOfSigners;

    uint quorum;

    mapping (uint => mapping(address => bool)) public approvedTransactions;
   

    mapping(uint => Transaction) public proposedTransactions;

    modifier onlyApprovals {
        bool isApprover = false;
        for (uint i = 0; i < approvers.length; i++) {
            if (approvers[i] == msg.sender) {
                isApprover = true;
                break;
            }
        }
        require(isApprover, "Sender is not an approver");
        _;
    }

    constructor(uint _noOfSigners, uint _quorum, address[] memory _approver, address _timeLock) {
        approvers = _approver;
        noOfSigners = _noOfSigners;
        quorum = _quorum;
        timeLock = ITimeLock(_timeLock);
    }

    function proposeTransaction (
        uint _value,
        address _recipient,
        uint _amount
       
    ) external payable{
            require(msg.value == 1 ether, "Proposal fee is 1 ether");
           
        proposalCounts += 1;
        proposedTransactions[proposalCounts] = Transaction({
            id: proposalCounts,
            nonce: proposalCounts,
            value: _value,
            recipient: _recipient,
            proposer: msg.sender,
            amount: _amount,
            noOfApprovals: 0,
            proposalFee: 1 ether,
            threshold: 0,
            queue: false,
            executed: false,
            cancelled: false,
            timeProposed: block.timestamp,
            startTime: 0,
            stopTime: 0
        });

        emit TransactionProposed(proposalCounts, msg.sender, _recipient, _value, _amount);
    }

    function approveTransaction(uint _transactionId) external onlyApprovals{
        Transaction storage transaction = proposedTransactions[_transactionId];

        require(transaction.proposalFee == 1 ether, "Pay up your proposal fee");

        require(transaction.proposer != msg.sender, "Proposer cannot approve their own transaction");

        require(!transaction.queue, "Transaction already queued");

        require(!transaction.executed, "Transaction already executed");

        require(!transaction.cancelled, "Transaction already cancelled");

        require(!approvedTransactions[_transactionId][msg.sender], "Transaction already approved by this signer");

        approvedTransactions[_transactionId][msg.sender] = true;

        transaction.noOfApprovals += 1;

        if(transaction.noOfApprovals >= quorum && !transaction.queue){
           transaction.queue = true;
           transaction.stopTime = block.timestamp + timeLock.getLockTime();
        }
    }

    function execute(uint _transactionId) external{
         Transaction storage transaction = proposedTransactions[_transactionId];

        require(transaction.queue, "Transaction not queued");

        require(!transaction.executed, "Already executed");

        require(!transaction.cancelled, "Cancelled");

        require(block.timestamp >= transaction.stopTime, "Timelock not passed");

        treasury.proposalWithdrawal(transaction.amount, transaction.recipient);

        (bool success, ) = transaction.recipient.call{value: transaction.value}("");

        require(success, "Execution failed");

        transaction.executed = true;

        emit TransactionExecuted(_transactionId);
    }


    function cancel(uint _transactionId) external onlyApprovals{
        Transaction storage transaction = proposedTransactions[_transactionId];

        require(!transaction.executed, "Already executed");

        require(!transaction.cancelled, "Already cancelled");

        transaction.cancelled = true;

        (bool success,) = payable(transaction.proposer).call{value: transaction.proposalFee}("");

        require(success, "Refund failed");

        delete proposedTransactions[_transactionId];

        emit TransactionCancelled(_transactionId);

    }

    receive() external payable {
       
    }
    fallback() external payable {
        
    }
}