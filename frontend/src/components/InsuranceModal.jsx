import React from 'react';
import { ethers } from 'ethers';
import '../styles/InsuranceModal.css';

function InsuranceModal({ nft, quote, onClose, onConfirm }) {
  if (!nft) return null;

  const handleConfirm = () => {
    // onConfirm now starts the entire process
    onConfirm(nft);
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-content" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Insure NFT</h2>
          <button className="close-button" onClick={onClose}>&times;</button>
        </div>
        <div className="modal-body">
          <img src={nft.image.cachedUrl} alt={nft.name} className="modal-nft-image" />
          <h3>{nft.name}</h3>
          <div className="premium-quote">
            <p>Dynamic Premium Quote:</p>
            {quote ? (
              // If a quote has arrived, display it
              <strong>{ethers.utils.formatEther(quote)} ETH</strong>
            ) : (
              // Otherwise, show placeholder
              <strong>Click "Confirm" to request a quote.</strong>
            )}
          </div>
        </div>
        <div className="modal-footer">
           <button className="confirm-button" onClick={handleConfirm}>
             Accept & Pay Premium
           </button>
        </div>
      </div>
    </div>
  );
}

export default InsuranceModal;