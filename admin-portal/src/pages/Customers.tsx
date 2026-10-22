import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, Customer } from '../api/client';
import { Search, UserPlus, Phone, IndianRupee, Eye, Archive, BookOpen } from 'lucide-react';

export const Customers: React.FC = () => {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);

  // Form State
  const [name, setName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [aliases, setAliases] = useState('');
  const [notes, setNotes] = useState('');
  const [initialOpeningRupees, setInitialOpeningRupees] = useState('');
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    loadCustomers();
  }, [search]);

  const loadCustomers = async () => {
    setLoading(true);
    try {
      const data = await api.getCustomers(search, 'ACTIVE', 0, 50);
      setCustomers(data.content || []);
    } catch (err) {
      console.error('Failed to load customers', err);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateCustomer = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    try {
      const aliasList = aliases
        .split(',')
        .map((a) => a.trim())
        .filter((a) => a.length > 0);

      const openingPaise = initialOpeningRupees ? Math.round(parseFloat(initialOpeningRupees) * 100) : 0;

      await api.createCustomer({
        name,
        phoneNumber: phoneNumber.trim() || undefined,
        aliases: aliasList,
        notes: notes.trim() || undefined,
        initialOpeningBalancePaise: openingPaise,
      });

      setShowAddModal(false);
      setName('');
      setPhoneNumber('');
      setAliases('');
      setNotes('');
      setInitialOpeningRupees('');
      loadCustomers();
    } catch (err: any) {
      setFormError(err.response?.data?.message || 'Failed to create customer');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title">
          <h2>ఖాతాదారులు (Customer Directory)</h2>
          <p>Search, manage customer debt profiles, and add new customers</p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <Link to="/migration" className="btn btn-secondary">
            <BookOpen size={18} />
            <span>పుస్తకం పాత బాకీల నమోదు (Notebook Debts)</span>
          </Link>
          <button
            onClick={() => setShowAddModal(true)}
            className="btn btn-primary"
          >
            <UserPlus size={18} />
            <span>New Customer / కొత్త కస్టమర్</span>
          </button>
        </div>
      </div>

      {/* Search Bar */}
      <div style={{ marginBottom: '20px', maxWidth: '450px', position: 'relative' }}>
        <input
          type="text"
          className="form-control"
          style={{ paddingLeft: '40px' }}
          placeholder="Search by name, nickname, or phone number..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <Search size={18} style={{ position: 'absolute', left: '12px', top: '12px', color: '#94a3b8' }} />
      </div>

      {/* Customers Table */}
      <div className="card-table">
        <div className="table-header">
          <h3>Customer Accounts ({customers.length})</h3>
        </div>

        <table>
          <thead>
            <tr>
              <th>Customer Name / పేరు</th>
              <th>Aliases / మారుపేర్లు</th>
              <th>Phone / ఫోన్ నంబర్</th>
              <th>Outstanding Debt / మొత్తం బాకీ</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                  Loading customers...
                </td>
              </tr>
            ) : customers.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                  No customer matching "{search}" found.
                </td>
              </tr>
            ) : (
              customers.map((c) => (
                <tr key={c.id}>
                  <td style={{ fontWeight: 600 }}>
                    <Link to={`/customers/${c.id}`} style={{ color: '#0f172a' }}>
                      {c.name}
                    </Link>
                  </td>
                  <td style={{ fontSize: '12px', color: '#64748b' }}>
                    {c.aliases?.length ? c.aliases.join(', ') : '-'}
                  </td>
                  <td style={{ color: '#64748b' }}>
                    {c.phoneNumber || '-'}
                  </td>
                  <td style={{ fontWeight: 700, color: c.outstandingBalancePaise > 0 ? '#e11d48' : '#059669' }}>
                    ₹{c.balanceInRupees.toFixed(2)}
                  </td>
                  <td>
                    <span className="badge badge-active">{c.status}</span>
                  </td>
                  <td>
                    <div style={{ display: 'flex', gap: '6px' }}>
                      <Link to={`/customers/${c.id}`} className="btn btn-secondary btn-sm" title="View customer profile">
                        <Eye size={14} />
                        <span>Details</span>
                      </Link>
                      <Link
                        to={`/migration?customerId=${c.id}`}
                        className="btn btn-secondary btn-sm"
                        title="Add previous debt written in physical notebook"
                        style={{ borderColor: '#d97706', color: '#b45309', background: '#fffbeb' }}
                      >
                        <BookOpen size={14} />
                        <span>+ Book Debt</span>
                      </Link>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Add Customer Modal */}
      {showAddModal && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h4>Add New Customer / కొత్త ఖాతాదారుని నమోదు</h4>
              <button onClick={() => setShowAddModal(false)} style={{ color: '#94a3b8', fontSize: '18px' }}>
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateCustomer}>
              <div className="modal-body">
                {formError && (
                  <div style={{ padding: '10px', background: '#fff1f2', color: '#e11d48', borderRadius: '6px', marginBottom: '14px', fontSize: '13px' }}>
                    {formError}
                  </div>
                )}

                <div className="form-group">
                  <label className="form-label">Full Name / పూర్తి పేరు *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Ramesh (Auto Driver)"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Phone Number / ఫోన్ నంబర్ (Optional)</label>
                  <input
                    type="tel"
                    className="form-control"
                    placeholder="10-digit mobile number"
                    value={phoneNumber}
                    onChange={(e) => setPhoneNumber(e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Aliases / మారుపేర్లు (Comma separated)</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. రమేష్, Auto Ramesh"
                    value={aliases}
                    onChange={(e) => setAliases(e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Initial Debt from Notebook (₹ INR)</label>
                  <input
                    type="number"
                    step="0.01"
                    className="form-control"
                    placeholder="0.00"
                    value={initialOpeningRupees}
                    onChange={(e) => setInitialOpeningRupees(e.target.value)}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Notes / గమనికలు</label>
                  <textarea
                    className="form-control"
                    rows={2}
                    placeholder="Morning parcel regular, driver, teacher, etc."
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setShowAddModal(false)}
                >
                  Cancel / రద్దు
                </button>
                <button type="submit" className="btn btn-primary">
                  Save Customer / సేవ్ చేయండి
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
