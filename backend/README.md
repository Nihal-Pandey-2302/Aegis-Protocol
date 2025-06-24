# 🛡️ Aegis Protocol - Backend

This repository contains the smart contract and off-chain logic for the Aegis Protocol — a decentralized NFT insurance protocol using dynamic pricing powered by Chainlink Functions.

## Overview

The backend consists of two primary components:

1. **`AegisV2.sol`**: The Solidity smart contract responsible for managing policy requests, executing insurance creation, and integrating with Chainlink Functions.
2. **`source.js`**: The JavaScript file executed off-chain by the Chainlink DON, responsible for live market data fetching and premium calculation logic.

## 🔐 Smart Contract — `AegisV2.sol`

This is the deployed contract used in the final version of the application.

### Key Functions

- **`createPolicyRequest(...)`**: Initiates an insurance quote by sending NFT details to Chainlink Functions.
- **`fulfillRequest(...)`**: The callback from the DON that stores the premium once it's computed.
- **`executePolicy(...)`**: A payable function that finalizes the policy by accepting the premium and saving a `Policy` struct on-chain.
- **`reportLoss(...)`** / **`claimPolicy(...)`**: Allow users to report a loss or claim their policy payout.
- **`getPoliciesByOwner(...)`**: Lets the frontend fetch all active policies for a wallet.

**✅ Deployed Contract (Sepolia):**  
[`0xa155016b9C39F500605F2e459A3335703b7053df`](https://sepolia.etherscan.io/address/0xa155016b9C39F500605F2e459A3335703b7053df)

## 🧠 Chainlink Functions Script — `source.js`

This script contains the protocol’s off-chain dynamic pricing logic.

### Responsibilities

- **Data Fetching**: Calls the Reservoir API to get current floor price for the NFT’s collection.
- **Risk Profile Calculation**: Combines floor price with a simulated age-based risk factor.
- **Fallback Handling**: If the API fails, a default premium is generated to avoid breaking the user flow.

This script is referenced directly inside the smart contract's `createPolicyRequest` function call.

## Setup Instructions

> ⚙️ Remix was used for deployment and testing. No Hardhat is required unless extending this contract.

### If testing Chainlink Functions locally:

1. **Clone the Repository**

   ```bash
   git clone https://github.com/Nihal-Pandey-2302/aegis-backend.git
   cd aegis-backend
   ```

2. **Install Dependencies**

   ```bash
   npm install
   ```

3. **Simulate source.js (optional)**  
   You can simulate `source.js` using the [Chainlink Functions Playground](https://functions.chain.link/playground) with test data for easier debugging.

## Project Repositories

- **Frontend**: [`aegis-frontend`](https://github.com/Nihal-Pandey-2302/aegis-frontend)
- **Backend**: [`aegis-backend`](https://github.com/Nihal-Pandey-2302/aegis-backend)

---

**Built with ❤️ for the [Chromium Hackathon] | June 2025**
