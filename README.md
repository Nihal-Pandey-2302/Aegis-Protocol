# 🛡️ Aegis Protocol

*An autonomous, on-chain risk protocol that provides dynamic, proactive insurance for NFTs and other tokenized assets. Powered by a synergy of Chainlink Functions and Chainlink Automation.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/Nihal-Pandey-2302/Aegis-Protocol)
[![Project Status](https://img.shields.io/badge/Status-Autonomous_V3_Live-blue)](https://github.com/Nihal-Pandey-2302/Aegis-Protocol)

---

## 🚀 POST-SUBMISSION UPGRADE: The Autonomous Sentinel Protocol

**The version of Aegis initially submitted was a complete, functional insurance dApp. Since then, our team has continued building at high velocity and deployed AegisV3, a significant architectural evolution.**

We have transformed Aegis from a reactive dApp into a **proactive, autonomous risk-monitoring protocol** by integrating **Chainlink Automation** with **Chainlink Functions**.

-   **New "Autonomous Demo" Video:** **[Watch Aegis automatically detect a potential theft using our new multi-service architecture.](https://your-new-video-link.com)**
-   **New Upgraded Contract (`AegisV3.sol`):** [View on Sepolia Etherscan - `0xd2Ce8CAb8285EA661ea2C6490f0f8467A39f9673`](https://sepolia.etherscan.io/address/0xd2Ce8CAb8285EA661ea2C6490f0f8467A39f9673)
-   **Chainlink Automation Upkeep:** [View Live Upkeep on Chainlink](https://automation.chain.link/sepolia/52479038237946955843236239999092429074983281081510323321284537758360662659465)

This new system showcases a powerful synergy between Chainlink's core services and represents the future of truly decentralized, on-chain security.

---

## 📌 About Aegis V3

Aegis introduces intelligent, autonomous insurance for the on-chain economy. It solves the core problem of static, manual insurance by creating a protocol that **proactively monitors assets and automatically detects loss events.**

The system uses **Chainlink Functions** as its "sentinel" to verify asset ownership off-chain and **Chainlink Automation** as its "heartbeat" to trigger these checks periodically. This eliminates the need for manual user reporting, prevents fraud, and creates a truly trustless risk management primitive.

---

<details>
<summary>🧠 How the Autonomous System Works</summary>

1.  **Policy Creation:**
    -   A user requests a dynamic premium quote via our frontend.
    -   A **Chainlink Function** fetches live floor price data from the Reservoir API to calculate a fair, real-time premium.
    -   The user pays the premium and an immutable policy is created in our `AegisV3.sol` smart contract.

2.  **Autonomous Monitoring (The Sentinel):**
    -   A **Chainlink Automation** Upkeep runs on a set schedule (e.g., every 10 minutes).
    -   The Upkeep calls the `performUpkeep` function on our contract, telling it to check the next active policy.
    -   This triggers a **second Chainlink Function** request.

3.  **Off-Chain Verification:**
    -   This new Function executes our `checkOwner.js` script.
    -   The script uses a public RPC URL to call the `ownerOf()` function on the insured NFT's contract, directly verifying its current owner on the blockchain.
    -   It returns a simple boolean (`true` or `false`) to our smart contract.

4.  **Automatic Loss Detection & Payout:**
    -   If the script returns `false` (the NFT has moved), the `fulfillRequest` function in our contract automatically updates the policy's status to `FlaggedForReview`.
    -   The policyholder can now call the `claimPolicy()` function to receive their payout instantly. The "Claim" button only appears after the protocol has autonomously detected the loss.

</details>

<details>
<summary>💰 The Capital Pool: Guaranteeing Solvency</summary>

Aegis ensures reliable payouts with a fully-collateralized, on-chain Capital Pool. For this hackathon, the **Capital Pool for the `AegisV3` contract has been pre-seeded with initial liquidity** to guarantee that all valid claims made during the demo can be paid instantly. This simulates the backing a real-world project would secure from early investors. The pool is further supplemented by the premiums collected from every new policy created.

</details>

---

---

## ⚙️ Tech Stack & Code

| Layer                    | Tech                                                                 |
| ------------------------ | -------------------------------------------------------------------- |
| Blockchain               | Ethereum (Sepolia), Avalanche (Fuji compatibility)                   |
| Smart Contracts          | Solidity, Remix IDE                                                  |
| **Autonomous Logic**     | **Chainlink Automation** (Trigger/Heartbeat)                         |
| **Off-Chain Logic**      | **Chainlink Functions** (Data Fetching & Ownership Verification)     |
| Frontend (for Demo)      | React (Vite), Ethers.js, Tailwind, Toast                             |
| APIs                     | Reservoir API (floor price), Public RPCs                             |

### Project Repositories

This project is organized into two separate repositories for a clean separation of concerns:

-**Latest V3 Contract:**[**AegisV3** on Etherscan](https://sepolia.etherscan.io/address/0xd2Ce8CAb8285EA661ea2C6490f0f8467A39f9673)

-   **Backend & Protocol HQ (This Repo):** [Aegis-Protocol](https://github.com/Nihal-Pandey-2302/Aegis-Protocol)
    -   Contains the `AegisV3.sol` smart contract and the core project documentation.

-   **Frontend User Interface:** [aegis-frontend](https://github.com/Nihal-Pandey-2302/aegis-frontend)
    -   The **`main`** branch powers the stable V2 live demo.
    -   The **[`v3-upgrade` branch](https://github.com/Nihal-Pandey-2302/aegis-frontend/tree/v3-upgrade)** contains the most up-to-date code for interacting with our new `AegisV3` autonomous protocol.

---

---

<details>
<summary>✅ How to Test the Aegis Protocol</summary>

### Testing the V3 Autonomous Sentinel (Recommended)

To see our latest and most advanced features in action, you can interact with the `AegisV3` contract by running our upgraded frontend locally.

1.  **Get Testnet Assets:** Make sure your wallet is funded with Sepolia ETH and you own at least one testnet NFT. You can use the faucets and minting tools linked below.

2.  **Clone the Frontend Repo:**
    ```bash
    git clone https://github.com/Nihal-Pandey-2302/aegis-frontend.git
    cd aegis-frontend
    ```

3.  **Switch to the V3 Branch:**
    ```bash
    git checkout v3-upgrade
    ```
4.  **Install & Run:**
    ```bash
    npm install
    npm run dev
    ```
5.  Your browser will open `localhost:5173`. Connect your wallet and you can now create policies on our new `AegisV3` contract and witness the autonomous monitoring.

### Testing the Original V2 Demo

You can view the stable, original version of our project (without the autonomous monitoring) via the live link below.

-   **Original Live Demo:** [https://aegis-frontend-tau.vercel.app/](https://aegis-frontend-tau.vercel.app/)
-   **Original V2 Contract:** [`AegisV2.sol` on Etherscan](https://sepolia.etherscan.io/address/0xa155016b9C39F500605F2e459A3335703b7053df)

### Required Testnet Resources
-   **ETH Faucet:** [Google Web3 Faucet](https://cloud.google.com/application/web3/faucet) or [Alchemy's Sepolia Faucet](https://www.alchemy.com/faucets/ethereum-sepolia)
-   **NFT Minting Tool:** [Bitbond's Token Tool for Sepolia](https://tokentool.bitbond.com/create-nft/ethereum-sepolia)

</details>

---

## 🏁 Final Thoughts

Aegis Protocol shows how multiple Chainlink services can be composed to create truly autonomous, on-chain systems. By fusing **Chainlink Automation** with the power of **Chainlink Functions**, we have built a protocol that demonstrates the future of decentralized risk management.

---

*This project was built for the Chromium Hackathon | June 2025*
