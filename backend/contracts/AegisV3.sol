// SPDX-License-Identifier: MIT
/**
 * @title AegisV3 - The Autonomous Sentinel Protocol
 * @author Maniacs (Nihal Pandey, Anshika Srivastava)
 * @notice This contract is an autonomous, on-chain NFT insurance protocol. It allows users to
 * purchase insurance policies with dynamically priced premiums. Its core feature is an
 * autonomous sentinel, powered by a synergy of Chainlink Automation and Functions, that
 * proactively monitors insured assets for loss events (e.g., wallet compromise, theft)
 * and automatically flags them for claims.
 * @dev This protocol uses Chainlink Functions for two distinct purposes:
 * 1. DYNAMIC PRICING: Fetching NFT floor prices from the Reservoir API to calculate a risk-adjusted premium.
 * 2. AUTONOMOUS MONITORING: Using a public RPC to perform on-chain checks of NFT ownership.
 * Chainlink Automation acts as the "heartbeat" to trigger the autonomous monitoring function periodically.
 */
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

    /// @notice The status of an insurance policy.
    enum PolicyStatus { Active, Expired, Claimed, FlaggedForReview }

    /// @notice Represents an individual insurance policy for a single NFT.
    struct Policy {
        uint256 policyId;           // Unique identifier for the policy
        address policyHolder;       // The owner of the policy
        address nftContractAddress; // The contract address of the insured NFT
        uint256 nftTokenId;         // The token ID of the insured NFT
        uint256 premiumPaid;        // The premium paid by the user in WEI
        uint256 coverageValue;      // The payout amount if a claim is successful
        uint64 expirationTimestamp; // The UNIX timestamp when the policy expires
        PolicyStatus status;        // The current status of the policy
    }

    // --- Chainlink & Protocol Configuration ---
    bytes32 public s_donId;                                 /// @dev The ID of the Chainlink Functions DON.
    uint64 public s_subscriptionId;                          /// @dev The ID of the Chainlink Functions subscription.
    uint32 public s_gasLimit;                                /// @dev The gas limit for the Chainlink Functions request.
    string public s_rpcUrl;                                  /// @dev The public RPC URL used by the sentinel to check on-chain data.

    // --- Protocol State ---
    uint256 public s_policyCounter;                         /// @dev A counter to generate unique policy IDs.
    uint256 public s_lastCheckedPolicyId;                   /// @dev Tracks the last policy ID checked by the Automation upkeep for round-robin logic.

    // --- Request Tracking Mappings ---
    /// @dev Maps a Chainlink request ID to the policy ID it corresponds to for sentinel checks.
    mapping(bytes32 => uint256) public s_pendingPolicyChecks;
    /// @dev Maps a Chainlink request ID to the dynamically calculated premium. A value of 1 indicates a request is pending.
    mapping(bytes32 => uint256) public s_pendingQuotes;

    // --- Data Mappings ---
    /// @dev Maps a policy ID to its corresponding Policy struct.
    mapping(uint256 => Policy) public policies;
    /// @dev Maps a user's address to an array of their policy IDs.
    mapping(address => uint256[]) public ownerToPolicyIds;

    // --- Events ---
    event QuoteReceived(bytes32 indexed requestId, uint256 premium);
    event PolicyCreated(uint256 indexed policyId, address indexed policyHolder, uint256 premium, uint256 coverage);
    event PolicyFlagged(uint256 indexed policyId);
    event PolicyClaimed(uint256 indexed policyId, uint256 payout);

    // --- Errors ---
    error Aegis__PolicyNotFlagged();

    /// @param router The address of the Chainlink Functions Router contract.
    /// @param donId The bytes32 ID of the Chainlink Functions DON.
    constructor(address router, bytes32 donId) FunctionsClient(router) ConfirmedOwner(msg.sender) {
        s_donId = donId;
    }
    
    /// @notice Sets the core configuration parameters for the protocol. Can only be called by the owner.
    /// @param subscriptionId The Chainlink Functions subscription ID.
    /// @param gasLimit The gas limit for Functions requests.
    /// @param rpcUrl The public RPC URL for the sentinel to use.
    function setConfig(uint64 subscriptionId, uint32 gasLimit, string memory rpcUrl) external onlyOwner {
        s_subscriptionId = subscriptionId;
        s_gasLimit = gasLimit;
        s_rpcUrl = rpcUrl;
    }

    // --- CORE FUNCTIONS ---

    /// @notice Initiates a request for a dynamic insurance premium quote for a specific NFT.
    /// @dev Sends a request to Chainlink Functions. The JS source fetches floor price from the Reservoir API,
    ///      calculates a premium based on market factors and token ID, and returns the value.
    /// @param nftContractAddress The contract address of the NFT.
    /// @param nftTokenId The token ID of the NFT.
    /// @return requestId The ID of the sent Chainlink Functions request.
    function createPolicyRequest(address nftContractAddress, uint256 nftTokenId) external returns (bytes32 requestId) {
        string memory source = "async function calculatePremium(){const nftContractAddress=args[0];const nftTokenId=args[1];let floorPrice=0;try{const reservoirReq=Functions.makeHttpRequest({url:`https://api.reservoir.tools/collections/v7?id=${nftContractAddress}`});const res=await reservoirReq;if(res.error||!res.data.collections||res.data.collections.length===0)throw new Error(\"Reservoir data not available or API error.\");floorPrice=res.data.collections[0].floorAsk?.price?.amount?.native||0}catch(e){}const tokenIdNumber=Number(nftTokenId);const basePremiumEth=0.01;let marketFactor=1;if(floorPrice>1){marketFactor=1.5}else if(floorPrice>0.5){marketFactor=1.2}let ageFactor=1;if(tokenIdNumber<1000){ageFactor=0.8}else if(tokenIdNumber<10000){ageFactor=1.2}else{ageFactor=1.8}const finalPremiumEth=basePremiumEth*marketFactor*ageFactor;let finalPremiumWei=BigInt(Math.round(finalPremiumEth*1e18));const maxPremiumWei=BigInt(5e17);if(finalPremiumWei>maxPremiumWei){finalPremiumWei=maxPremiumWei}if(finalPremiumWei===BigInt(0)){finalPremiumWei=BigInt(1e16)}return Functions.encodeUint256(finalPremiumWei)}return calculatePremium();";
        string[] memory args = new string[](2);
        args[0] = nftContractAddress.toHexString();
        args[1] = nftTokenId.toString();
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);
        requestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_gasLimit, s_donId);
        s_pendingQuotes[requestId] = 1; // Mark as pending
    }

    /// @notice Pays the quoted premium to create and activate an insurance policy.
    /// @dev Validates that the msg.value matches the premium stored from the fulfillRequest callback.
    ///      Creates a new Policy struct, stores it, and associates it with the policyholder.
    /// @param requestId The ID of the original quote request.
    /// @param nftContractAddress The contract address of the NFT being insured.
    /// @param nftTokenId The token ID of the NFT being insured.
    function executePolicy(bytes32 requestId, address nftContractAddress, uint256 nftTokenId) external payable {
        uint256 premium = s_pendingQuotes[requestId];
        require(premium > 0, "Quote not ready or already used");
        require(msg.value == premium, "Incorrect premium paid");

        s_policyCounter++;
        uint256 policyId = s_policyCounter;
        uint256 coverage = premium * 10; // Example coverage calculation

        policies[policyId] = Policy(policyId, msg.sender, nftContractAddress, nftTokenId, premium, coverage, uint64(block.timestamp + 30 days), PolicyStatus.Active);
        ownerToPolicyIds[msg.sender].push(policyId);
        
        delete s_pendingQuotes[requestId]; // Clean up to prevent reuse
        emit PolicyCreated(policyId, msg.sender, premium, coverage);
    }
    
    // --- AUTONOMOUS SENTINEL FUNCTIONS ---

    /// @notice Called by the Chainlink Automation network to check if any policies require monitoring.
    /// @dev Implements a simple round-robin check. It checks one policy at a time, starting from s_lastCheckedPolicyId.
    ///      This ensures a consistent, low gas cost for the checkUpkeep call.
    /// @param checkData Arbitrary data sent by the Automation network (not used in this implementation).
    /// @return upkeepNeeded True if there is an active policy to monitor.
    /// @return performData ABI-encoded policyId that needs to be checked.
    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        if (s_policyCounter == 0) {
            return (false, "");
        }
        upkeepNeeded = true; // As long as there's one policy, we should check something.
        uint256 policyToCheck = s_lastCheckedPolicyId + 1;
        if (policyToCheck > s_policyCounter) {
            policyToCheck = 1;
        }
        performData = abi.encode(policyToCheck);
    }

    /// @notice Executes the monitoring check for a specific policy. Called by the Chainlink Automation network.
    /// @dev Decodes the policyId from performData and triggers the _performOwnershipCheck function
    ///      if the policy is currently active and not expired.
    /// @param performData The ABI-encoded policyId returned by checkUpkeep.
    function performUpkeep(bytes calldata performData) external override {
        uint256 policyId = abi.decode(performData, (uint256));
        s_lastCheckedPolicyId = policyId;

        Policy storage policy = policies[policyId];
        if (policy.status == PolicyStatus.Active && block.timestamp < policy.expirationTimestamp) {
            _performOwnershipCheck(policyId);
        }
    }

    /// @dev Internal function to dispatch the Chainlink Function request for the sentinel check.
    /// @dev This implementation is gas-optimized. It passes the RPC URL as an argument to the JS source
    ///      instead of using expensive on-chain `string.concat`, ensuring the upkeep simulation does not revert.
    /// @param policyId The ID of the policy to check.
    /// @return requestId The ID of the sent Chainlink Functions request.
    function _performOwnershipCheck(uint256 policyId) private returns (bytes32 requestId) {
        Policy storage policy = policies[policyId];
        
        string memory source = "const nftContractAddress=args[0];const tokenId=args[1];const expectedOwner=args[2];const rpcUrl=args[3];const provider=new ethers.providers.JsonRpcProvider(rpcUrl);const abi=['function ownerOf(uint256 tokenId) view returns (address)'];const nftContract=new ethers.Contract(nftContractAddress,abi,provider);try{const currentOwner=await nftContract.ownerOf(tokenId);const isOwner=currentOwner.toLowerCase()===expectedOwner.toLowerCase();return Functions.encodeBool(isOwner)}catch(e){return Functions.encodeBool(false)}";

        string[] memory args = new string[](4);
        args[0] = policy.nftContractAddress.toHexString();
        args[1] = policy.nftTokenId.toString();
        args[2] = policy.policyHolder.toHexString();
        args[3] = s_rpcUrl; // Pass the RPC URL as an argument for gas efficiency

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.setArgs(args);

        requestId = _sendRequest(req.encodeCBOR(), s_subscriptionId, s_gasLimit, s_donId);
        s_pendingPolicyChecks[requestId] = policyId;
    }

    // --- CLAIM & FULFILLMENT ---

    /// @notice Allows a policyholder to claim their payout after a loss has been automatically detected.
    /// @dev Requires the policy status to be FlaggedForReview, which is set by the `fulfillRequest`
    ///      callback from the sentinel. Transfers the coverage amount to the policyholder.
    /// @param policyId The ID of the policy to claim.
    function claimPolicy(uint256 policyId) external {
        Policy storage policy = policies[policyId];
        require(policy.policyHolder == msg.sender, "Not your policy");
        if (policy.status != PolicyStatus.FlaggedForReview) revert Aegis__PolicyNotFlagged();
        
        policy.status = PolicyStatus.Claimed;
        (bool sent, ) = msg.sender.call{value: policy.coverageValue}("");
        require(sent, "Transfer failed");

        emit PolicyClaimed(policyId, policy.coverageValue);
    }
    
    /// @notice The central callback function for all Chainlink Functions requests.
    /// @dev Acts as a router for responses. If the requestId corresponds to a pending quote, it stores the premium.
    ///      If it corresponds to a pending sentinel check, it processes the ownership result and flags the policy if necessary.
    /// @param requestId The unique ID of the request being fulfilled.
    /// @param response The CBOR-encoded response data from the Functions DON.
    /// @param err Any error data from the Functions DON.
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (err.length > 0) {
            // Handle potential errors, e.g., unlocking a pending check
            if (s_pendingPolicyChecks[requestId] > 0) {
                delete s_pendingPolicyChecks[requestId];
            }
            return;
        }

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
    
    /// @notice Retrieves all policies owned by a specific address.
    /// @param owner The address to query.
    /// @return An array of Policy structs owned by the address.
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
