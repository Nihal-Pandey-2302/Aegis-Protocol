import React, { useState } from 'react';
import blockies from 'ethereum-blockies';
import toast from 'react-hot-toast';
import { Clipboard, Check } from 'lucide-react';

function truncateAddress(address) {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function Header({ account, onConnect }) {
  const [copied, setCopied] = useState(false);

  const copyToClipboard = () => {
    if (!account) return;
    navigator.clipboard.writeText(account);
    setCopied(true);
    toast.success("Wallet address copied!");
    setTimeout(() => setCopied(false), 1500);
  };

  const avatar = account
    ? blockies.create({ seed: account }).toDataURL()
    : null;

  return (
    <header className="app-header">
      <div></div>
      {account ? (
        <div
          className="wallet-info"
          onClick={copyToClipboard}
          title="Click to copy"
        >
          <img className="wallet-avatar" src={avatar} alt="Wallet Avatar" />
          <span>{truncateAddress(account)}</span>
          {copied ? (
            <Check size={16} className="copy-icon copied" />
          ) : (
            <Clipboard size={16} className="copy-icon" />
          )}
        </div>
      ) : (
        <button onClick={onConnect} className="connectButton">
          Connect Wallet
        </button>
      )}
    </header>
  );
}

export default Header;
