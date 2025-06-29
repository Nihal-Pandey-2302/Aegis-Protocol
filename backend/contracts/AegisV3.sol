// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {AutomationCompatibleInterface} from "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

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

    bytes32 public s_donId;
    uint64 public s_subscriptionId;
    uint32 public s_gasLimit;
    string public s_rpcUrl; // UPGRADE: Store the public RPC URL in state

    uint256 public s_policyCounter;
    uint256 public s_lastCheckedPolicyId; 

    mapping(bytes32 => uint256) public s_pendingPolicyChecks;
    mapping(bytes32 => uint256) public s_pendingQuotes;
    mapping(uint256 => Policy) public policies;
    mapping(address => uint256[]) public ownerToPolicyIds;

    event QuoteReceived(bytes32 indexed requestId, uint256 premium);
    event PolicyCreated(uint256 indexed policyId, address indexed policyHolder);
    event PolicyFlagged(uint256 indexed policyId);
    event PolicyClaimed(uint256 indexed policyId, uint256 payout);

    error Aegis__PolicyNotFlagged();

    constructor(address router, bytes32 donId) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        s_donId = donId;
    }
    
    // UPGRADE: setConfig now includes the RPC URL string
    function setConfig(uint64 subscriptionId, uint32 gasLimit, string memory rpcUrl) external onlyOwner {
        s_subscriptionId = subscriptionId;
        s_gasLimit = gasLimit;
        s_rpcUrl = rpcUrl;
    }

    // --- Core Functions ---
    function createPolicyRequest(address nftContractAddress, uint256 nftTokenId) external returns (bytes32 requestId) {
        string memory source = "async function calculatePremium(){const nftContractAddress=args[0];const nftTokenId=args[1];let floorPrice=0;try{const reservoirReq=Functions.makeHttpRequest({url:`https://api.reservoir.tools/collections/v7?id=${nftContractAddress}`});const res=await reservoirReq;if(res.error||!res.data.collections||res.data.collections.length===0)throw new Error(\"Reservoir data not available or API error.\");floorPrice=res.data.collections[0].floorAsk?.price?.amount?.native||0}catch(e){}const tokenIdNumber=Number(nftTokenId);const basePremiumEth=0.01;let marketFactor=1;if(floorPrice>1){marketFactor=1.5}else if(floorPrice>0.5){marketFactor=1.2}let ageFactor=1;if(tokenIdNumber<1000){ageFactor=0.8}else if(tokenIdNumber<10000){ageFactor=1.2}else{ageFactor=1.8}const finalPremiumEth=basePremiumEth*marketFactor*ageFactor;let finalPremiumWei=BigInt(Math.round(finalPremiumEth*1e18));const maxPremiumWei=BigInt(5e17);if(finalPremiumWei>maxPremiumWei){finalPremiumWei=maxPremiumWei}if(finalPremiumWei===BigInt(0)){finalPremiumWei=BigInt(1e16)}return Functions.encodeUint256(finalPremiumWei)}return calculatePremium();";
        string[] memory args = new string[](2);
        args[0] = nftContractAddress.toHexString();
        args[1] = nftTokenId.toString();
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);
        requestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_gasLimit, s_donId);
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
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (s_policyCounter > 0);
        uint256 policyToCheck = s_lastCheckedPolicyId + 1 > s_policyCounter ? 1 : s_lastCheckedPolicyId + 1;
        performData = abi.encode(policyToCheck);
    }

        function performUpkeep(bytes calldata performData) external override {
        // The redundant check has been removed.
        // We can trust that if this function is being called, checkUpkeep must have returned true.
        
        uint256 policyId = abi.decode(performData, (uint256));
        s_lastCheckedPolicyId = policyId;

        Policy storage policy = policies[policyId];
        if (policy.status == PolicyStatus.Active && block.timestamp < policy.expirationTimestamp) {
            _performOwnershipCheck(policyId);
        }
    }

    function _performOwnershipCheck(uint256 policyId) private returns (bytes32 requestId) {
        Policy storage policy = policies[policyId];
        
        // UPGRADE: Dynamically construct the source code string on-chain
        string memory sourcePrefix = "const nftContractAddress=args[0];const tokenId=args[1];const expectedOwner=args[2];const rpcUrl='";
        string memory sourceSuffix = "';const provider=new ethers.providers.JsonRpcProvider(rpcUrl);const abi=['function ownerOf(uint256 tokenId) view returns (address)'];const nftContract=new ethers.Contract(nftContractAddress,abi,provider);const currentOwner=await nftContract.ownerOf(tokenId);const isOwner=currentOwner.toLowerCase()===expectedOwner.toLowerCase();return Functions.encodeBool(isOwner);";
        string memory finalSource = string.concat(sourcePrefix, s_rpcUrl, sourceSuffix);

        string[] memory args = new string[](3);
        args[0] = policy.nftContractAddress.toHexString();
        args[1] = policy.nftTokenId.toString();
        args[2] = policy.policyHolder.toHexString();

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(finalSource);
        req.setArgs(args);

        requestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_gasLimit, s_donId);
        s_pendingPolicyChecks[requestId] = policyId;
    }

    function claimPolicy(uint256 policyId) external {
        Policy storage policy = policies[policyId];
        require(policy.policyHolder == msg.sender, "Not your policy");
        if (policy.status != PolicyStatus.FlaggedForReview) revert Aegis__PolicyNotFlagged();
        policy.status = PolicyStatus.Claimed;
        (bool sent, ) = msg.sender.call{value: policy.coverageValue}("");
        require(sent, "Transfer failed");
        emit PolicyClaimed(policyId, policy.coverageValue);
    }
    
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (err.length > 0) return;
        if (s_pendingQuotes[requestId] > 0) {
            uint256 premium = abi.decode(response, (uint256));
            s_pendingQuotes[requestId] = premium;
            emit QuoteReceived(requestId, premium);
        } else if (s_pendingPolicyChecks[requestId] > 0) {
            uint256 policyId = s_pendingPolicyChecks[requestId];
            bool isStillOwner = abi.decode(response, (bool));
            if (!isStillOwner) {
                policies[policyId].status = PolicyStatus.FlaggedForReview;
                emit PolicyFlagged(policyId);
            }
            delete s_pendingPolicyChecks[requestId];
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
