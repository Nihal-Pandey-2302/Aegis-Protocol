import React from 'react';
import '../styles/ActivePolicies.css';

function ActivePolicies({ policies = [], onReportLoss, onClaim }) {
  const getRemainingTime = (expiration) => {
    const expirationTimestamp = Number(expiration.toString());
    const now = Date.now() / 1000;
    const remaining = expirationTimestamp - now;
    if (remaining <= 0) return '⛔ Expired';
    const days = Math.floor(remaining / 86400);
    const hours = Math.floor((remaining % 86400) / 3600);
    return `⏳ ${days}d ${hours}h left`;
  };

  return (
    <div className="policies-container">
      <h3>Active Policies</h3>
      {policies.length > 0 ? (
        <div className="policies-list">
          {policies.map(policy => (
            <div key={policy.policyId} className="policy-card">
              <div className="policy-image-wrapper">
                {policy.image?.cachedUrl ? (
                  <img src={policy.image.cachedUrl} alt={policy.name || "NFT Image"} />
                ) : (
                  <div className="no-image-placeholder">No image</div>
                )}
  
                {policy.claimed && (
                  <span className="claimed-badge">✅ Claimed</span> 
                )}
  
                {!policy.claimed && policy.lossReported && (
                  <span className="loss-badge">⚠️ Loss Reported</span>
                )}
              </div>
  
              <div className="policy-info">
                <h4>{policy.name || `Token #${policy.nftTokenId}`}</h4>
                <p>Expires: ⏳ {getRemainingTime(policy.expirationTimestamp)}</p>
                <p>Premium Paid: {policy.premiumPaid ? `${(Number(policy.premiumPaid) / 1e18).toFixed(4)} ETH` : 'Not Available'}</p>
                {policy.lossReported && !policy.claimed && (
                  <p>Status: ⚠️ Loss Reported</p>
                )}
                {policy.claimed && (
                  <p>Status: ✅ Claimed</p>
                )}
              </div>
  
              <div className="policy-actions">
                {!policy.lossReported && !policy.claimed && (
                  <button onClick={() => onReportLoss(policy.policyId)} className="btn report-loss">
                    Report Loss
                  </button>
                )}
                {policy.lossReported && !policy.claimed && (
                  <button onClick={() => onClaim(policy.policyId)} className="btn claim-policy">
                    Claim
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="policies-list-placeholder">
          <p>Your insured NFTs will appear here.</p>
        </div>
      )}
    </div>
  );
}

export default ActivePolicies;
