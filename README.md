# 🛡️ Aegis Protocol V3: The Autonomous Sentinel

**Aegis is a fully autonomous, on-chain insurance protocol that proactively monitors digital assets. It uses a powerful synergy of Chainlink Automation and Chainlink Functions to automatically detect loss events and prepare policies for claims without requiring any user intervention.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/V3_Protocol-Live_on_Sepolia-brightgreen)](https://sepolia.etherscan.io/address/0x4e50f4aa92132bec49b59ac31bd360840b8a608c)
[![Automation](https://img.shields.io/badge/Sentinel_Upkeep-Live-blue)](https://automation.chain.link/sepolia/52479053358607414262573789753157733136198557779381457305521613214336204719465)
[![V3 Demo Video](https://img.shields.io/badge/Watch_The_V3_Demo-green)](https://www.youtube.com/watch?v=mQY3gdAVlv4)

---

### **Irrefutable On-Chain Proof of the Live V3 Protocol**

The entire Aegis V3 autonomous system is **live and operational on the Sepolia testnet.** We invite you to verify our work directly on the blockchain.

*   **V3 Smart Contract (`AegisV3.sol`):** [**`0x4e50f4aa92132bec49b59ac31bd360840b8a608c`** on Sepolia Etherscan](https://sepolia.etherscan.io/address/0x4e50f4aa92132bec49b59ac31bd360840b8a608c)
*   **Chainlink Automation (The Heartbeat):** [**View the "Aegis Sentinel" Upkeep Live**](https://automation.chain.link/sepolia/52479053358607414262573789753157733136198557779381457305521613214336204719465)
    *(You can view the successful `Perform Upkeep` history here.)*
*   **Chainlink Functions (The Sentinel):** [**View our Live Subscription (ID: 5065)**](https://functions.chain.link/sepolia/5065)
    *(You can see the successful requests processed by our V3 contract.)*

---

### **The Aegis Vision: Autonomous On-Chain Risk Management**

Aegis solves the core problem of static, manual insurance by creating a protocol that **proactively monitors assets and automatically detects loss events.** The system uses **Chainlink Automation** as its "heartbeat" and **Chainlink Functions** as its "sentinel" to create a truly trustless risk management primitive.

![Architecture Diagram](https://github.com/Nihal-Pandey-2302/Aegis-Protocol/blob/main/Final%20Fowchart.png)
<!-- **Action:** Upload your new architecture diagram to a service like Imgur and paste the direct link here -->

<details>
<summary><strong>Our Journey: From dApp to Autonomous Protocol (The Story Behind the Code)</strong></summary>

Building a truly autonomous protocol required us to solve some of the deepest challenges in Web3.

1.  **The Core Conceptual Challenge: Automating Loss Detection**
    *   **Our Solution:** We architected the Autonomous Sentinel. We integrated Chainlink Automation to act as a heartbeat, periodically triggering a Chainlink Function. This Function acts as a sentinel, using an off-chain RPC to verify asset ownership directly on the blockchain.

2.  **The Final Boss: Diagnosing a "Black Box" Revert**
    *   In our final integration tests, our functions began failing with an `UNPREDICTABLE_GAS_LIMIT` error, even though our on-chain setup was perfect. After eliminating every possible on-chain cause, we diagnosed the issue as a gas-cost problem within the Chainlink DON's simulation environment.
    *   **Our Winning Pivot:** We re-architected the on-chain logic to be ultra-gas-efficient. This deep dive into gas optimization was the final step that brought the full autonomous system to life.

*Overcoming these challenges transformed us from dApp developers into true protocol architects, capable of building and diagnosing complex, multi-service systems.*

</details>

<details>
<summary><strong>⚙️ Tech Stack & Project Repositories</strong></summary>

| Layer                | Technology                                                                |
| -------------------- | ------------------------------------------------------------------------- |
| **Smart Contracts**   | Solidity, Remix IDE                                                       |
| **Autonomous Core**  | **Chainlink Automation** (Trigger) & **Chainlink Functions** (Execution)  |
| **Blockchain**       | Ethereum (Sepolia), Avalanche (Fuji compatibility)                        |
| **Frontend**         | React (Vite), Ethers.js, Alchemy SDK, Vercel                              |

*   **Protocol Logic & Documentation (This Repo):** Contains the `AegisV3.sol` smart contract.
*   **Frontend User Interface:** [https://github.com/Nihal-Pandey-2302/aegis-frontend](https://github.com/Nihal-Pandey-2302/aegis-frontend)
*   **Live Demo (Stable V2):** [https://aegis-frontend-tau.vercel.app/](https://aegis-frontend-tau.vercel.app/)

</details>

---

## 🏁 The Future is Autonomous

Aegis Protocol shows how multiple Chainlink services can be composed to create truly autonomous, on-chain systems. The framework we've built is asset-agnostic and ready to provide a layer of automated security for the future of tokenized real estate, RWAs, and the entire on-chain economy.

*This project was built for the Chainlink Fall 2023 Hackathon.*
