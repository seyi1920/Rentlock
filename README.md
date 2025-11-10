RentLock Smart Contract

**RentLock** is a decentralized escrow-based rental payment system built on the **Stacks blockchain** using **Clarity**.  
It enables secure, transparent, and automated rent payments between landlords and tenants — removing the need for intermediaries.

---

Overview

The **RentLock Smart Contract** provides a trustless system for managing rental agreements, holding rent deposits securely until the agreed terms are met.  
It ensures transparency, fair handling of funds, and automated release of payments through on-chain logic.

---

Key Features

- **Escrow-Based Rent Payments** — Tenants lock rent in escrow until the due date.  
- **Automated Release** — Landlords receive payment once the rental term completes successfully.  
- **Refund System** — Tenants receive refunds for deposits if all conditions are met.  
- **Dispute Resolution** — Mutual cancellation option for both parties.  
- **On-Chain Transparency** — All agreements, transactions, and states are recorded immutably.  

---

Core Functions

| Function | Description |
|-----------|--------------|
| `create-rental-agreement` | Initializes a new rental contract with landlord, tenant, amount, and duration. |
| `pay-rent` | Allows tenant to deposit STX rent payment into the escrow. |
| `release-payment` | Transfers rent to landlord upon successful completion of agreement. |
| `cancel-agreement` | Cancels an agreement and refunds deposit based on mutual consent. |
| `get-agreement` | Retrieves details of a specific active rental contract. |

---

Technical Details

- **Language:** [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-overview)  
- **Blockchain:** [Stacks](https://stacks.co) (Bitcoin Layer for smart contracts)  
- **Framework:** [Clarinet](https://github.com/hirosystems/clarinet) for testing and local deployment  
- **Contract Type:** Rental Escrow Smart Contract  

---

Testing

Run the following commands using Clarinet:

```bash
clarinet check
clarinet test
