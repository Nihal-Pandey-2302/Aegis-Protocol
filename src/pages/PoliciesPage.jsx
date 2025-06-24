import React from 'react';
import { useOutletContext } from 'react-router-dom';
import ActivePolicies from '../components/ActivePolicies';

function PoliciesPage() {
  const { activePolicies } = useOutletContext();

  return (
    <div className="main-content" style={{ padding: '2rem' }}>
      <h1>My Active Policies</h1>
      <ActivePolicies policies={activePolicies} />
    </div>
  );
}

export default PoliciesPage;
