// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {IAutomationRegistrar2_1} from "@chainlink/contracts/src/v0.8/interfaces/IAutomationRegistrar2_1.sol"; // UPGRADE: Import Automation interface
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract AegisV3 is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;
    using Strings for uint256;
    using Strings for address;

    // UPGRADE: A more robust state machine for policies.
    enum PolicyStatus {
        Active,
        Expired,
        Claimed,
        FlaggedForReview // <-- The new, crucial state
    }

    struct Policy {
        uint256 policyId;
        address policyHolder;
        address nftContractAddress;
        uint256 nftTokenId;
        uint256 premiumPaid;
        uint256 coverageValue;
        uint64 expirationTimestamp;
        PolicyStatus status; // UPGRADE: Replaced booleans with the enum
    }

    // UPGRADE: Define different types of requests to handle them in one callback
    enum RequestType {
        PremiumQuote,
        OwnershipCheck
    }
    
    bytes32 public s_donId;
    uint64 public s_subscriptionId; // UPGRADE: Store subscriptionId
    uint32 public s_gasLimit; // UPGRADE: Store gasLimit

    // UPGRADE: Mappings to track different request types
    mapping(bytes32 => RequestType) public s_requestType;
    mapping(bytes32 => uint256) public s_pendingPolicyChecks;
    mapping(bytes32 => uint256) public s_pendingQuotes;

    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public ownerToPolicyIds;
    uint256 private s_policyCounter;

    // --- Events ---
    event QuoteReceived(bytes32 indexed requestId, uint256 premium);
    event PolicyCreated(uint256 indexed policyId, address indexed policyHolder, address nftContract, uint256 tokenId);
    event PolicyFlagged(uint256 indexed policyId, address indexed owner); // UPGRADE: New event
    event PolicyClaimed(uint256 indexed policyId, address indexed claimant, uint256 payout);

    // --- Errors ---
    error Aegis__NotYourPolicy();
    error Aegis__PolicyNotActive();
    error Aegis__PolicyNotFlagged();
    error Aegis__AlreadyClaimed();
    error Aegis__PolicyExpired();
    error Aegis__InsufficientContractBalance();
    error Aegis__TransferFailed();

    constructor(address router, bytes32 donId)
        FunctionsClient(router)
        ConfirmedOwner(msg.sender)
    {
        s_donId = donId;
    }
    
    // UPGRADE: Function to set core Chainlink configuration
    function setConfig(uint64 subscriptionId, uint32 gasLimit) external onlyOwner {
        s_subscriptionId = subscriptionId;
        s_gasLimit = gasLimit;
    }

    // --- Original Functionality: Requesting a Premium Quote ---
    function createPolicyRequest(
        address nftContractAddress,
        uint256 nftTokenId
    ) external returns (bytes32 requestId) {
        string memory source = "async function calculatePremium(){const nftContractAddress=args[0];const nftTokenId=args[1];let floorPrice=0;try{const reservoirReq=Functions.makeHttpRequest({url:`https://api.reservoir.tools/collections/v7?id=${nftContractAddress}`});const res=await reservoirReq;if(res.error||!res.data.collections||res.data.collections.length===0)throw new Error(\"Reservoir data not available or API error.\");floorPrice=res.data.collections[0].floorAsk?.price?.amount?.native||0;console.log(`SUCCESS: Live Floor Price fetched: ${floorPrice} ETH`)}catch(e){console.log(\"LOG: Could not fetch live floor price. Using fallback simulation logic.\")}const tokenIdNumber=Number(nftTokenId);if(isNaN(tokenIdNumber))throw new Error(\"Invalid tokenId passed.\");const basePremiumEth=0.01;let marketFactor=1.0;if(floorPrice>1){marketFactor=1.5}else if(floorPrice>0.5){marketFactor=1.2}let ageFactor=1.0;if(tokenIdNumber<1000){ageFactor=0.8}else if(tokenIdNumber<10000){ageFactor=1.2}else{ageFactor=1.8}console.log(`Factors Used: Market=${marketFactor}, Age=${ageFactor}`);const finalPremiumEth=basePremiumEth*marketFactor*ageFactor;let finalPremiumWei=BigInt(Math.round(finalPremiumEth*1e18));const maxPremiumWei=BigInt(5e17);if(finalPremiumWei>maxPremiumWei){finalPremiumWei=maxPremiumWei}if(finalPremiumWei===BigInt(0)){finalPremiumWei=BigInt(1e16)}console.log(`Final Premium (Wei): ${finalPremiumWei.toString()}`);return Functions.encodeUint256(finalPremiumWei)}return calculatePremium();";
        string[] memory args = new string[](2);
        args[0] = nftContractAddress.toHexString();
        args[1] = nftTokenId.toString();

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);

        requestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_gasLimit, s_donId);
        s_requestType[requestId] = RequestType.PremiumQuote; // UPGRADE: Track request type
        s_pendingQuotes[requestId] = 1; // Mark as pending
    }

    // --- NEW AUTONOMOUS FUNCTIONALITY ---
    // UPGRADE: This function is called by Chainlink Automation. It triggers the ownership check.
    function performOwnershipCheck(uint256 policyId) external returns (bytes32 requestId) {
        Policy storage policy = policies[policyId];
        if(policy.status != PolicyStatus.Active) { revert Aegis__PolicyNotActive(); }
        if(block.timestamp >= policy.expirationTimestamp) { 
            policy.status = PolicyStatus.Expired;
            return bytes32(0);
        }

        string memory source = "const nftContractAddress=args[0];const tokenId=args[1];const expectedOwner=args[2];const rpcUrl=secrets.RPC_URL;if(!rpcUrl){throw new Error('RPC_URL not set in secrets')}const provider=new ethers.providers.JsonRpcProvider(rpcUrl);const abi=['function ownerOf(uint256 tokenId) view returns (address)'];const nftContract=new ethers.Contract(nftContractAddress,abi,provider);const currentOwner=await nftContract.ownerOf(tokenId);const isOwner=currentOwner.toLowerCase()===expectedOwner.toLowerCase();return Functions.encodeBool(isOwner);";
        
        string[] memory args = new string[](3);
        args[0] = policy.nftContractAddress.toHexString();
        args[1] = policy.nftTokenId.toString();
        args[2] = policy.policyHolder.toHexString();

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);
        // UPGRADE: This expects you to upload secrets with your RPC URL.
        // Command: npx @chainlink/functions-toolkit secrets-set --slot-id 0 --ttl 1440 --network sepolia --key RPC_URL --value YOUR_ALCHEMY_OR_INFURA_URL
        req.addDONHostedSecrets("0x0");

        requestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_gasLimit, s_donId);
        s_requestType[requestId] = RequestType.OwnershipCheck; // UPGRADE: Track request type
        s_pendingPolicyChecks[requestId] = policyId;
    }


    function executePolicy(bytes32 requestId, address nftContractAddress, uint256 nftTokenId) external payable {
        uint256 premium = s_pendingQuotes[requestId];
        require(premium > 0, "Quote not ready or invalid");
        require(msg.value == premium, "Incorrect premium");

        s_policyCounter++;
        uint256 policyId = s_policyCounter;

        policies[policyId] = Policy({
            policyId: policyId,
            policyHolder: msg.sender,
            nftContractAddress: nftContractAddress,
            nftTokenId: nftTokenId,
            premiumPaid: premium,
            coverageValue: premium * 10,
            expirationTimestamp: uint64(block.timestamp + 30 days),
            status: PolicyStatus.Active
        });

        ownerToPolicyIds[msg.sender].push(policyId);
        delete s_pendingQuotes[requestId];
        emit PolicyCreated(policyId, msg.sender, nftContractAddress, nftTokenId);
    }

    // UPGRADE: claimPolicy now relies on the policy being 'FlaggedForReview'
    function claimPolicy(uint256 policyId) external {
        Policy storage policy = policies[policyId];
        if (policy.policyHolder != msg.sender) { revert Aegis__NotYourPolicy(); }
        if (policy.status != PolicyStatus.FlaggedForReview) { revert Aegis__PolicyNotFlagged(); }
        if (block.timestamp >= policy.expirationTimestamp) { revert Aegis__PolicyExpired(); }
        if (address(this).balance < policy.coverageValue) { revert Aegis__InsufficientContractBalance(); }

        policy.status = PolicyStatus.Claimed;

        (bool sent, ) = msg.sender.call{value: policy.coverageValue}("");
        if (!sent) { revert Aegis__TransferFailed(); }

        emit PolicyClaimed(policyId, msg.sender, policy.coverageValue);
    }
    
    // UPGRADE: The single callback now handles both types of requests.
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        RequestType requestType = s_requestType[requestId];

        if (requestType == RequestType.PremiumQuote) {
            if (err.length > 0) {
                // Handle error for premium quote if needed
                delete s_pendingQuotes[requestId];
                return;
            }
            uint256 calculatedPremium = abi.decode(response, (uint256));
            s_pendingQuotes[requestId] = calculatedPremium;
            emit QuoteReceived(requestId, calculatedPremium);
        } 
        else if (requestType == RequestType.OwnershipCheck) {
            uint256 policyId = s_pendingPolicyChecks[requestId];
            if (err.length > 0) {
                // Handle error for ownership check if needed
                delete s_pendingPolicyChecks[requestId];
                return;
            }
            bool isStillOwner = abi.decode(response, (bool));
            if (!isStillOwner) {
                policies[policyId].status = PolicyStatus.FlaggedForReview;
                emit PolicyFlagged(policyId, policies[policyId].policyHolder);
            }
            delete s_pendingPolicyChecks[requestId];
        }
        delete s_requestType[requestId];
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
