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
    if (!token) {
      setLoading(false);
      return;
    }

    let isMounted = true;
    // Safety timer: Max 3 seconds for session verification to prevent hanging on cold start or CORS issues
    const safetyTimer = setTimeout(() => {
      if (isMounted) {
        console.warn('Session verification timeout: redirecting to login');
        localStorage.removeItem('tiffin_token');
        localStorage.removeItem('tiffin_user');
        setUser(null);
        setLoading(false);
      }
    }, 3000);

    api.getMe()
      .then((userData) => {
        if (isMounted) {
          setUser(userData);
          localStorage.setItem('tiffin_user', JSON.stringify(userData));
        }
      })
      .catch(() => {
        if (isMounted) {
          localStorage.removeItem('tiffin_token');
          localStorage.removeItem('tiffin_user');
          setUser(null);
        }
      })
      .finally(() => {
        clearTimeout(safetyTimer);
        if (isMounted) {
          setLoading(false);
        }
      });

    return () => {
      isMounted = false;
      clearTimeout(safetyTimer);
    };
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
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        minHeight: '100vh',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#0f172a',
        color: '#fff',
        gap: '16px'
      }}>
        <div style={{
          width: '40px',
          height: '40px',
          border: '3px solid rgba(255, 255, 255, 0.15)',
          borderTopColor: '#f59e0b',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite'
        }} />
        <div style={{ fontSize: '15px', color: '#cbd5e1', fontWeight: 500 }}>
          Verifying Session / సెషన్ ధృవీకరిస్తోంది...
        </div>
        <button
          onClick={() => {
            localStorage.removeItem('tiffin_token');
            localStorage.removeItem('tiffin_user');
            setUser(null);
            setLoading(false);
          }}
          style={{
            marginTop: '8px',
            padding: '8px 18px',
            background: '#1e293b',
            border: '1px solid #475569',
            color: '#fcd34d',
            borderRadius: '8px',
            cursor: 'pointer',
            fontSize: '13px',
            fontWeight: 600
          }}
        >
          లాగిన్ పేజీకి వెళ్లండి (Go to Login)
        </button>
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
