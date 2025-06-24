import React from 'react';
import { Buffer } from "buffer";
window.Buffer = Buffer;
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import PoliciesPage from './pages/PoliciesPage';
// We no longer import Layout. Instead, we import Dashboard directly.
import Dashboard from './Dashboard.jsx'; 
import HowItWorks from './components/HowItWorks.jsx';
import ActivePolicies from './components/ActivePolicies.jsx';
import Layout from './Layout.jsx'; // Import the Layout component

import './index.css';

// ... imports
 // We will create this new page

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          <Route path="how-it-works" element={<HowItWorks />} />
          <Route path="policies" element={<PoliciesPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  </React.StrictMode>,
);