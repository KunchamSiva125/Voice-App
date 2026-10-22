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
                <Route path="/migration" element={<OpeningBalanceMigration />} />
                <Route path="/users" element={<UserManagement />} />
                <Route path="/audit" element={<AuditLogs />} />
                <Route path="/exports" element={<Exports />} />
              </Route>

              <Route path="*" element={<Navigate to="/dashboard" replace />} />
            </Routes>
          </main>
        </div>
        <Routes>
          <Route
            path="*"
            element={
              <div style={{ minHeight: '100vh', background: '#0f172a', color: '#f8fafc', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', fontFamily: 'sans-serif', padding: 24, textAlign: 'center' }}>
                <div style={{ background: '#1e293b', border: '1px solid #334155', borderRadius: 20, padding: '36px 30px', maxWidth: 460 }}>
                  <div style={{ fontSize: 44, marginBottom: 12 }}>📱✨</div>
                  <h2 style={{ color: '#f59e0b', margin: '0 0 8px 0' }}>మహిమ టిఫిన్ సెంటర్</h2>
                  <h3 style={{ color: '#fcd34d', margin: '0 0 16px 0' }}>100% Flutter Mobile Admin Portal</h3>
                  <p style={{ color: '#94a3b8', fontSize: 14, lineHeight: 1.6, marginBottom: 24 }}>
                    అడ్మిన్ పోర్టల్ ఇప్పుడు పూర్తిగా <strong>Flutter Mobile App</strong> గా మార్చబడింది.
                  </p>
                  <a
                    href="http://localhost:5173"
                    style={{ display: 'inline-block', background: 'linear-gradient(135deg, #d97706, #f59e0b)', color: '#fff', textDecoration: 'none', fontWeight: 'bold', padding: '14px 28px', borderRadius: 12, boxShadow: '0 4px 12px rgba(217, 119, 6, 0.4)' }}
                  >
                    🚀 Open Flutter Admin Portal (http://localhost:5173)
                  </a>
                </div>
              </div>
            }
          />
        </Routes>
      )}
    </BrowserRouter>
  );
};

export default App;
