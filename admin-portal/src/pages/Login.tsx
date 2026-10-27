import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api, User } from '../api/client';
import { UtensilsCrossed, Lock, User as UserIcon, AlertCircle } from 'lucide-react';

interface LoginProps {
  onLoginSuccess: (user: User, token: string) => void;
}

export const Login: React.FC<LoginProps> = ({ onLoginSuccess }) => {
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const data = await api.login(username.trim(), password);
      
      // Strict role enforcement: Only ADMIN can use the admin portal
      if (data.user.role !== 'ADMIN') {
        setError('Access Denied: Only Admin (Siva) can access the Admin Web Portal. Owners please log into the Mobile Application.');
        return;
      }

      localStorage.setItem('tiffin_token', data.accessToken);
      localStorage.setItem('tiffin_user', JSON.stringify(data.user));
      onLoginSuccess(data.user, data.accessToken);
      navigate('/dashboard');
    } catch (err: any) {
      setError(err.response?.data?.message || err.message || 'Login failed. Please verify credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 100%)',
      padding: '20px'
    }}>
      <div style={{
        background: '#ffffff',
        borderRadius: '16px',
        maxWidth: '440px',
        width: '100%',
        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.3)',
        overflow: 'hidden'
      }}>
        <div style={{
          background: 'linear-gradient(135deg, #0f172a, #1e293b)',
          padding: '34px 28px 28px',
          color: '#ffffff',
          textAlign: 'center',
          borderBottom: '3px solid #f59e0b'
        }}>
          <div style={{
            display: 'inline-block',
            marginBottom: '14px'
          }}>
            <img
              src="/logo.png"
              alt="Mahima Tiffin Centre Logo"
              style={{
                width: '88px',
                height: '88px',
                borderRadius: '50%',
                objectFit: 'cover',
                boxShadow: '0 4px 18px rgba(245, 158, 11, 0.4)',
                border: '3px solid #f59e0b'
              }}
            />
          </div>
          <h2 style={{ fontSize: '24px', fontWeight: 900, color: '#fcd34d', letterSpacing: '0.2px', margin: 0 }}>
            Mahima Tiffin Centre
          </h2>
          <p style={{ fontSize: '15px', fontWeight: 600, color: '#ffffff', marginTop: '4px', marginBottom: 0 }}>
            మహిమ టిఫిన్ సెంటర్
          </p>
          <p style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px', marginBottom: 0 }}>
            Admin & Ledger Management Portal
          </p>
        </div>

        <div style={{ padding: '32px 28px' }}>
          {error && (
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              padding: '12px',
              background: '#fff1f2',
              color: '#e11d48',
              borderRadius: '8px',
              fontSize: '13.5px',
              marginBottom: '20px',
              border: '1px solid #ffe4e6'
            }}>
              <AlertCircle size={18} />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label">Username / యూజర్‌నేమ్</label>
              <div style={{ position: 'relative' }}>
                <input
                  type="text"
                  className="form-control"
                  style={{ paddingLeft: '40px' }}
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="e.g. owner@tiffin.local"
                  required
                />
                <UserIcon size={18} style={{ position: 'absolute', left: '12px', top: '12px', color: '#94a3b8' }} />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Password / పాస్‌వర్డ్</label>
              <div style={{ position: 'relative' }}>
                <input
                  type="password"
                  className="form-control"
                  style={{ paddingLeft: '40px' }}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  required
                />
                <Lock size={18} style={{ position: 'absolute', left: '12px', top: '12px', color: '#94a3b8' }} />
              </div>
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              disabled={loading}
              style={{ width: '100%', padding: '12px', marginTop: '8px' }}
            >
              {loading ? 'Logging in... / ప్రవేశిస్తోంది...' : 'Log In / లాగిన్ అవ్వండి'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};
