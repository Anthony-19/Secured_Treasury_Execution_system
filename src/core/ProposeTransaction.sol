// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import {Treasury} from "src/core/Treasury.sol";
import {ITimeLock} from "src/interfaces/ITimeLock.sol";
import {Errors} from "src/libraries/Errors.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract ProposeTransaction is ReentrancyGuard {

    Treasury public treasury;

    ITimeLock public timeLock;

    event  TransactionProposed(uint indexed proposalCounts, address indexed from, address _recipient, uint _value, uint _amount);

    event TransactionApproved(uint indexed transactionId, address indexed approver);

    event TransactionExecuted(uint indexed transactionId);

    event TransactionCancelled(uint indexed transactionId);

    struct Transaction {
        uint id;

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
       if (!isApprover) revert Errors.NotApprover(msg.sender);
        _;
    }

    constructor(uint _noOfSigners, uint _quorum, address[] memory _approver, address _timeLock, address _treasury) {
        approvers = _approver;
        noOfSigners = _noOfSigners;
        quorum = _quorum;
        timeLock = ITimeLock(_timeLock);
       treasury = Treasury(payable(_treasury));
    }

    function proposeTransaction (
        uint _value,
        address _recipient,
        uint _amount
       
    ) external payable nonReentrant{
            require(msg.value == 1 ether, "Proposal fee is 1 ether");
           
        proposalCounts += 1;
        proposedTransactions[proposalCounts] = Transaction({
            id: proposalCounts,
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

    function approveTransaction(uint _transactionId) external onlyApprovals payable{
        Transaction storage transaction = proposedTransactions[_transactionId];

        if (msg.value != 1 ether) revert Errors.InvalidProposalFee(msg.value);

        if (transaction.proposalFee != 1 ether) revert Errors.ProposalFeeNotPaid();

        if (transaction.proposer == msg.sender) revert Errors.ProposerCannotApprove();

         if (transaction.queue) revert Errors.TransactionAlreadyQueued(_transactionId);

        if (transaction.executed) revert Errors.TransactionAlreadyExecuted(_transactionId);

       if (transaction.cancelled) revert Errors.TransactionAlreadyCancelled(_transactionId);

      if (approvedTransactions[_transactionId][msg.sender]) {
    revert Errors.TransactionAlreadyApproved(_transactionId, msg.sender);
}

        approvedTransactions[_transactionId][msg.sender] = true;

        transaction.noOfApprovals += 1;

        if(transaction.noOfApprovals >= quorum && !transaction.queue){
           transaction.queue = true;
           transaction.stopTime = block.timestamp + timeLock.getLockTime();
        }
    }

    function execute(uint _transactionId) external{
         Transaction storage transaction = proposedTransactions[_transactionId];

        if (!transaction.queue) revert Errors.TransactionNotQueued(_transactionId);

        if (transaction.executed) revert Errors.TransactionAlreadyExecuted(_transactionId);

      if (transaction.cancelled) revert Errors.TransactionAlreadyCancelled(_transactionId);

        if (block.timestamp < transaction.stopTime) {
    revert Errors.TimelockNotExpired(transaction.stopTime);
}

        treasury.proposalWithdrawal(transaction.recipient, transaction.amount);



        transaction.executed = true;

        emit TransactionExecuted(_transactionId);
    }


    function cancel(uint _transactionId) external onlyApprovals{
        Transaction storage transaction = proposedTransactions[_transactionId];

        if (transaction.executed) revert Errors.TransactionAlreadyExecuted(_transactionId);

        if (transaction.cancelled) revert Errors.TransactionAlreadyCancelled(_transactionId);

        transaction.cancelled = true;

        (bool success,) = payable(transaction.proposer).call{value: transaction.proposalFee}("");

        if (!success) revert Errors.RefundFailed();

        // delete proposedTransactions[_transactionId];

        emit TransactionCancelled(_transactionId);

    }

    receive() external payable {
       
    }
    fallback() external payable {
        
    }
}