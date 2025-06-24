import React, { useEffect, useState } from "react";
import { Link, NavLink } from "react-router-dom";
import { ethers } from "ethers";
import { Alchemy, Network } from 'alchemy-sdk';
import { AEGIS_ABI, AEGIS_CONTRACT_ADDRESS } from '../config/contract';
import "../styles/Sidebar.css";

const CHAINLINK_SUBSCRIPTION_ID = "5065";
const alchemy = new Alchemy({ apiKey: import.meta.env.VITE_ALCHEMY_API_KEY, network: Network.ETH_SEPOLIA });
function Sidebar({ account, activePolicies, uninsuredNfts = [] }) {

  // Calculate user-specific stats
  const userActivePolicies = activePolicies.filter(p => p.isActive);
  const totalCoverageWei = userActivePolicies.reduce((acc, policy) => acc.add(policy.coverageValue), ethers.BigNumber.from(0));
  const totalCoverageEth = ethers.utils.formatEther(totalCoverageWei);

  const totalPremiumWei = userActivePolicies.reduce((acc, policy) => acc.add(policy.premiumPaid), ethers.BigNumber.from(0));
  const totalPremiumEth = ethers.utils.formatEther(totalPremiumWei);



  const policiesNearExpiry = userActivePolicies.filter(p => {
    const expiry = Number(p.expirationTimestamp);
    const now = Math.floor(Date.now() / 1000);
    return expiry - now <= 7 * 24 * 60 * 60; // within 7 days
  });
  
  const mostRecentPolicy = userActivePolicies.reduce((latest, p) => {
    return (p.expirationTimestamp > latest.expirationTimestamp ? p : latest);
  }, { expirationTimestamp: 0 });
  
  const averageCoverage = userActivePolicies.length > 0
    ? ethers.utils.formatEther(totalCoverageWei.div(userActivePolicies.length))
    : "0.0";
  

  
  return (
    <aside className="sidebar">
      <Link to="/">
        <div className="sidebar-logo">🛡️ Aegis</div>
      </Link>

      <nav className="sidebar-nav">
        <ul>
          <li><NavLink to="/">📊 Dashboard</NavLink></li>
          <li><NavLink to="/policies">📜 My Policies</NavLink></li>
          <li><NavLink to="/how-it-works">❓ How It Works</NavLink></li>
        </ul>
      </nav>

      {account && (
      <div className="sidebar-stats">
        <h4>Your Stats</h4>
        <div className="stat-item">
          <span className="stat-label">Active Policies</span>
          <span className="stat-value">{userActivePolicies.length}</span>
        </div>
        <div className="stat-item">
          <span className="stat-label">Total Coverage</span>
          <span className="stat-value">{totalCoverageEth} ETH</span>
        </div>
        <div className="stat-item">
          <span className="stat-label">Total Premium Paid</span>
          <span className="stat-value">{totalPremiumEth} ETH</span>
        </div>
        <div className="stat-item">
          <span className="stat-label">Avg Coverage per Policy</span>
          <span className="stat-value">
            {userActivePolicies.length > 0
              ? (Number(totalCoverageEth) / userActivePolicies.length).toFixed(3)
              : "0.000"} ETH
          </span>
        </div>
        <div className="stat-item">
          <span className="stat-label">Expiring Soon</span>
          <span className="stat-value">{policiesNearExpiry.length}</span>
        </div>
        <div className="stat-item">
          <span className="stat-label">Uninsured NFTs</span>
          <span className="stat-value">{uninsuredNfts.length}</span>
        </div>
      </div>
    )}


      <div className="sidebar-stats">
        <h4>Protocol Stats</h4>
        <div className="stat-item">
          <span className="stat-label">Total Value Insured</span>
          <span className="stat-value">$1,234,567</span>
        </div>
        <div className="stat-item">
          <span className="stat-label">Active Policies</span>
          <span className="stat-value">1,432</span>
        </div>
        <div className="stat-item">
          <span className="stat-label">Supported Collections</span>
          <span className="stat-value">88</span>
        </div>
      </div>
    </aside>
  );
}

export default Sidebar;