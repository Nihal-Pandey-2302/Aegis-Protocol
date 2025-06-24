import React from 'react';
import { useOutletContext } from 'react-router-dom';
import NftGallery from './components/NftGallery';
import ActivePolicies from './components/ActivePolicies';
import toast from 'react-hot-toast';
import './styles/Dashboard.css';

function Dashboard() {
  // Receive all data from the parent Layout component via the context hook
  const { account, isLoading, uninsuredNfts, activePolicies, handleOpenModal, contract, fetchAllData } = useOutletContext();


  const onReportLoss = async (policyId) => {
    const toastId = toast.loading("Reporting loss..."); // create toast with ID
    try {
      const tx = await contract.reportLoss(policyId);
      await tx.wait();
      toast.success("Loss reported successfully.", { id: toastId }); // update same toast
      await fetchAllData();
    } catch (err) {
      toast.error("Failed to report loss.", { id: toastId }); // show error on same toast
      console.error(err);
    }
  };
  

const onClaim = async (policyId) => {
  toast.loading("Claiming payout...");
  try {
    const tx = await contract.claimPolicy(policyId);
    await tx.wait();
    toast.success("Claim successful!");
    await fetchAllData();
  } catch (err) {
    toast.error("Claim failed.");
    console.error(err);
  }
};

  

  return (
    <main className="app-container">
      <div className="main-content">
        {account ? (
          isLoading ? (
            <div className="loading-state">Loading Your Dashboard...</div>
          ) : (
            <>
              <div className="hero-section">
                <h2>Protect Your Digital Assets</h2>
                <p>Aegis offers dynamic, on-demand insurance for your valuable NFTs. Select an asset below to get a real-time risk assessment and premium quote.</p>
              </div>
              <div className="content-columns">
                <div className="left-column">
                  <NftGallery uninsuredNfts={uninsuredNfts} onInsureClick={handleOpenModal} />
                </div>
                <div className="right-column">
                <ActivePolicies 
                  policies={activePolicies}
                  onReportLoss={onReportLoss}
                  onClaim={onClaim}
                />
                </div>
              </div>
            </>
          )
        ) : (
          <div className='loading-state'>
            <h2>Welcome to Aegis</h2>
            <p>Please connect your wallet to view and insure your NFTs.</p>
          </div>
        )}
      </div>
    </main>
  );
}

export default Dashboard;