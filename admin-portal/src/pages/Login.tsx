import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api, User } from '../api/client';
import { UtensilsCrossed, Lock, User as UserIcon, AlertCircle } from 'lucide-react';

interface LoginProps {
  onLoginSuccess: (user: User, token: string) => void;
}

export const Login: React.FC<LoginProps> = ({ onLoginSuccess }) => {
  const navigate = useNavigate();
  const [username, setUsername] = useState('owner@tiffin.local');
  const [password, setPassword] = useState('Password123!');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const data = await api.login(username, password);
      localStorage.setItem('tiffin_token', data.accessToken);
      localStorage.setItem('tiffin_user', JSON.stringify(data.user));
      onLoginSuccess(data.user, data.accessToken);
      navigate('/dashboard');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Login failed. Please verify credentials.');
    } finally {
      setLoading(false);
    }
  };

  const fillCredentials = (user: string, pass: string) => {
    setUsername(user);
    setPassword(pass);
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
          background: 'linear-gradient(135deg, #f59e0b, #d97706)',
          padding: '32px 28px',
          color: '#ffffff',
          textAlign: 'center'
        }}>
          <div style={{
            display: 'inline-flex',
            padding: '12px',
            background: 'rgba(255, 255, 255, 0.2)',
            borderRadius: '12px',
            marginBottom: '12px'
          }}>
            <UtensilsCrossed size={32} />
          </div>
          <h2 style={{ fontSize: '22px', fontWeight: 700 }}>తెలుగు టిఫిన్ ఖాటా</h2>
          <p style={{ fontSize: '13px', opacity: 0.9, marginTop: '4px' }}>
            Tiffin Hotel Debt Management & Ledger
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

          {/* Quick Credential Helper for Demo */}
          <div style={{ marginTop: '24px', paddingTop: '20px', borderTop: '1px solid #e2e8f0' }}>
            <p style={{ fontSize: '12px', fontWeight: 600, color: '#64748b', marginBottom: '8px', textAlign: 'center' }}>
              Quick Fill Demo Accounts:
            </p>
            <div style={{ display: 'flex', gap: '8px', justifyContent: 'center' }}>
              <button
                type="button"
                className="btn btn-secondary btn-sm"
                onClick={() => fillCredentials('owner@tiffin.local', 'Password123!')}
              >
                Owner
              </button>
              <button
                type="button"
                className="btn btn-secondary btn-sm"
                onClick={() => fillCredentials('admin@tiffin.local', 'Password123!')}
              >
                Admin
              </button>
              <button
                type="button"
                className="btn btn-secondary btn-sm"
                onClick={() => fillCredentials('kalyan@tiffin.local', 'Password123!')}
              >
                Family Member
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
