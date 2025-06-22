# 🛡️ Aegis Protocol - Backend

This repository contains the smart contract and off-chain logic for the Aegis Protocol.

## Overview

The backend consists of two main components:

1. **`Aegis.sol`:** A Solidity smart contract responsible for handling user requests, triggering Chainlink Functions, and creating on-chain insurance policies.
2. **`source.js`:** A JavaScript script that is executed off-chain by the Chainlink DON. It contains the core "AI" logic for fetching live market data and calculating dynamic insurance premiums.

## Core Components

### `Aegis.sol`

This is the main smart contract for the protocol.

* **`createPolicyRequest(...)`**: This function is called by the user to initiate an insurance quote. It packages the NFT details and sends a request to the Chainlink Functions network.
* **`executePolicy(...)`**: After a quote is received, the user calls this `payable` function, sending the premium amount in ETH. This function creates and stores a new `Policy` struct on-chain.
* **`fulfillRequest(...)`**: The internal callback function that the Chainlink oracle calls to deliver the calculated premium or any errors.
* **`getPoliciesByOwner(...)`**: A view function that allows the frontend to query all active policies for a given user.

**Deployed Address (Sepolia):** `YOUR_FINAL_CONTRACT_ADDRESS`

### `source.js`

This script contains the dynamic pricing algorithm.

* **Data Fetching:** It makes a live `GET` request to the Reservoir API (`api.reservoir.tools`) to fetch the target NFT collection's current floor price.
* **Risk Factors:** It combines the fetched floor price (as a "market factor") with other simulated data (like an "age factor" based on token ID) to create a risk profile.
* **Fallback Logic:** The script is built to be resilient. If the live API call fails or times out, it gracefully falls back to a simulation model, ensuring the protocol always returns a valid quote.

## Setup

This project uses the Hardhat environment for managing the Chainlink Functions Toolkit.

1. **Clone and Install:**

    ```bash
    git clone [https://github.com/YOUR_USERNAME/aegis-backend.git](https://github.com/YOUR_USERNAME/aegis-backend.git)
    cd aegis-backend
    npm install
    ```

2. **Environment:**
    Create a `.env` file with your `SEPOLIA_RPC_URL` and `PRIVATE_KEY`.
3. **Test the Off-Chain Script:**
    You can simulate the `source.js` script locally using the Chainlink Functions Playground or by running Hardhat tasks (if the local environment is fully configured).

## Project Repositories

* **Frontend:** `https://github.com/Nihal-Pandey-2302/aegis-frontend`
* **Backend (Smart Contracts & Logic):** `https://github.com/Nihal-Pandey-2302/aegis-backend`

## Deployed Contract

* **Aegis.sol on Sepolia Etherscan:**
    `https://sepolia.etherscan.io/address/0xed8a57ff5ED79e9F1803f486C6ad61c16f8ab6D3`

---
*This project was built for the [Chromium Hackathon] | June 2025*
