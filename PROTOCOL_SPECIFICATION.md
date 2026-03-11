# Protocol Specification

## Protocol Lifecycle

The protocol has a lifecycle with five main stages: proposal creation, approval, queueing, timelock waiting, and execution or cancellation.

---

## 1. Proposal Creation

The lifecycle starts when a user submits a transaction proposal. To do this, the user calls `proposeTransaction`, providing the target recipient address, transfer amount, and transaction value. The user must pay **1 ether** as a fee to submit the proposal. This fee helps prevent spam proposals and ensures that only meaningful transactions are submitted.

When the proposal is created, it receives a unique identifier. A `Transaction` record is then stored, which includes the proposer, recipient, amount, timestamp, and approval state. An event is emitted to notify external systems that a new proposal has been created.

---

## 2. Transaction Approval

After a proposal is created, authorized governance participants can approve it. Only addresses included in the **approvers list** are allowed to approve transactions.

When an approver calls `approveTransaction`, the contract checks the following conditions:

- The caller must be an approver  
- The caller must not be the proposer  
- The proposal must not already be cancelled  
- The caller must not have previously approved the proposal  

If all conditions are satisfied, the approval is recorded and the proposal's approval counter is increased.

---

## 3. Quorum and Queueing

When the number of approvals reaches the required **quorum**, the proposal becomes **queued**.

At this stage:

- The proposal is marked as queued  
- A `stopTime` is calculated  
- The proposal cannot yet be executed; it is scheduled for execution once the timelock expires  

---

## 4. Timelock Waiting Period

The **timelock mechanism** delays the execution of approved proposals. During this period, governance participants have time to inspect the transaction.

If suspicious activity is detected, authorized approvers can cancel the proposal before execution.

The timelock delay defines how long the system must wait before the transaction can be executed.

---

## 5. Execution

Once the timelock period has expired, any user can execute the proposal by calling the `execute` function.

Before execution, the contract verifies that:

- The proposal has been queued  
- The timelock period has passed  
- The transaction has not already been cancelled  

If all conditions are satisfied, the treasury transfers the specified amount to the recipient. The proposal is then marked as **executed**, and an execution event is emitted.

---

## 6. Cancellation

Authorized approvers can cancel a proposal before execution.

When a proposal is cancelled:

- The proposal state is marked as **cancelled**  
- The proposal fee is **refunded to the proposer**  
- The stored transaction data is **deleted**  

This mechanism allows governance participants to stop malicious or incorrect proposals before they affect treasury funds.