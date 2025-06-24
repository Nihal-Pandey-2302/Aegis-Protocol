import React from 'react';

/**
 * NftGallery Component
 * A "dumb" component that receives a list of uninsured NFTs and a click handler.
 * It has no logic of its own and simply displays what it's given.
 */
function NftGallery({ uninsuredNfts, onInsureClick }) {
  return (
    <div>
      <h3>Your Uninsured NFTs</h3>
      <div className="nft-gallery">
        {uninsuredNfts.length > 0 ? (
          uninsuredNfts.map(nft => (
            <div key={nft.tokenId + nft.contract.address} className="nft-card">
              <img src={nft.image.cachedUrl} alt={nft.name} />
              <div className="nft-card-info">
                <h4>{nft.name}</h4>
                <button 
                  className="insure-button" 
                  onClick={() => onInsureClick(nft)}
                >
                  Insure
                </button>
              </div>
            </div>
          ))
        ) : (
          <p className="loading-state">No uninsured NFTs found.</p>
        )}
      </div>
    </div>
  );
}

export default NftGallery;