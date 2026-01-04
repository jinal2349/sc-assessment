# ✅ Tech Interview Smart Contracts – Test Result & Submission

## Overview

This repository contains the completed solution for the **Tech Interview Smart Contracts Coding Problem**.

The task required implementing logic **only inside `Token.sol`**, ensuring all provided unit tests pass without modifying the test suite.

The implemented smart contract behaves as:

- A **mintable ERC-20–like token** backed 1:1 by ETH (similar to Wrapped ETH)
- Supports **mint**, **burn**, **transfer**, and **allowance**
- Maintains an **efficient on-chain token holder list**
- Distributes **ETH dividends proportionally** to token holders
- Preserves accrued dividends even after tokens are transferred or burned

---

## 🧠 Contract Design Highlights

- `mint()` mints tokens equal to `msg.value`
- `burn()` redeems ETH equal to token balance
- Holder list updates automatically on mint, burn, and transfer
- Dividend payouts compound correctly across multiple distributions
- Withdrawals can be made at any time, even after relinquishing tokens

---

## 🧪 Test Results

All unit tests pass successfully using Hardhat.

```bash
npm run test

Contract: Token
✔ has default values
✔ can be minted
✔ can be burnt
✔ can be transferred directly
✔ can be transferred indirectly
✔ disallows empty dividend
✔ keeps track of holders when minting and burning
✔ keeps track of holders when transferring
✔ compounds the payouts
✔ allows for withdrawals in-between payouts
✔ allows for withdrawals even after holder relinquishes tokens

11 passing
0 failing

## Loom Video Link:
https://www.loom.com/share/3b0a801b258444c4b7301a3746a339e7

## Repository Access

Repository is public

Only Token.sol was modified

Test files and project structure remain unchanged
Link :
https://github.com/jinal2349/sc-assessment
