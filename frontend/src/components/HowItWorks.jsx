import React from 'react';
import '../styles/HowItWorks.css';

const steps = [
  {
    title: 'Connect Your Wallet',
    description:
      'Securely connect your crypto wallet to start protecting your valuable NFTs and tokenized assets.',
  },
  {
    title: 'Explore Your Digital Assets',
    description:
      'View all your uninsured NFTs and tokenized assets on the dashboard, ready for tailored insurance coverage.',
  },
  {
    title: 'Request a Dynamic Quote',
    description:
      'Click “Insure” on any asset to get a real-time, AI-powered risk assessment and a data-driven premium quote.',
  },
  {
    title: 'Trustless Oracle Integration',
    description:
      'Chainlink Functions securely fetch off-chain AI risk scores and market data to calculate precise premiums on-chain.',
  },
  {
    title: 'Approve & Activate Coverage',
    description:
      'Approve the transaction in your wallet to purchase an insurance policy fully managed by decentralized smart contracts.',
  },
  {
    title: 'Monitor & Manage Policies',
    description:
      'Your insured assets move to Active Policies — monitor coverage and rest easy knowing your investments are safeguarded.',
  },
];

export default function HowItWorks() {
  return (
    <section className="how-it-works">
      <h2>How Aegis Protects Your Digital Assets</h2>
      <p className="intro-text">
        The digital asset space is fast-growing but risky — without traditional safety nets. Aegis brings dynamic, trustless insurance tailored to NFTs and tokenized assets, powered by AI and decentralized oracles.
      </p>
      <div className="steps-container">
        {steps.map((step, index) => (
          <div key={index} className="step-card">
            <div className="step-number">{index + 1}</div>
            <h3 className="step-title">{step.title}</h3>
            <p className="step-description">{step.description}</p>
          </div>
        ))}
      </div>
    </section>
  );
}