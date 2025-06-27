

# 🛡️ Aegis Protocol

*A decentralized NFT insurance protocol with dynamic, real-time premiums powered by Chainlink Functions.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/Nihal-Pandey-2302/aegis-frontend)
[![Project Status](https://img.shields.io/badge/Status-Feature_Complete-blue)](https://github.com/Nihal-Pandey-2302/aegis-frontend)

-   **Live Demo:** [https://aegis-frontend-tau.vercel.app/](https://aegis-frontend-tau.vercel.app/)
-   **Faucet:** [Google Web3 Faucet](https://cloud.google.com/application/web3/faucet)
-   **NFT Minting Demo:** [https://vimeo.com/1095478830?share=copy](https://vimeo.com/1095478830?share=copy)

---

## 📌 About

Aegis introduces intelligent insurance for NFTs, using real-time market data to offer dynamic, fair premiums. Built with Chainlink Functions and deployed on Ethereum Sepolia, it removes manual risk assumptions by relying on live NFT floor prices and on-chain policy enforcement.

---

## 🚩 The Problem

NFTs are volatile, yet most insurance models rely on static pricing, leading to overpriced coverage or under-hedged risks. Aegis solves this by offering:

-   📈 Market-aware premium calculation
-   🤖 Automated off-chain risk logic via Chainlink Functions
-   ✅ Trustless execution and payout on-chain

---

<details>
<summary>🧠 How Aegis Works</summary>

1.  **Quote Request:**
    A user selects an NFT from their wallet, which triggers the `createPolicyRequest()` function in the smart contract.

2.  **Chainlink Function Triggered:**
    The contract calls a custom JavaScript script via a Chainlink Functions subscription. This script fetches the NFT's real-time floor price from the Reservoir API.

3.  **Dynamic Premium Calculation:**
    The floor price and the NFT's age are used to calculate a risk-adjusted premium in ETH, which is returned to the smart contract.

4.  **User Executes Policy:**
    The user approves the quote and pays the premium. A `Policy` struct is created and stored immutably on-chain.

5.  **Claim & Payout:**
    If the insured NFT is lost (e.g., transferred from the wallet without the owner's consent), the policyholder can initiate a claim. The contract verifies the loss on-chain and automatically pays the coverage amount from the capital pool.

</details>

<details>
<summary>✅ Verifiable Claims & Payouts</summary>

For an insurance protocol to be viable, its claim process must be trustless, transparent, and secure.

-   **Defining a "Loss" for the Demo:** For the Chromium Hackathon, Aegis focuses on the most critical on-chain risk: **wallet compromise leading to theft**. A loss event is defined as the insured NFT being transferred from the policyholder's wallet without a corresponding sale initiated through a recognized marketplace.

-   **Automated Claim Process:** When a policyholder files a claim, the `AegisV2.sol` smart contract performs an on-chain check to confirm that the user's wallet no longer holds the NFT. If the conditions are met, the policy's coverage amount is paid out instantly and automatically.

-   **Future Fraud Prevention:** We recognize that sophisticated fraud (e.g., a user "selling" an NFT to their own secondary wallet to claim insurance) is a challenge. Our long-term roadmap includes integrating with a decentralized arbitration service (like Kleros) to adjudicate disputed claims, ensuring the protocol remains fair and robust.

</details>

<details>
<summary>💰 The Capital Pool: Guaranteeing Solvency</summary>

A decentralized insurance protocol is only as good as its ability to pay claims. Aegis ensures reliable payouts with a fully-collateralized, on-chain Capital Pool.

-   **Pre-Funded for the Hackathon:** To guarantee solvency and demonstrate a working product for the Chromium Hackathon, the **Capital Pool has been pre-seeded with initial liquidity.** You can verify the contract's balance on Etherscan. This initial funding ensures that all valid claims made during the demo can be paid instantly, simulating the backing a real-world project would secure from early investors or liquidity providers.

-   **Sustained by Premiums:** The pool is further supplemented by the premiums collected from every new policy created. When a user files a valid claim, the coverage amount is paid directly from this collective, on-chain reserve.

-   **Long-Term Vision for Growth:** Our architecture is designed for sustainable, decentralized growth. Future versions will allow:
    -   **Liquidity Providers (LPs):** Users will be able to stake capital (e.g., ETH or USDC) into the pool to underwrite policies, earning a share of premium revenue in return.
    -   **Yield Generation:** The capital pool will be integrated with blue-chip DeFi protocols like Aave or Compound. The yield earned will increase the pool's reserves and reward LPs, creating a self-sustaining economic model.

</details>

---

## ✨ Features

-   🔄 **Real-Time Premiums:** Live API data powers pricing
-   🔐 **Trustless On-Chain Policies:** Transparent, immutable insurance logic
-   🧩 **NFT-Aware Risk Model:** Considers floor price and token age
-   💡 **Smart UX:** React dashboard with clear visuals and feedback
-   🔁 **Remix-Compatible Deployment:** Easy for Web3 beginners—no Hardhat needed

## 📱 Responsive Design

The Aegis Protocol frontend is fully responsive and optimized for both desktop and mobile devices. The layout adjusts dynamically for smaller screens to ensure smooth user experience on phones and tablets.

Key enhancements include:

-   Collapsible sidebar on mobile view
-   Stacked layout for content and headers
-   Responsive grid for NFTs and policy cards

---

## ⚙️ Tech Stack

| Layer          | Tech                                               |
| -------------- | -------------------------------------------------- |
| Blockchain     | Ethereum (Sepolia Testnet), Avalanche Fuji Testnet |
| Smart Contracts | Solidity, Remix IDE                                |
| Off-Chain Logic| Chainlink Functions                                |
| Frontend       | React (Vite), Ethers.js, Tailwind, Toast           |
| APIs           | Reservoir (floor price), Alchemy (NFT metadata)    |

---

## Getting Started

To run this project locally:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Nihal-Pandey-2302/aegis-frontend.git
    cd aegis-frontend
    ```
2.  **Install dependencies:**
    ```bash
    npm install
    ```
3.  **Set up environment variables:**
    Create a `.env` file in the root and add your Alchemy API Key:
    `VITE_ALCHEMY_API_KEY=YOUR_ALCHEMY_KEY`
4.  **Run the development server:**
    ```bash
    npm run dev
    ```

---

## How to Use the Aegis Demo

To test the Aegis Protocol, you will need a wallet funded with Sepolia ETH and at least one NFT on the Sepolia testnet.

### 1. Get Sepolia ETH

The Sepolia network requires ETH for gas fees. You can get free testnet ETH from a public faucet.

-   **Recommended Faucet:**
    -   [Google Web3 Faucet](https://cloud.google.com/application/web3/faucet)
    -   [Alchemy's Sepolia Faucet](https://www.alchemy.com/faucets/ethereum-sepolia)

### 2. Get a Testnet NFT

Once you have Sepolia ETH, you can mint a free, custom testnet NFT using the Bitbond Token Tool.

-   **NFT Minting Tool:** [Bitbond's Token Tool for Sepolia](https://tokentool.bitbond.com/create-nft/ethereum-sepolia)
-   **NFT Minting Demo:** [https://vimeo.com/1095478830?share=copy](https://vimeo.com/1095478830?share=copy)

-   **Instructions:**
    1.  **Create NFT Definition:** First, use the "Create NFT" page to define your NFT (e.g., give it a name like "My Test Asset").
    2.  **Manage Metadata:** After creation, go to the "Manage" section to add a picture and other metadata.
    3.  **Mint the NFT:** Finally, go to the "Mint" section on the manage page. Select the NFT you defined and mint it to your wallet.
    4.  **Check MetaMask:** The NFT should appear in your MetaMask wallet under the "NFTs" tab and will then be visible in the Aegis application.

---

## Project Repositories

-   **Frontend:** [https://github.com/Nihal-Pandey-2302/aegis-frontend](https://github.com/Nihal-Pandey-2302/aegis-frontend)
-   **Backend (Smart Contracts & Logic):** [https://github.com/Nihal-Pandey-2302/aegis-backend](https://github.com/Nihal-Pandey-2302/aegis-backend)

## 🔗 Smart Contract

-   **Sepolia Contract:**
    [`AegisV2.sol` on Etherscan](https://sepolia.etherscan.io/address/0xa155016b9C39F500605F2e459A3335703b7053df)
-   **Avalanche Fuji Testnet:**
    Smart contract is compiled and deployable on Fuji C-Chain. Final deployment will be completed once faucet access is restored.

---

## 📌 Key Notes for Deployment

-   ✅ Add the deployed contract address in your frontend `config.js`
-   🔁 Ensure Chainlink subscription has Aegis contract as an authorized consumer
-   ⛽ **Use MetaMask to pre-fund the contract with ETH to ensure claim solvency**
-   🧪 Use Remix for seamless deployments—no Hardhat setup needed

---

## 🏁 Final Thoughts

Aegis Protocol shows how off-chain computation and real-world data can be fused with immutable smart contracts to enable real financial products on-chain. It demonstrates:

-   Decentralized risk computation
-   Real-world API integration
-   Simple, user-friendly frontend for complex backend logic

---

*This project was built for the Chromium Hackathon | June 2025*
