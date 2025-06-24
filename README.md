# 🛡️ Aegis Protocol

*A decentralized NFT insurance protocol with dynamic, real-time premiums powered by Chainlink Functions.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/Nihal-Pandey-2302/aegis-frontend)
[![Project Status](https://img.shields.io/badge/Status-Feature_Complete-blue)](https://github.com/Nihal-Pandey-2302/aegis-frontend)

- **Live Demo:** [https://aegis-frontend-tau.vercel.app/](https://aegis-frontend-tau.vercel.app/)
- **Faucet** [Google Web3 Faucet](https://cloud.google.com/application/web3/faucet)
- **NFT Minting Demo** [https://vimeo.com/1095478830?share=copy](https://vimeo.com/1095478830?share=copy)

---

## 📌 About

Aegis introduces intelligent insurance for NFTs, using real-time market data to offer dynamic, fair premiums. Built with Chainlink Functions and deployed on Ethereum Sepolia, it removes manual risk assumptions by relying on live NFT floor prices and on-chain policy enforcement.

---

## 🚩 The Problem

NFTs are volatile, yet most insurance models rely on static pricing, leading to overpriced coverage or under-hedged risks. Aegis solves this by offering:

- 📈 Market-aware premium calculation  
- 🤖 Automated off-chain risk logic via Chainlink Functions  
- ✅ Trustless execution and payout on-chain

---

## 🧠 How Aegis Works

1. **Quote Request:**  
   User selects an NFT → Triggers `createPolicyRequest()` in the smart contract.

2. **Chainlink Function Triggered:**  
   Contract calls a JS script via Chainlink Functions → Script fetches floor price using Reservoir API.

3. **Dynamic Premium Calculation:**  
   Floor price + NFT age → Risk-adjusted premium calculated in ETH → Returned to contract.

4. **User Executes Policy:**  
   User approves quote → Pays premium → Policy struct is created and stored on-chain.

5. **Loss Reporting & Claim:**  
   Policyholder can report a loss and claim funds automatically if eligible.

---

## ✨ Features

- 🔄 **Real-Time Premiums:** Live API data powers pricing  
- 🔐 **Trustless On-Chain Policies:** Transparent, immutable insurance logic  
- 🧩 **NFT-Aware Risk Model:** Considers floor price and token age  
- 💡 **Smart UX:** React dashboard with clear visuals and feedback  
- 🔁 **Remix-Compatible Deployment:** Easy for Web3 beginners—no Hardhat needed

## 📱 Responsive Design

The Aegis Protocol frontend is fully responsive and optimized for both desktop and mobile devices. The layout adjusts dynamically for smaller screens to ensure smooth user experience on phones and tablets.

Key enhancements include:

- Collapsible sidebar on mobile view
- Stacked layout for content and headers
- Responsive grid for NFTs and policy cards


---

## ⚙️ Tech Stack

| Layer             | Tech                                      |
|------------------|-------------------------------------------|
| Blockchain        | Ethereum (Sepolia Testnet) ,Avalanche Fuji Testnet|
| Smart Contracts   | Solidity, Remix IDE                       |
| Off-Chain Logic   | Chainlink Functions                       |
| Frontend          | React (Vite), Ethers.js, Tailwind, Toast |
| APIs              | Reservoir (floor price), Alchemy (NFT metadata) |

---

## 💰 The Capital Pool: How Claims Are Paid

Aegis ensures reliable payouts by using a transparent, on-chain Capital Pool. This pool is the reserve used to pay out all successful insurance claims.

For our current implementation, the Capital Pool is funded directly by the **premiums** paid by users when they purchase a policy.
- Every time a user creates an insurance policy, the ETH premium is collected and stored within the `AegisV2.sol` smart contract itself.
- This creates a collective, on-chain reserve. When a policyholder files a valid claim, the coverage amount is paid directly from this pool of accumulated premiums.

This model demonstrates the core mechanic, but the long-term vision is to create a more robust, decentralized underwriting system by:

- **Allowing Liquidity Providers (LPs)** to stake capital (e.g., ETH or USDC) into the pool to underwrite policies, earning a share of the premium revenue in return.
- **Generating Yield** by integrating the capital pool with blue-chip DeFi protocols like Aave. The yield earned would further increase the pool's reserves and reward LPs, creating a self-sustaining economic loop.

This approach ensures Aegis is not only functional but also designed for long-term, sustainable growth within the DeFi ecosystem.
---

## Getting Started

To run this project locally:

1. **Clone the repository:**

    ```bash
    git clone [https://github.com/YOUR_USERNAME/aegis-frontend.git](https://github.com/YOUR_USERNAME/aegis-frontend.git)
    cd aegis-frontend
    ```

2. **Install dependencies:**

    ```bash
    npm install
    ```

3. **Set up environment variables:**
    Create a `.env` file in the root and add your Alchemy API Key:
    `VITE_ALCHEMY_API_KEY=YOUR_ALCHEMY_KEY`
4. **Run the development server:**

    ```bash
    npm run dev
    ```

## How to Use the Aegis Demo

To test the Aegis Protocol, you will need a wallet funded with Sepolia ETH and at least one NFT on the Sepolia testnet.

### 1. Get Sepolia ETH

The Sepolia network requires ETH for gas fees. You can get free testnet ETH from a public faucet.

* **Recommended Faucet:**
- [Google Web3 Faucet](https://cloud.google.com/application/web3/faucet)
- [Alchemy's Sepolia Faucet](https://www.alchemy.com/faucets/ethereum-sepolia)

### 2. Get a Testnet NFT

Once you have Sepolia ETH, you can mint a free, custom testnet NFT using the Bitbond Token Tool. This tool has a multi-step process.

- **NFT Minting Tool:** [Bitbond's Token Tool for Sepolia](https://tokentool.bitbond.com/create-nft/ethereum-sepolia)
- **NFT Minting Demo** [https://vimeo.com/1095478830?share=copy](https://vimeo.com/1095478830?share=copy)

- **Instructions:**
    1. **Create NFT Definition:** First, use the "Create NFT" page to define your NFT (e.g., give it a name like "My Test Asset"). This transaction creates the contract for your NFT collection.
    2. **Manage Metadata:** After creation, go to the "Manage" section of their tool. Here you can add a picture and other metadata to your NFT definition.
    3. **Mint the NFT:** Finally, go to the "Mint" section in the NFT minting page by clicking this link on the manage page. Select the NFT you just defined and mint it to your wallet address.
    4. **Check MetaMask:** After you approve the final minting transaction, the NFT should appear automatically in your MetaMask wallet under the "NFTs" tab. It will then be visible in the Aegis application.

## Project Repositories

- **Frontend:** [https://github.com/Nihal-Pandey-2302/aegis-frontend](https://github.com/Nihal-Pandey-2302/aegis-frontend)
- **Backend (Smart Contracts & Logic):** [https://github.com/Nihal-Pandey-2302/aegis-backend](https://github.com/Nihal-Pandey-2302/aegis-backend)

## 🔗 Smart Contract

- **Sepolia Contract:**  
  [`AegisV2.sol`](https://sepolia.etherscan.io/address/0xa155016b9C39F500605F2e459A3335703b7053df)
- **Avalanche Fuji Testnet**
   -Smart contract is compiled and deployable on Fuji C-Chain , Final deployment will be completed once faucet access is restored  

---

## 📌 Key Notes for Deployment

- ✅ Add the deployed contract address in your frontend `config.js`
- 🔁 Ensure Chainlink subscription has Aegis contract as an authorized consumer
- ⛽ Use MetaMask to fund the contract with ETH for payouts
- 🧪 Use Remix for seamless deployments—no Hardhat setup needed

---

## 🏁 Final Thoughts

Aegis Protocol shows how off-chain computation and real-world data can be fused with immutable smart contracts to enable real financial products on-chain. It demonstrates:

- Decentralized risk computation  
- Real-world API integration  
- Simple, user-friendly frontend for complex backend logic

---

*This project was built for the [Chromium Hackathon] | June 2025*
