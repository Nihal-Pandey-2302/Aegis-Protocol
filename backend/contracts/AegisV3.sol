// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
// UPGRADE: This is the correct, standard interface for making a contract compatible with Chainlink Automation.
import {AutomationCompatibleInterface} from "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

// UPGRADE: Inherit from AutomationCompatibleInterface
contract AegisV3 is FunctionsClient, ConfirmedOwner, AutomationCompatibleInterface {
    using FunctionsRequest for FunctionsRequest.Request;
    using Strings for uint256;
    using Strings for address;

    enum PolicyStatus { Active, Expired, Claimed, FlaggedForReview }

    struct Policy {
        uint256 policyId;
        address policyHolder;
        address nftContractAddress;
        uint256 nftTokenId;
        uint256 premiumPaid;
        uint256 coverageValue;
        uint64 expirationTimestamp;
        PolicyStatus status;
    }

    enum RequestType { PremiumQuote, OwnershipCheck }
    
    bytes32 public s_donId;
    uint64 public s_subscriptionId;
    uint32 public s_gasLimit;
    uint256 public s_policyCounter;

    // UPGRADE: New state variables for Automation
    uint256 public s_lastCheckedPolicyId; 

    mapping(bytes32 => RequestType) public s_requestType;
    mapping(bytes32 => uint256) public s_pendingPolicyChecks;
    mapping(bytes32 => uint256) public s_pendingQuotes;
    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public ownerToPolicyIds;

    event QuoteReceived(bytes32 indexed requestId, uint256 premium);
    event PolicyCreated(uint256 indexed policyId, address indexed policyHolder);
    event PolicyFlagged(uint256 indexed policyId);
    event PolicyClaimed(uint256 indexed policyId, uint256 payout);

    error Aegis__NotYourPolicy();
    error Aegis__PolicyNotFlagged();
    error Aegis__InsufficientContractBalance();
    error Aegis__TransferFailed();

    constructor(address router, bytes32 donId) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        s_donId = donId;
        s_lastCheckedPolicyId = 0;
        s_policyCounter = 0;
    }
    
    function setConfig(uint64 subscriptionId, uint32 gasLimit) external onlyOwner {
        s_subscriptionId = subscriptionId;
        s_gasLimit = gasLimit;
    }

    // --- Core Functions (Unchanged) ---
    function createPolicyRequest(address nftContractAddress, uint256 nftTokenId) external returns (bytes32 requestId) {
        string memory source = "async function calculatePremium(){const nftContractAddress=args[0];const nftTokenId=args[1];let floorPrice=0;try{const reservoirReq=Functions.makeHttpRequest({url:`https://api.reservoir.tools/collections/v7?id=${nftContractAddress}`});const res=await reservoirReq;if(res.error||!res.data.collections||res.data.collections.length===0)throw new Error(\"Reservoir data not available or API error.\");floorPrice=res.data.collections[0].floorAsk?.price?.amount?.native||0}catch(e){}const tokenIdNumber=Number(nftTokenId);const basePremiumEth=0.01;let marketFactor=1;if(floorPrice>1){marketFactor=1.5}else if(floorPrice>0.5){marketFactor=1.2}let ageFactor=1;if(tokenIdNumber<1000){ageFactor=0.8}else if(tokenIdNumber<10000){ageFactor=1.2}else{ageFactor=1.8}const finalPremiumEth=basePremiumEth*marketFactor*ageFactor;let finalPremiumWei=BigInt(Math.round(finalPremiumEth*1e18));const maxPremiumWei=BigInt(5e17);if(finalPremiumWei>maxPremiumWei){finalPremiumWei=maxPremiumWei}if(finalPremiumWei===BigInt(0)){finalPremiumWei=BigInt(1e16)}return Functions.encodeUint256(finalPremiumWei)}return calculatePremium();";
        string[] memory args = new string[](2);
        args[0] = nftContractAddress.toHexString();
        args[1] = nftTokenId.toString();

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);

        requestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_gasLimit, s_donId);
        s_requestType[requestId] = RequestType.PremiumQuote;
        s_pendingQuotes[requestId] = 1; 
    }

    function executePolicy(bytes32 requestId, address nftContractAddress, uint256 nftTokenId) external payable {
        uint256 premium = s_pendingQuotes[requestId];
        require(premium > 0, "Quote not ready");
        require(msg.value == premium, "Incorrect premium");

        s_policyCounter++;
        uint256 policyId = s_policyCounter;
        policies[policyId] = Policy(policyId, msg.sender, nftContractAddress, nftTokenId, premium, premium * 10, uint64(block.timestamp + 30 days), PolicyStatus.Active);
        ownerToPolicyIds[msg.sender].push(policyId);
        delete s_pendingQuotes[requestId];
        emit PolicyCreated(policyId, msg.sender);
    }
    
    // --- Automation and Sentinel Functions ---

    // UPGRADE: This function tells the Automation Network IF there's work to do.
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (s_policyCounter > 0); // Only run if there's at least one policy.
        uint256 policyToCheck = s_lastCheckedPolicyId + 1;
        if (policyToCheck > s_policyCounter) {
            policyToCheck = 1; // Loop back to the first policy
        }
        performData = abi.encode(policyToCheck);
    }

    // UPGRADE: This function is CALLED by the Automation Network when checkUpkeep is true.
    function performUpkeep(bytes calldata performData) external override {
        uint256 policyId = abi.decode(performData, (uint256));
        s_lastCheckedPolicyId = policyId; // Update the last checked ID

        Policy storage policy = policies[policyId];
        // Only check active policies that haven't expired
        if (policy.status == PolicyStatus.Active && block.timestamp < policy.expirationTimestamp) {
            _performOwnershipCheck(policyId);
        }
    }

    function _performOwnershipCheck(uint256 policyId) private returns (bytes32 requestId) {
        Policy storage policy = policies[policyId];
        string memory source = "const nftContractAddress=args[0];const tokenId=args[1];const expectedOwner=args[2];const rpcUrl=secrets.RPC_URL;if(!rpcUrl){throw new Error('RPC_URL not set in secrets')}const provider=new ethers.providers.JsonRpcProvider(rpcUrl);const abi=['function ownerOf(uint256 tokenId) view returns (address)'];const nftContract=new ethers.Contract(nftContractAddress,abi,provider);const currentOwner=await nftContract.ownerOf(tokenId);const isOwner=currentOwner.toLowerCase()===expectedOwner.toLowerCase();return Functions.encodeBool(isOwner);";
        string[] memory args = new string[](3);
        args[0] = policy.nftContractAddress.toHexString();
        args[1] = policy.nftTokenId.toString();
        args[2] = policy.policyHolder.toHexString();

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);
        req.addDONHostedSecrets("0x0");

        requestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_gasLimit, s_donId);
        s_requestType[requestId] = RequestType.OwnershipCheck;
        s_pendingPolicyChecks[requestId] = policyId;
    }

    function claimPolicy(uint256 policyId) external {
        Policy storage policy = policies[policyId];
        if (policy.policyHolder != msg.sender) revert Aegis__NotYourPolicy();
        if (policy.status != PolicyStatus.FlaggedForReview) revert Aegis__PolicyNotFlagged();
        
        policy.status = PolicyStatus.Claimed;

        (bool sent, ) = msg.sender.call{value: policy.coverageValue}("");
        if (!sent) revert Aegis__TransferFailed();

        emit PolicyClaimed(policyId, policy.coverageValue);
    }
    
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (err.length > 0) { /* Handle error */ return; }
        RequestType requestType = s_requestType[requestId];

        if (requestType == RequestType.PremiumQuote) {
            uint256 premium = abi.decode(response, (uint256));
            s_pendingQuotes[requestId] = premium;
            emit QuoteReceived(requestId, premium);
        } 
        else if (requestType == RequestType.OwnershipCheck) {
            uint256 policyId = s_pendingPolicyChecks[requestId];
            bool isStillOwner = abi.decode(response, (bool));
            if (!isStillOwner) {
                policies[policyId].status = PolicyStatus.FlaggedForReview;
                emit PolicyFlagged(policyId);
            }
            delete s_pendingPolicyChecks[requestId];
        }
    }
    
    // --- Other Functions ---
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
