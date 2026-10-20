import React, { useEffect, useState } from 'react';
import { api, LedgerTransaction } from '../api/client';
import { Download, Filter, Calendar } from 'lucide-react';

export const Transactions: React.FC = () => {
  const [transactions, setTransactions] = useState<LedgerTransaction[]>([]);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadTransactions();
  }, []);

  const loadTransactions = async () => {
    setLoading(true);
    try {
      const data = await api.getTransactionsByRange(
        startDate || undefined,
        endDate || undefined,
        0,
        50
      );
      setTransactions(data.content || []);
    } catch (err) {
      console.error('Failed to load transactions', err);
    } finally {
      setLoading(false);
    }
  };

  const handleFilter = (e: React.FormEvent) => {
    e.preventDefault();
    loadTransactions();
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title">
          <h2>లావాదేవీల చిట్టా (General Ledger Transactions)</h2>
          <p>Chronological financial entries across all hotel customers</p>
        </div>

        <a
          href={api.getExportTransactionsUrl(startDate, endDate)}
          className="btn btn-secondary"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Download size={18} />
          <span>Export CSV / డౌన్‌లోడ్</span>
        </a>
      </div>

      {/* Date Filter Card */}
      <form onSubmit={handleFilter} className="card-table" style={{ padding: '16px 20px', marginBottom: '20px' }}>
        <div style={{ display: 'flex', gap: '16px', alignItems: 'center', flexWrap: 'wrap' }}>
          <div>
            <label style={{ fontSize: '12px', fontWeight: 600, color: '#64748b', display: 'block', marginBottom: '4px' }}>
              Start Date / ప్రారంభ తేదీ:
            </label>
            <input
              type="date"
              className="form-control"
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              style={{ width: '180px' }}
            />
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: 600, color: '#64748b', display: 'block', marginBottom: '4px' }}>
              End Date / ముగింపు తేదీ:
            </label>
            <input
              type="date"
              className="form-control"
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              style={{ width: '180px' }}
            />
          </div>

          <div style={{ alignSelf: 'flex-end' }}>
            <button type="submit" className="btn btn-primary" style={{ padding: '10px 18px' }}>
              <Filter size={16} />
              <span>Filter / ఫిల్టర్</span>
            </button>
          </div>
        </div>
      </form>

      {/* Transactions Table */}
      <div className="card-table">
        <div className="table-header">
          <h3>Posted Ledger Entries ({transactions.length})</h3>
        </div>

        <table>
          <thead>
            <tr>
              <th>Date & Time (IST)</th>
              <th>Customer</th>
              <th>Type</th>
              <th>Amount</th>
              <th>Balance Effect</th>
              <th>Recorded By</th>
              <th>Description / Reason</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                  Loading transactions...
                </td>
              </tr>
            ) : transactions.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                  No transactions found for the selected dates.
                </td>
              </tr>
            ) : (
              transactions.map((tx) => (
                <tr key={tx.id} style={{ opacity: tx.hasReversal ? 0.6 : 1 }}>
                  <td style={{ fontSize: '13px' }}>
                    {new Date(tx.effectiveAt).toLocaleString('en-IN', {
                      day: '2-digit', month: 'short', year: 'numeric',
                      hour: '2-digit', minute: '2-digit'
                    })}
                  </td>
                  <td style={{ fontWeight: 600 }}>{tx.customerName}</td>
                  <td>
                    <span className={`badge badge-${tx.type.toLowerCase()}`}>
                      {tx.type}
                    </span>
                  </td>
                  <td style={{ fontWeight: 700 }}>
                    ₹{tx.amountInRupees.toFixed(2)}
                  </td>
                  <td style={{
                    fontWeight: 700,
                    color: tx.balanceEffectPaise > 0 ? '#e11d48' : '#059669'
                  }}>
                    {tx.balanceEffectPaise > 0 ? '+' : ''}₹{(tx.balanceEffectPaise / 100).toFixed(2)}
                  </td>
                  <td style={{ fontSize: '12px', color: '#64748b' }}>{tx.createdBy}</td>
                  <td style={{ fontSize: '13px', color: '#475569' }}>
                    {tx.description || '-'}
                    {tx.correctionReason && <div style={{ fontSize: '11px', color: '#e11d48' }}>Reason: {tx.correctionReason}</div>}
                    {tx.reversesTransactionId && <div style={{ fontSize: '11px', color: '#a21caf' }}>Reverses Tx: {tx.reversesTransactionId}</div>}
                  </td>
                  <td>
                    {tx.hasReversal ? (
                      <span className="badge badge-reversal">REVERSED</span>
                    ) : (
                      <span className="badge badge-active">POSTED</span>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
