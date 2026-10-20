import React, { useEffect, useState } from 'react';
import { api, User, Role } from '../api/client';
import { UserPlus, UserCheck, UserX, Shield } from 'lucide-react';

export const UserManagement: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);

  // Form
  const [name, setName] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<Role>('FAMILY_MEMBER');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    setLoading(true);
    try {
      const data = await api.getUsers();
      setUsers(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);

    try {
      await api.createUser({ name, username, password, role });
      setShowAddModal(false);
      setName('');
      setUsername('');
      setPassword('');
      setRole('FAMILY_MEMBER');
      loadUsers();
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to create user');
    }
  };

  const handleToggleActive = async (user: User) => {
    try {
      await api.toggleUserStatus(user.id, !user.active);
      loadUsers();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Action failed');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title">
          <h2>కుటుంబ సభ్యుల నిర్వహణ (Authorized Family & Staff)</h2>
          <p>Role-Based Access Control (RBAC): OWNER, ADMIN, FAMILY_MEMBER</p>
        </div>

        <button className="btn btn-primary" onClick={() => setShowAddModal(true)}>
          <UserPlus size={18} />
          <span>Add User / కొత్త సభ్యుడు</span>
        </button>
      </div>

      <div className="card-table">
        <div className="table-header">
          <h3>Registered Users ({users.length})</h3>
        </div>

        <table>
          <thead>
            <tr>
              <th>Name / పేరు</th>
              <th>Username / లాగిన్ ఐడీ</th>
              <th>Role / పాత్ర</th>
              <th>Status</th>
              <th>Access Action</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                  Loading users...
                </td>
              </tr>
            ) : (
              users.map((u) => (
                <tr key={u.id}>
                  <td style={{ fontWeight: 600 }}>{u.name}</td>
                  <td style={{ color: '#475569' }}>{u.username}</td>
                  <td>
                    <span className="badge" style={{
                      background: u.role === 'OWNER' ? '#fef3c7' : u.role === 'ADMIN' ? '#e0f2fe' : '#f1f5f9',
                      color: u.role === 'OWNER' ? '#b45309' : u.role === 'ADMIN' ? '#0369a1' : '#475569',
                      fontWeight: 700
                    }}>
                      {u.role}
                    </span>
                  </td>
                  <td>
                    {u.active ? (
                      <span className="badge badge-active">ACTIVE</span>
                    ) : (
                      <span className="badge badge-archived">DISABLED</span>
                    )}
                  </td>
                  <td>
                    <button
                      className="btn btn-secondary btn-sm"
                      style={{ color: u.active ? '#e11d48' : '#059669' }}
                      onClick={() => handleToggleActive(u)}
                    >
                      {u.active ? <UserX size={14} /> : <UserCheck size={14} />}
                      <span>{u.active ? 'Deactivate' : 'Activate'}</span>
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Add User Modal */}
      {showAddModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h4>Add Authorized User / నూతన సభ్యుని చేర్చు</h4>
              <button onClick={() => setShowAddModal(false)} style={{ color: '#94a3b8', fontSize: '18px' }}>✕</button>
            </div>

            <form onSubmit={handleCreateUser}>
              <div className="modal-body">
                {errorMsg && (
                  <div style={{ padding: '10px', background: '#fff1f2', color: '#e11d48', borderRadius: '6px', marginBottom: '14px', fontSize: '13px' }}>
                    {errorMsg}
                  </div>
                )}

                <div className="form-group">
                  <label className="form-label">Full Name / పూర్తి పేరు *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Kalyan (Son / Cashier)"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Username / లాగిన్ యూజర్‌నేమ్ *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. kalyan@tiffin.local"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Password / పాస్‌వర్డ్ *</label>
                  <input
                    type="password"
                    className="form-control"
                    placeholder="Minimum 8 characters"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Role / హోదా *</label>
                  <select
                    className="form-control"
                    value={role}
                    onChange={(e) => setRole(e.target.value as Role)}
                  >
                    <option value="FAMILY_MEMBER">FAMILY_MEMBER (Search, Add Credit, Record Payment)</option>
                    <option value="ADMIN">ADMIN (Customer Management, Authorized Corrections)</option>
                    <option value="OWNER">OWNER (Full Business Access, Exports, User Management)</option>
                  </select>
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setShowAddModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Create User / సభ్యుని సృష్టించు
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
