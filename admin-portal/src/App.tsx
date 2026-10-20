import React, { useState, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { User, api } from './api/client';
import { Sidebar } from './components/Sidebar';
import { ProtectedRoute } from './components/ProtectedRoute';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { Customers } from './pages/Customers';
import { CustomerDetail } from './pages/CustomerDetail';
import { Transactions } from './pages/Transactions';
import { Corrections } from './pages/Corrections';
import { OpeningBalanceMigration } from './pages/OpeningBalanceMigration';
import { Reports } from './pages/Reports';
import { UserManagement } from './pages/UserManagement';
import { AuditLogs } from './pages/AuditLogs';
import { Exports } from './pages/Exports';

export const App: React.FC = () => {
  const [user, setUser] = useState<User | null>(() => {
    const saved = localStorage.getItem('tiffin_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = localStorage.getItem('tiffin_token');
    if (token) {
      api.getMe()
        .then((userData) => {
          setUser(userData);
          localStorage.setItem('tiffin_user', JSON.stringify(userData));
        })
        .catch(() => {
          localStorage.removeItem('tiffin_token');
          localStorage.removeItem('tiffin_user');
          setUser(null);
        })
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, []);

  const handleLoginSuccess = (loggedInUser: User, token: string) => {
    setUser(loggedInUser);
  };

  const handleLogout = () => {
    localStorage.removeItem('tiffin_token');
    localStorage.removeItem('tiffin_user');
    setUser(null);
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', background: '#0f172a', color: '#fff' }}>
        Verifying Session / సెషన్ ధృవీకరిస్తోంది...
      </div>
    );
  }

  return (
    <BrowserRouter>
      {user ? (
        <div className="app-container">
          <Sidebar user={user} onLogout={handleLogout} />
          <main className="main-content">
            <Routes>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/customers" element={<Customers />} />
              <Route path="/customers/:id" element={<CustomerDetail />} />
              <Route path="/transactions" element={<Transactions />} />

              {/* Admin & Owner Protected Routes */}
              <Route element={<ProtectedRoute user={user} allowedRoles={['OWNER', 'ADMIN']} />}>
                <Route path="/corrections" element={<Corrections />} />
                <Route path="/reports" element={<Reports />} />
              </Route>

              {/* Owner Only Protected Routes */}
              <Route element={<ProtectedRoute user={user} allowedRoles={['OWNER']} />}>
                <Route path="/migration" element={<OpeningBalanceMigration />} />
                <Route path="/users" element={<UserManagement />} />
                <Route path="/audit" element={<AuditLogs />} />
                <Route path="/exports" element={<Exports />} />
              </Route>

              <Route path="*" element={<Navigate to="/dashboard" replace />} />
            </Routes>
          </main>
        </div>
      ) : (
        <Routes>
          <Route path="/login" element={<Login onLoginSuccess={handleLoginSuccess} />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      )}
    </BrowserRouter>
  );
};

export default App;
