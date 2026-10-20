import React, { useEffect, useState } from 'react';
import { api, LedgerTransaction } from '../api/client';
import { RotateCcw, AlertTriangle, ShieldCheck } from 'lucide-react';

export const Corrections: React.FC = () => {
  const [transactions, setTransactions] = useState<LedgerTransaction[]>([]);
  const [selectedTx, setSelectedTx] = useState<LedgerTransaction | null>(null);
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    loadTransactions();
  }, []);

  const loadTransactions = async () => {
    setLoading(true);
    try {
      const data = await api.getTransactionsByRange(undefined, undefined, 0, 50);
      setTransactions(data.content || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleReversal = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedTx) return;
    setErrorMsg(null);

    if (!reason.trim()) {
      setErrorMsg('A detailed audit justification is strictly required to reverse a financial entry.');
      return;
    }

    try {
      await api.reverseTransaction(selectedTx.id, reason.trim());
      setSelectedTx(null);
      setReason('');
      loadTransactions();
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to reverse transaction');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title">
          <h2>తప్పులు సరిదిద్దుట (Transaction Corrections & Reversals)</h2>
          <p>Strict double-entry reversal policy: Compensatory cancellation without deleting audit history</p>
        </div>
      </div>

      <div style={{
        background: '#eff6ff',
        border: '1px solid #bfdbfe',
        borderRadius: '12px',
        padding: '16px 20px',
        marginBottom: '24px',
        display: 'flex',
        alignItems: 'flex-start',
        gap: '12px'
      }}>
        <ShieldCheck size={22} color="#1d4ed8" style={{ marginTop: '2px', flexShrink: 0 }} />
        <div style={{ fontSize: '13.5px', color: '#1e3a8a' }}>
          <strong>Financial Invariant Policy:</strong> Reversals insert an explicit compensatory ledger entry
          (<code>balanceEffectPaise = -1 * original</code>) and link back to the original entry.
          Neither record is ever destroyed, ensuring perfect compliance with accounting integrity and owner audit requirements.
        </div>
      </div>

      <div className="card-table">
        <div className="table-header">
          <h3>Recent Active Ledger Entries</h3>
        </div>

        <table>
          <thead>
            <tr>
              <th>Date (IST)</th>
              <th>Customer</th>
              <th>Type</th>
              <th>Amount</th>
              <th>Balance Effect</th>
              <th>Created By</th>
              <th>Status</th>
              <th>Correction Action</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                  Loading transactions...
                </td>
              </tr>
            ) : (
              transactions.map((tx) => (
                <tr key={tx.id} style={{ opacity: tx.hasReversal ? 0.5 : 1 }}>
                  <td>{new Date(tx.effectiveAt).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}</td>
                  <td style={{ fontWeight: 600 }}>{tx.customerName}</td>
                  <td>
                    <span className={`badge badge-${tx.type.toLowerCase()}`}>{tx.type}</span>
                  </td>
                  <td style={{ fontWeight: 700 }}>₹{tx.amountInRupees.toFixed(2)}</td>
                  <td style={{ color: tx.balanceEffectPaise > 0 ? '#e11d48' : '#059669', fontWeight: 600 }}>
                    {tx.balanceEffectPaise > 0 ? '+' : ''}₹{(tx.balanceEffectPaise / 100).toFixed(2)}
                  </td>
                  <td style={{ fontSize: '12px', color: '#64748b' }}>{tx.createdBy}</td>
                  <td>
                    {tx.hasReversal ? (
                      <span className="badge badge-reversal">REVERSED</span>
                    ) : (
                      <span className="badge badge-active">POSTED</span>
                    )}
                  </td>
                  <td>
                    {!tx.hasReversal && tx.type !== 'REVERSAL' ? (
                      <button
                        className="btn btn-secondary btn-sm"
                        style={{ color: '#e11d48', borderColor: '#fecdd3' }}
                        onClick={() => setSelectedTx(tx)}
                      >
                        <RotateCcw size={14} />
                        <span>Reverse Entry</span>
                      </button>
                    ) : (
                      <span style={{ fontSize: '12px', color: '#94a3b8' }}>Already corrected</span>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Reversal Confirmation Modal */}
      {selectedTx && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h4 style={{ color: '#e11d48' }}>Confirm Reversal / రద్దు ఖరారు</h4>
              <button onClick={() => setSelectedTx(null)} style={{ color: '#94a3b8', fontSize: '18px' }}>✕</button>
            </div>

            <form onSubmit={handleReversal}>
              <div className="modal-body">
                <p style={{ fontSize: '13.5px', color: '#334155', marginBottom: '14px' }}>
                  You are reversing transaction <strong>{selectedTx.id}</strong> for customer <strong>{selectedTx.customerName}</strong>.
                  Nominal amount: <strong>₹{selectedTx.amountInRupees.toFixed(2)}</strong>.
                </p>

                {errorMsg && (
                  <div style={{ padding: '10px', background: '#fff1f2', color: '#e11d48', borderRadius: '6px', marginBottom: '14px', fontSize: '13px' }}>
                    {errorMsg}
                  </div>
                )}

                <div className="form-group">
                  <label className="form-label">Audit Reason for Mistake / తప్పుకు కారణం *</label>
                  <textarea
                    className="form-control"
                    rows={3}
                    placeholder="e.g. Cashier mistakenly recorded 2 Idli credit to wrong customer"
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setSelectedTx(null)}>
                  Cancel / రద్దు
                </button>
                <button type="submit" className="btn btn-danger">
                  Post Reversal / సరిదిద్దండి
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
