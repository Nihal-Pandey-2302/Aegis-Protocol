// Aegis Ownership Sentinel v1.0
// This script is executed by a Chainlink Function.
// It receives NFT details and an expected owner, then uses an RPC provider
// to check the current owner of the NFT directly on the blockchain.

const nftContractAddress = args[0];
const tokenId = args[1];
const expectedOwner = args[2];

// You MUST upload your RPC provider URL (e.g., from Alchemy or Infura) as a secret
const rpcUrl = secrets.RPC_URL;
if (!rpcUrl) {
  throw new Error("RPC_URL not set in secrets");
}

const provider = new ethers.providers.JsonRpcProvider(rpcUrl);

// Minimal ABI for the ERC721 ownerOf function
const abi = ["function ownerOf(uint256 tokenId) view returns (address)"];
const nftContract = new ethers.Contract(nftContractAddress, abi, provider);

console.log(`Checking ownership of NFT ${nftContractAddress} token ${tokenId}...`);
console.log(`Expecting owner: ${expectedOwner}`);

// Make the call to the NFT contract
const currentOwner = await nftContract.ownerOf(tokenId);
console.log(`Current on-chain owner: ${currentOwner}`);

// Compare and return the boolean result
const isOwner = currentOwner.toLowerCase() === expectedOwner.toLowerCase();
console.log(`Is expected owner still the holder? ${isOwner}`);

return Functions.encodeBool(isOwner);
