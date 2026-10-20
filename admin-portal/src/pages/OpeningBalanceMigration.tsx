import React, { useEffect, useState } from 'react';
import { api, Customer } from '../api/client';
import { BookOpen, CheckCircle, AlertCircle } from 'lucide-react';

export const OpeningBalanceMigration: React.FC = () => {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [selectedCustomerId, setSelectedCustomerId] = useState('');
  const [amountRupees, setAmountRupees] = useState('');
  const [notebookPage, setNotebookPage] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    loadCustomers();
  }, []);

  const loadCustomers = async () => {
    try {
      const data = await api.getCustomers(undefined, 'ACTIVE', 0, 100);
      setCustomers(data.content || []);
    } catch (err) {
      console.error(err);
    }
  };

  const handleMigration = async (e: React.FormEvent) => {
    e.preventDefault();
    setSuccessMsg(null);
    setErrorMsg(null);

    if (!selectedCustomerId) {
      setErrorMsg('Please select a customer.');
      return;
    }

    const amountPaise = Math.round(parseFloat(amountRupees) * 100);
    if (isNaN(amountPaise) || amountPaise < 0) {
      setErrorMsg('Please enter a valid non-negative amount.');
      return;
    }

    setLoading(true);
    try {
      const res = await api.importOpeningBalance(
        selectedCustomerId,
        amountPaise,
        notebookPage.trim() || undefined,
        notes.trim() || undefined
      );

      setSuccessMsg(res.teluguSpeechMessage || 'Opening balance imported successfully.');
      setAmountRupees('');
      setNotebookPage('');
      setNotes('');
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to import opening balance');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: '680px' }}>
      <div className="page-header">
        <div className="page-title">
          <h2>పుస్తకం బాకీల నమోదు (Notebook Balance Migration)</h2>
          <p>Safely transfer old debt records from your physical notebook into the digital ledger</p>
        </div>
      </div>

      <div className="card-table" style={{ padding: '28px' }}>
        {successMsg && (
          <div style={{ display: 'flex', gap: '10px', padding: '12px', background: '#ecfdf5', color: '#047857', borderRadius: '8px', marginBottom: '20px', border: '1px solid #d1fae5' }}>
            <CheckCircle size={20} />
            <span>{successMsg}</span>
          </div>
        )}

        {errorMsg && (
          <div style={{ display: 'flex', gap: '10px', padding: '12px', background: '#fff1f2', color: '#e11d48', borderRadius: '8px', marginBottom: '20px', border: '1px solid #ffe4e6' }}>
            <AlertCircle size={20} />
            <span>{errorMsg}</span>
          </div>
        )}

        <form onSubmit={handleMigration}>
          <div className="form-group">
            <label className="form-label">Select Customer / కస్టమర్‌ను ఎంచుకోండి *</label>
            <select
              className="form-control"
              value={selectedCustomerId}
              onChange={(e) => setSelectedCustomerId(e.target.value)}
              required
            >
              <option value="">-- Choose Customer / కస్టమర్ పేరు --</option>
              {customers.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name} {c.phoneNumber ? `(${c.phoneNumber})` : ''} - Current: ₹{c.balanceInRupees.toFixed(2)}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Notebook Debt Amount in Rupees (₹) *</label>
            <input
              type="number"
              step="0.01"
              className="form-control"
              placeholder="e.g. 250.00"
              value={amountRupees}
              onChange={(e) => setAmountRupees(e.target.value)}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Physical Notebook Page Number / పేజీ నంబర్</label>
            <input
              type="text"
              className="form-control"
              placeholder="e.g. Page 14 (ఎరుపు రంగు బుక్)"
              value={notebookPage}
              onChange={(e) => setNotebookPage(e.target.value)}
            />
          </div>

          <div className="form-group">
            <label className="form-label">Migration Notes / గమనికలు</label>
            <textarea
              className="form-control"
              rows={3}
              placeholder="Notes from notebook: e.g. Old credit migrated from September 2026 balance sheet"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </div>

          <button
            type="submit"
            className="btn btn-primary"
            disabled={loading}
            style={{ width: '100%', padding: '12px', marginTop: '12px' }}
          >
            {loading ? 'Importing... / నమోదు అవుతోంది...' : 'Import Opening Balance / బాకీ నమోదు చేయండి'}
          </button>
        </form>
      </div>
    </div>
  );
};
