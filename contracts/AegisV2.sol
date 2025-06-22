// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Aegis is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;
    using Strings for uint256;
    using Strings for address;

    struct Policy {
        uint256 policyId;
        address policyHolder;
        address nftContractAddress;
        uint256 nftTokenId;
        uint256 premiumPaid;
        uint256 coverageValue;
        uint64 expirationTimestamp;
        bool isActive;
        bool lossReported;
        bool claimed;
    }

    bytes32 public s_donId;
    mapping(bytes32 => uint256) public s_pendingQuotes;
    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public ownerToPolicyIds;
    uint256 private s_policyCounter;

    event QuoteReceived(bytes32 indexed requestId, uint256 premium);
    event PolicyCreated(uint256 indexed policyId, address indexed policyHolder, address nftContract, uint256 tokenId);
    event LossReported(uint256 indexed policyId, address indexed reporter);
    event PolicyClaimed(uint256 indexed policyId, address indexed claimant, uint256 payout);

    constructor(address router, string memory donIdString)
        FunctionsClient(router)
        ConfirmedOwner(msg.sender)
    {
        s_donId = bytes32(bytes(donIdString));


    }

    function createPolicyRequest(
    uint64 subscriptionId,
    address nftContractAddress,
    uint256 nftTokenId
) external returns (bytes32) {
    string memory source = "async function calculatePremium(){const nftContractAddress=args[0];const nftTokenId=args[1];let floorPrice=0;try{const reservoirReq=Functions.makeHttpRequest({url:`https://api.reservoir.tools/collections/v7?id=${nftContractAddress}`});const res=await reservoirReq;if(res.error||!res.data.collections||res.data.collections.length===0)throw new Error(\"Reservoir data not available or API error.\");floorPrice=res.data.collections[0].floorAsk?.price?.amount?.native||0;console.log(`SUCCESS: Live Floor Price fetched: ${floorPrice} ETH`)}catch(e){console.log(\"LOG: Could not fetch live floor price. Using fallback simulation logic.\")}const tokenIdNumber=Number(nftTokenId);if(isNaN(tokenIdNumber))throw new Error(\"Invalid tokenId passed.\");const basePremiumEth=0.01;let marketFactor=1.0;if(floorPrice>1){marketFactor=1.5}else if(floorPrice>0.5){marketFactor=1.2}let ageFactor=1.0;if(tokenIdNumber<1000){ageFactor=0.8}else if(tokenIdNumber<10000){ageFactor=1.2}else{ageFactor=1.8}console.log(`Factors Used: Market=${marketFactor}, Age=${ageFactor}`);const finalPremiumEth=basePremiumEth*marketFactor*ageFactor;let finalPremiumWei=BigInt(Math.round(finalPremiumEth*1e18));const maxPremiumWei=BigInt(5e17);if(finalPremiumWei>maxPremiumWei){finalPremiumWei=maxPremiumWei}if(finalPremiumWei===BigInt(0)){finalPremiumWei=BigInt(1e16)}console.log(`Final Premium (Wei): ${finalPremiumWei.toString()}`);return Functions.encodeUint256(finalPremiumWei)}return calculatePremium();";
        string[] memory args = new string[](2);
        args[0] = nftContractAddress.toHexString();
        args[1] = nftTokenId.toString();
    FunctionsRequest.Request memory req;
    req.initializeRequestForInlineJavaScript(source);
    req.setArgs(args);

    return _sendRequest(req.encodeCBOR(), subscriptionId, 200000, s_donId);
    }


    function executePolicy(
        bytes32 requestId,
        address nftContractAddress,
        uint256 nftTokenId
    ) external payable {
        uint256 premium = s_pendingQuotes[requestId];
        require(premium > 0, "Invalid requestId");
        require(msg.value == premium, "Incorrect premium sent");

        s_policyCounter++;
        uint256 policyId = s_policyCounter;

        policies[policyId] = Policy({
            policyId: policyId,
            policyHolder: msg.sender,
            nftContractAddress: nftContractAddress,
            nftTokenId: nftTokenId,
            premiumPaid: premium,
            coverageValue: premium * 10, // 10x coverage logic
            expirationTimestamp: uint64(block.timestamp + 30 days),
            isActive: true,
            lossReported: false,
            claimed: false
        });

        ownerToPolicyIds[msg.sender].push(policyId);

        emit PolicyCreated(policyId, msg.sender, nftContractAddress, nftTokenId);
    }

    function reportLoss(uint256 policyId) external {
        Policy storage policy = policies[policyId];
        require(policy.policyHolder == msg.sender, "Not your policy");
        require(policy.isActive, "Policy inactive");
        require(!policy.lossReported, "Already reported");
        require(block.timestamp < policy.expirationTimestamp, "Policy expired");

        policy.lossReported = true;
        emit LossReported(policyId, msg.sender);
    }

    function claimPolicy(uint256 policyId) external {
        Policy storage policy = policies[policyId];
        require(policy.policyHolder == msg.sender, "Not your policy");
        require(policy.isActive, "Policy inactive");
        require(policy.lossReported, "Loss not reported");
        require(!policy.claimed, "Already claimed");
        require(block.timestamp < policy.expirationTimestamp, "Policy expired");
        require(address(this).balance >= policy.coverageValue, "Insufficient contract balance");

        policy.isActive = false;
        policy.claimed = true;

        (bool sent, ) = msg.sender.call{value: policy.coverageValue}("");
        require(sent, "Claim transfer failed");

        emit PolicyClaimed(policyId, msg.sender, policy.coverageValue);
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (err.length == 0) {
            uint256 calculatedPremium = abi.decode(response, (uint256));
            s_pendingQuotes[requestId] = calculatedPremium;
            emit QuoteReceived(requestId, calculatedPremium);
        }
    }

    function getPoliciesByOwner(address owner) external view returns (Policy[] memory) {
        uint256[] memory ids = ownerToPolicyIds[owner];
        Policy[] memory result = new Policy[](ids.length);
        for (uint i = 0; i < ids.length; i++) {
            result[i] = policies[ids[i]];
        }
        return result;
    }

    receive() external payable {}
}
