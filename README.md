# 🛡️ Aegis Protocol

*An autonomous, on-chain risk protocol that provides dynamic, proactive insurance for NFTs and other tokenized assets. Powered by a synergy of Chainlink Functions and Chainlink Automation.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/V3_Backend-Live_on_Sepolia-brightgreen)](https://sepolia.etherscan.io/address/0x4e50f4aa92132bec49b59ac31bd360840b8a608c)
[![Project Status](https://img.shields.io/badge/Status-Autonomous_V3_Live-blue)](https://automation.chain.link/sepolia/52479053358607414262573789753157733136198557779381457305521613214336204719465)

---

## 🚀 The Aegis V3 Autonomous Sentinel Protocol

This repository contains the smart contract and core logic for **AegisV3**, a significant architectural evolution of our original concept. We have transformed Aegis from a reactive dApp into a **proactive, autonomous risk-monitoring protocol** by integrating **Chainlink Automation** with **Chainlink Functions**.

The entire V3 backend system is **live and operational on the Sepolia testnet.**

### **Irrefutable On-Chain Proof:**

-   **V3 Smart Contract (`AegisV3.sol`):** [**`0x4e50...608c`** on Etherscan](https://sepolia.etherscan.io/address/0x4e50f4aa92132bec49b59ac31bd360840b8a608c)
-   **Chainlink Automation Upkeep:** [**View our "Aegis Sentinel" Live on Chainlink**](https://automation.chain.link/sepolia/52479053358607414262573789753157733136198557779381457305521613214336204719465)
    *(You can view the successful `Perform Upkeep` history here.)*
-   **Chainlink Functions Subscription:** [**View our Live Subscription (ID: 5065)**](https://functions.chain.link/sepolia/5065)
    *(You can see the successful requests processed by our V3 contract here.)*

---

## 📌 About Aegis V3

Aegis introduces intelligent, autonomous insurance for the on-chain economy. It solves the core problem of static, manual insurance by creating a protocol that **proactively monitors assets and automatically detects loss events.** The system uses **Chainlink Automation** as its "heartbeat" and **Chainlink Functions** as its "sentinel" to create a truly trustless risk management primitive.

<details>
<summary>🧠 How the Autonomous System Works</summary>

1.  **Policy Creation:** A user creates an on-chain insurance policy. In our V2 demo, this is done via a dynamic quote from Chainlink Functions. For our V3 demo, we use a staging function to create policies directly.

2.  **Autonomous Monitoring (The Sentinel):** Our live **Chainlink Automation** Upkeep runs on a set schedule, calling the `performUpkeep` function on our `AegisV3` contract.

3.  **Off-Chain Verification:** This triggers a **Chainlink Function** which executes our `checkOwner.js` script. The script uses a public RPC to call the `ownerOf()` function on the insured NFT's contract, directly verifying its current owner.

4.  **Automatic Loss Detection:** If the script returns `false` (the NFT has moved), the `fulfillRequest` function in our contract automatically updates the policy's on-chain status to `FlaggedForReview`.

*This entire process is live and can be verified using the on-chain links provided above.*

</details>

<details>
<summary>⚙️ Tech Stack & Project Repositories</summary>

| Layer                    | Tech                                                         |
| ------------------------ | ------------------------------------------------------------ |
| Blockchain               | Ethereum (Sepolia), Avalanche (Fuji compatibility)           |
| Smart Contracts          | Solidity, Remix IDE                                          |
| **Autonomous Logic**     | **Chainlink Automation** (Trigger/Heartbeat)                 |
| **Off-Chain Logic**      | **Chainlink Functions** (Ownership Verification)             |
| Frontend (for V2 Demo)   | React (Vite), Ethers.js, Tailwind, Toast                     |

-   **Backend & Protocol HQ (This Repo):** Contains the `AegisV3.sol` smart contract and this documentation.
-   **Frontend User Interface:** [aegis-frontend](https://github.com/Nihal-Pandey-2302/aegis-frontend)
    *(The `main` branch powers our stable V2 live demo.)*

</details>

---

## 🏁 Final Thoughts

Aegis Protocol shows how multiple Chainlink services can be composed to create truly autonomous, on-chain systems. By fusing **Chainlink Automation** with the power of **Chainlink Functions**, we have built a protocol that demonstrates the future of decentralized risk management.

---

*This project was built for the Chromium Hackathon | June 2025*
