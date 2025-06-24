import { useState, useEffect, useCallback } from 'react';
import { ethers } from 'ethers';
import { Outlet } from 'react-router-dom';
import toast, { Toaster } from 'react-hot-toast';
import { Alchemy, Network } from 'alchemy-sdk';
import InsuranceModal from './components/InsuranceModal.jsx';
import Header from './components/Header';
import Sidebar from './components/Sidebar';
import Footer from './components/Footer';
import { AEGIS_ABI, AEGIS_CONTRACT_ADDRESS } from './config/contract';

const CHAINLINK_SUBSCRIPTION_ID = "5065";
const alchemy = new Alchemy({ apiKey: import.meta.env.VITE_ALCHEMY_API_KEY, network: Network.ETH_SEPOLIA });

function Layout() {
  const [account, setAccount] = useState(null);
  const [provider, setProvider] = useState(null);
  const [contract, setContract] = useState(null);
  
  const [allNfts, setAllNfts] = useState([]);
  const [insuredNfts, setInsuredNfts] = useState([]);
  const [uninsuredNfts, setUninsuredNfts] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedNft, setSelectedNft] = useState(null);
  const [quotes, setQuotes] = useState({});
  const [activeRequestId, setActiveRequestId] = useState(null);
  const [activePolicies, setActivePolicies] = useState([]);  


  useEffect(() => {
    if (window.ethereum) {
      const newProvider = new ethers.providers.Web3Provider(window.ethereum);
      setProvider(newProvider);
    }
  }, []);

  useEffect(() => {
    if (!contract) return;
  
    const handleQuoteEvent = (requestId, premium) => {
      console.log("QuoteReceived event:", requestId, premium.toString());
  
      // Update selectedNft if relevant
      if (selectedNft && selectedNft.lastRequestId === requestId) {
        setSelectedNft(prev => ({ ...prev, quote: premium }));
      }
  
      // Optionally update quotes state if you use it
      setQuotes(prev => ({ ...prev, [requestId]: premium }));
    };
  
    contract.on("QuoteReceived", handleQuoteEvent);
    return () => contract.off("QuoteReceived", handleQuoteEvent);
  }, [contract, selectedNft]);
  

  // Layout.jsx — ABOVE useEffect
  const fetchAllData = useCallback(async () => {
    if (!contract || !account) return;
    setIsLoading(true);

    try {
      const nftsForOwner = await alchemy.nft.getNftsForOwner(account);
      const fetchedNfts = nftsForOwner.ownedNfts.filter(nft => nft.name && nft.image?.cachedUrl);
      setAllNfts(fetchedNfts);

      const policiesFromChain = await contract.getPoliciesByOwner(account);

      const nftMap = {};
      fetchedNfts.forEach(nft => {
        nftMap[`${nft.contract.address.toLowerCase()}-${nft.tokenId.toString()}`] = nft;
      });

      const enrichedPolicies = policiesFromChain.map(policy => {
        const key = `${policy.nftContractAddress.toLowerCase()}-${policy.nftTokenId.toString()}`;
        return {
          ...policy,
          ...nftMap[key],
        };
      });

      const insuredIdSet = new Set(
        policiesFromChain.map(p => `${p.nftContractAddress.toLowerCase()}-${p.nftTokenId.toString()}`)
      );

      const insuredList = [];
      const uninsuredList = [];

      fetchedNfts.forEach(nft => {
        const key = `${nft.contract.address.toLowerCase()}-${nft.tokenId.toString()}`;
        if (insuredIdSet.has(key)) {
          insuredList.push(nft);
        } else {
          uninsuredList.push(nft);
        }
      });

      setActivePolicies(enrichedPolicies);
      setInsuredNfts(insuredList);
      setUninsuredNfts(uninsuredList);

    } catch (error) {
      console.error("Error fetching dashboard data:", error);
      toast.error("Could not fetch your data. Please try again.");
    } finally {
      setIsLoading(false);
    }
  }, [contract, account]);

  // Fetch all user data when the account or contract changes
  useEffect(() => {
    fetchAllData();
  }, [account, contract]);
  
  

  const connectWallet = async () => {
    if (provider) {
      try {
        const accounts = await provider.send("eth_requestAccounts", []);
        const signer = provider.getSigner();
        const newContract = new ethers.Contract(AEGIS_CONTRACT_ADDRESS, AEGIS_ABI, signer);
        setAccount(accounts[0]);
        setContract(newContract);
      } catch (error) {
        console.error("Error connecting wallet:", error);
      }
    } else {
      alert("Please install MetaMask to use this application.");
    }
  };

  const handleOpenModal = (nft) => {
    setSelectedNft(nft);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedNft(null);
  };

  


  const handleCreatePolicy = async (nft) => {
    if (!contract) return toast.error("Please connect your wallet first.");
    
    handleCloseModal();
    const toastId = toast.loading('1/2: Please approve quote request...');
  
    try {
      const requestTx = await contract.createPolicyRequest(
        CHAINLINK_SUBSCRIPTION_ID, 
        nft.contract.address, 
        nft.tokenId
      );
      
      toast.loading('2/2: Request sent! Waiting for oracle...', { id: toastId });
  
      const receipt = await requestTx.wait();
      const event = receipt.events.find(e => e.event === 'RequestSent');
      if (!event) {
        throw new Error("Could not find RequestSent event in transaction logs.");
      }
      const requestId = event.args.id;
      console.log("Request sent. Waiting for fulfillment. Request ID:", requestId);
  
      // Set up a listener for the specific response
      contract.once(contract.filters.QuoteReceived(requestId), async (reqId, premium) => {
        console.log("Quote received from oracle:", ethers.utils.formatEther(premium), "ETH");
        toast.loading('Quote received! Please approve final payment...', { id: toastId, icon: "🔔" });
        
        try {
          const executeTx = await contract.executePolicy(requestId, nft.contract.address, nft.tokenId, { value: premium });
          await executeTx.wait();
          
          toast.success(`Policy for ${nft.name} created!`, { id: toastId, duration: 4000 });
          await fetchAllData(); // Refresh all data from the blockchain
  
        } catch (execError) {
          console.error("Policy execution failed:", execError);
          toast.error(`Execution failed: ${execError.reason || "Check console."}`, { id: toastId });
        }
      });
  
    } catch (error) {
      console.error("Quote request failed:", error);
      toast.error(`Request failed: ${error.reason || "Check console."}`, { id: toastId });
    }
  };

  const truncateAddress = (address) => {
    if (!address) return "";
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  };

  return (
    <div className="app-layout">
      <Toaster position="top-center" reverseOrder={false} />
      <Sidebar account={account} activePolicies={activePolicies} uninsuredNfts={uninsuredNfts} />
      <div className="main-app-content">
      <Header account={account} onConnect={connectWallet} />
        <div className="content-wrapper">
          {/* Outlet now passes all necessary data and functions to the child routes */}
          <Outlet context={{ 
          account, 
          contract,
          isLoading, 
          uninsuredNfts, 
          activePolicies,
          handleOpenModal,
          fetchAllData   // ✅ here
        }} />
        </div>
        <Footer />
      </div>
      {isModalOpen && (
        <InsuranceModal 
          nft={selectedNft}
          onClose={handleCloseModal}
          onConfirm={handleCreatePolicy}
        />
      )}
    </div>
  );
}

export default Layout;