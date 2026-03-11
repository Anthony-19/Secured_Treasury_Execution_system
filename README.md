# Treasury Execution System

This project implements a **multi-signature treasury management system** with proposal approvals, timelock execution, and incentive claiming via Merkle proofs. It is written in Solidity 0.8.23 and tested using Foundry (`forge`).

---

## Features

1. **ProposeTransaction**

   * Users can propose transactions with a **proposal fee**.
   * Approved by a quorum of **designated approvers**.
   * Executed only after a **timelock** enforced by `TimeLock`.
   * Supports canceling proposals with automatic refund of the proposal fee.

2. **Treasury**

   * Holds and manages ERC20 tokens.
   * Allows deposits and withdrawals.
   * Handles **proposal withdrawals** when transactions are executed.

3. **TimeLock**

   * Stores a configurable timelock duration.
   * Ensures proposals cannot execute immediately.

4. **ClaimIncentives**

   * Users can claim ERC20 rewards using **Merkle proofs**.
   * Prevents double claims.
   * Admin can update the Merkle root.

5. **Errors Library**

   * Centralizes custom error messages used across contracts for **gas-efficient error handling**.

---

## Installation

```bash
clone <[repo-url](https://github.com/Anthony-19/Secured_Treasury_Execution_system)>
cd project
forge install
forge build
```

---

## Testing

* Run all unit and exploit tests:

```bash
forge test
```

---

## Contract Overview

| Contract             | Description                                                            |
| -------------------- | ---------------------------------------------------------------------- |
| `ProposeTransaction` | Handles transaction proposals, approvals, execution, and cancellation. |
| `Treasury`           | Manages token deposits, withdrawals, and proposal withdrawals.         |
| `TimeLock`           | Provides configurable timelock duration for proposals.                 |
| `ClaimIncentives`    | Allows users to claim ERC20 rewards via Merkle proof verification.     |
| `Errors`             | Central library for custom error messages.                             |
| `IERC20`             | ERC20 interface.                                                       |
| `ITimeLock`          | Interface for the TimeLock contract.                                   |

---

## Usage

1. Deploy `Treasury` with ERC20 token address.
2. Deploy `TimeLock` and set a timelock duration.
3. Deploy `ProposeTransaction` with:

   * List of approvers
   * Quorum number
   * Treasury address
   * TimeLock address
4. Users can submit proposals using `proposeTransaction`.
5. Approvers approve proposals using `approveTransaction`.
6. Execute proposals after timelock using `execute`.
7. Users can claim incentives via `ClaimIncentives` using Merkle proofs.

---

## Security Considerations

* Uses `ReentrancyGuard` to prevent reentrancy attacks on proposal creation and approvals.
* Validates proposal fees, approver rights, and timelocks.
* Claim system prevents double claims and verifies authenticity via Merkle proofs.

---

## File Structure

```
project/
├── src/
│   ├── core/
│   │   ├── ProposeTransaction.sol
│   │   ├── Treasury.sol
│   │   ├── TimeLock.sol
│   │   ├── ClaimIncentives.sol
│   ├── interfaces/
│   │   ├── IERC20.sol
│   │   ├── ITimeLock.sol
│   ├── libraries/
│   │   ├── Errors.sol
├── test/
│   ├── ProposeTransactionTest.t.sol
├── lib/
│   └── openzeppelin-contracts/  # For OpenZeppelin dependencies
├── README.md
├── foundry.toml
├── ARCHITECTURE.md
├── PROTOCOL_SPECIFICATION.md
```

---

## Proposal Lifecycle Diagram

```
User ---> proposeTransaction ---> Transaction Created
Approvers ---> approveTransaction ---> Queue after quorum
Timelock ---> wait until expiry ---> executeTransaction
Executed ---> treasury.proposalWithdrawal
```

```
User ---> ClaimIncentives ---> Verify Merkle Proof ---> Token Transfer
```

This provides a high-level overview of the flows for proposals and claims.
