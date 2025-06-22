// Aegis Dynamic Premium Calculation v3.1 - Resilient, Safe, Fallback-Protected
async function calculatePremium() {
  const nftContractAddress = args[0];
  const nftTokenId = args[1];

  let floorPrice = 0; // Default if API fails

  // --- TRY: Fetch live floor price from Reservoir API ---
  try {
    const reservoirReq = Functions.makeHttpRequest({
      url: `https://api.reservoir.tools/collections/v7?id=${nftContractAddress}`,
    });

    const res = await reservoirReq;
    if (res.error || !res.data.collections || res.data.collections.length === 0) {
      throw new Error("Reservoir data not available or API error.");
    }

    floorPrice = res.data.collections[0].floorAsk?.price?.amount?.native || 0;
    console.log(`SUCCESS: Live Floor Price fetched: ${floorPrice} ETH`);
  } catch (e) {
    console.log("LOG: Could not fetch live floor price. Using fallback simulation logic.");
  }

  // --- VALIDATE tokenId ---
  const tokenIdNumber = Number(nftTokenId);
  if (isNaN(tokenIdNumber)) {
    throw new Error("Invalid tokenId passed.");
  }

  // --- Base Premium Logic ---
  const basePremiumEth = 0.01;

  let marketFactor = 1.0;
  if (floorPrice > 1) {
    marketFactor = 1.5;
  } else if (floorPrice > 0.5) {
    marketFactor = 1.2;
  }

  let ageFactor = 1.0;
  if (tokenIdNumber < 1000) {
    ageFactor = 0.8;
  } else if (tokenIdNumber < 10000) {
    ageFactor = 1.2;
  } else {
    ageFactor = 1.8;
  }

  console.log(`Factors Used: Market=${marketFactor}, Age=${ageFactor}`);

  const finalPremiumEth = basePremiumEth * marketFactor * ageFactor;
  let finalPremiumWei = BigInt(Math.round(finalPremiumEth * 1e18));

  // --- SAFETY: Cap maximum premium ---
  const maxPremiumWei = BigInt(5e17); // Max 0.5 ETH
  if (finalPremiumWei > maxPremiumWei) {
    finalPremiumWei = maxPremiumWei;
  }

  // --- FALLBACK: Prevent zero premium ---
  if (finalPremiumWei === BigInt(0)) {
    finalPremiumWei = BigInt(1e16); // Fallback to 0.01 ETH
  }

  console.log(`Final Premium (Wei): ${finalPremiumWei.toString()}`);
  return Functions.encodeUint256(finalPremiumWei);
}

return calculatePremium();
