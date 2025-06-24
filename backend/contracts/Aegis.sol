// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {Strings} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/utils/Strings.sol";

contract Aegis is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;
    using Strings for uint256;
    using Strings for address;

    // --- NEW: Policy Struct ---
    // This struct holds all the data for a single insurance policy.
    struct Policy {
        uint256 policyId;
        address policyHolder;
        address nftContractAddress;
        uint256 nftTokenId;
        uint256 premiumPaid;
        uint256 coverageValue; // For now, let's say coverage is 10x the premium
        uint64 expirationTimestamp;
        bool isActive;
    }

    // --- State Variables ---
    bytes32 public s_donId;
    mapping(bytes32 => uint256) public s_pendingQuotes; // Maps requestId to the calculated premium
    mapping(uint256 => Policy) public policies; // Maps a policyId to the Policy struct
    uint256 private s_policyCounter;

    // --- Events ---
    event QuoteReceived(bytes32 indexed requestId, uint256 premium);
    event PolicyCreated(uint256 indexed policyId, address indexed policyHolder, address nftContract, uint256 tokenId);

    // --- Constructor ---
    constructor(address router, string memory donIdString)
        FunctionsClient(router)
        ConfirmedOwner(msg.sender)
    {
        s_donId = bytes32(bytes(donIdString));
    }

    // --- STEP 1: Request a Quote ---
    function createPolicyRequest(uint64 subscriptionId, address nftContractAddress, uint256 nftTokenId) external returns (bytes32 requestId) {
        string memory source = "async function calculatePremium(){let floorPrice=0;try{const reservoirReq=Functions.makeHttpRequest({url:`https://api.reservoir.tools/collections/v7?id=${args[0]}`});const res=await reservoirReq;if(res.error||!res.data.collections||res.data.collections.length===0)throw new Error(\"Reservoir data not available or API error.\");floorPrice=res.data.collections[0].floorAsk?.price?.amount?.native||0,console.log(`SUCCESS: Live Floor Price fetched: ${floorPrice} ETH`)}catch(e){console.log(\"LOG: Could not fetch live floor price. Using fallback simulation logic.\")}const basePremiumEth=.01;let marketFactor=1;floorPrice>1?marketFactor=1.5:floorPrice>.5&&(marketFactor=1.2);let ageFactor;const tokenIdNumber=Number(args[1]);tokenIdNumber<1e3?ageFactor=.8:tokenIdNumber<1e4?ageFactor=1.2:ageFactor=1.8,console.log(`Factors Used: Market=${marketFactor}, Age=${ageFactor}`);const finalPremiumEth=basePremiumEth*marketFactor*ageFactor,finalPremiumWei=BigInt(Math.round(1e18*finalPremiumEth));return console.log(`Final Premium (Wei): ${finalPremiumWei.toString()}`),Functions.encodeUint256(finalPremiumWei)}return calculatePremium();";
        string[] memory args = new string[](2);
        args[0] = nftContractAddress.toHexString();
        args[1] = nftTokenId.toString();

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);

        return _sendRequest(req.encodeCBOR(), subscriptionId, 200000, s_donId);
    }

    // --- STEP 2: Execute the Policy ---
    // The user calls this function AFTER a quote has been received.
    function executePolicy(bytes32 requestId, address nftContractAddress, uint256 nftTokenId) external payable {
        uint256 premium = s_pendingQuotes[requestId];
        require(premium > 0, "No valid quote for this request ID");
        require(msg.value == premium, "Incorrect premium amount sent");

        s_policyCounter++;
        uint256 newPolicyId = s_policyCounter;
        
        policies[newPolicyId] = Policy({
            policyId: newPolicyId,
            policyHolder: msg.sender,
            nftContractAddress: nftContractAddress,
            nftTokenId: nftTokenId,
            premiumPaid: msg.value,
            coverageValue: msg.value * 10, // Example coverage calculation
            expirationTimestamp: uint64(block.timestamp + 30 days), // 30-day policy
            isActive: true
        });

        emit PolicyCreated(newPolicyId, msg.sender, nftContractAddress, nftTokenId);
    }


    // --- Chainlink Functions Callback ---
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (err.length == 0) {
            uint256 calculatedPremium = abi.decode(response, (uint256));
            s_pendingQuotes[requestId] = calculatedPremium;
            emit QuoteReceived(requestId, calculatedPremium);
        } else {
            // Handle error if needed
        }
    }

    function getPoliciesByOwner(address owner) public view returns (Policy[] memory) {
        uint256 ownerPolicyCount = 0;
        for (uint256 i = 1; i <= s_policyCounter; i++) {
            if (policies[i].policyHolder == owner) {
                ownerPolicyCount++;
            }
        }

        Policy[] memory ownerPolicies = new Policy[](ownerPolicyCount);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= s_policyCounter; i++) {
            if (policies[i].policyHolder == owner) {
                ownerPolicies[currentIndex] = policies[i];
                currentIndex++;
            }
        }
        
        return ownerPolicies;
    }
}


