import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api, DailyReport, OutstandingReport, LedgerTransaction } from '../api/client';
import {
  Users,
  IndianRupee,
  ArrowDownLeft,
  ArrowUpRight,
  TrendingUp,
  Clock,
  ChevronRight,
  Volume2
} from 'lucide-react';

export const Dashboard: React.FC = () => {
  const [daily, setDaily] = useState<DailyReport | null>(null);
  const [outstanding, setOutstanding] = useState<OutstandingReport | null>(null);
  const [recentTxs, setRecentTxs] = useState<LedgerTransaction[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    setLoading(true);
    try {
      const [dailyData, outData, txPage] = await Promise.all([
        api.getDailyReport(),
        api.getOutstandingReport(5),
        api.getTransactionsByRange(undefined, undefined, 0, 8),
      ]);
      setDaily(dailyData);
      setOutstanding(outData);
      setRecentTxs(txPage.content || []);
    } catch (err) {
      console.error('Error fetching dashboard data', err);
    } finally {
      setLoading(false);
    }
  };

  const speakTelugu = (text: string) => {
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'te-IN';
      window.speechSynthesis.speak(utterance);
    }
  };

  if (loading) {
    return <div style={{ padding: '40px', textAlign: 'center', color: '#64748b' }}>Loading Hotel Ledger Data...</div>;
  }

  return (
    <div>
      <div className="page-header" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <img
            src="/logo.png"
            alt="Mahima Tiffin Centre Logo"
            style={{
              width: '50px',
              height: '50px',
              borderRadius: '50%',
              objectFit: 'cover',
              border: '2px solid #f59e0b',
              boxShadow: '0 2px 8px rgba(245, 158, 11, 0.3)',
              flexShrink: 0
            }}
          />
          <div>
            <h2 style={{ margin: 0, fontSize: '20px', fontWeight: 800, color: '#0f172a' }}>
              Mahima Tiffin Centre • మహిమ టిఫిన్ సెంటర్
            </h2>
            <p style={{ margin: '2px 0 0 0', fontSize: '13px', color: '#64748b' }}>
              హోటల్ లెక్కల వివరాలు (Real-time Debt Ledger & Daily Financials)
            </p>
          </div>
        </div>

        {daily?.teluguSummary && (
          <button
            onClick={() => speakTelugu(daily.teluguSummary)}
            className="btn btn-secondary"
            style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
          >
            <Volume2 size={18} color="#d97706" />
            <span>ఈ రోజు లెక్క వినండి (Speak Summary)</span>
          </button>
        )}
      </div>

      {/* Metrics Row */}
      <div className="metrics-grid">
        <div className="metric-card">
          <div className="metric-info">
            <h5>Total Outstanding Debt</h5>
            <div className="metric-value" style={{ color: '#e11d48' }}>
              ₹{daily?.totalOutstandingDebtInRupees.toLocaleString('en-IN', { minimumFractionDigits: 2 }) || '0.00'}
            </div>
            <div className="metric-sub">మొత్తం రావలసిన బాకీలు</div>
          </div>
          <div className="metric-icon-box rose">
            <IndianRupee size={24} />
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-info">
            <h5>Collections Today</h5>
            <div className="metric-value" style={{ color: '#059669' }}>
              ₹{daily?.totalPaymentsInRupees.toLocaleString('en-IN', { minimumFractionDigits: 2 }) || '0.00'}
            </div>
            <div className="metric-sub">ఈ రోజు వసూలైన మొత్తం</div>
          </div>
          <div className="metric-icon-box emerald">
            <ArrowDownLeft size={24} />
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-info">
            <h5>Credits Given Today</h5>
            <div className="metric-value" style={{ color: '#d97706' }}>
              ₹{daily?.totalCreditsInRupees.toLocaleString('en-IN', { minimumFractionDigits: 2 }) || '0.00'}
            </div>
            <div className="metric-sub">ఈ రోజు ఇచ్చిన అప్పు</div>
          </div>
          <div className="metric-icon-box amber">
            <ArrowUpRight size={24} />
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-info">
            <h5>Active Customers</h5>
            <div className="metric-value">
              {daily?.activeCustomersCount || 0}
            </div>
            <div className="metric-sub">ఖాతాదారులు సంఖ్య</div>
          </div>
          <div className="metric-icon-box blue">
            <Users size={24} />
          </div>
        </div>
      </div>

      {/* Grid: Recent Transactions & Top Debtors */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '24px' }}>
        {/* Recent Transactions */}
        <div className="card-table">
          <div className="table-header">
            <h3>ఇటీవలి లావాదేవీలు (Recent Transactions)</h3>
            <Link to="/transactions" style={{ fontSize: '13px', color: '#d97706', fontWeight: 600 }}>
              View All &rarr;
            </Link>
          </div>

          <table>
            <thead>
              <tr>
                <th>Customer / కస్టమర్</th>
                <th>Type / రకం</th>
                <th>Amount / మొత్తం</th>
                <th>Time / సమయం</th>
              </tr>
            </thead>
            <tbody>
              {recentTxs.length === 0 ? (
                <tr>
                  <td colSpan={4} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                    No transactions recorded today yet.
                  </td>
                </tr>
              ) : (
                recentTxs.map((tx) => (
                  <tr key={tx.id}>
                    <td style={{ fontWeight: 600 }}>
                      <Link to={`/customers/${tx.customerId}`} style={{ color: '#0f172a' }}>
                        {tx.customerName}
                      </Link>
                    </td>
                    <td>
                      <span className={`badge badge-${tx.type.toLowerCase()}`}>
                        {tx.type}
                      </span>
                    </td>
                    <td style={{
                      fontWeight: 700,
                      color: tx.balanceEffectPaise > 0 ? '#e11d48' : '#059669'
                    }}>
                      {tx.balanceEffectPaise > 0 ? '+' : '-'}₹{tx.amountInRupees.toFixed(2)}
                    </td>
                    <td style={{ fontSize: '12px', color: '#64748b' }}>
                      {new Date(tx.effectiveAt).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' })}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Top Debtors */}
        <div className="card-table">
          <div className="table-header">
            <h3>ఎక్కువ బాకీ ఉన్నవారు (Top Debtors)</h3>
            <Link to="/customers" style={{ fontSize: '13px', color: '#d97706', fontWeight: 600 }}>
              All Customers &rarr;
            </Link>
          </div>

          <table>
            <thead>
              <tr>
                <th>Customer Name</th>
                <th>Phone</th>
                <th>Outstanding Debt</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {outstanding?.topDebtors.map((debtor) => (
                <tr key={debtor.customerId}>
                  <td style={{ fontWeight: 600 }}>{debtor.customerName}</td>
                  <td style={{ color: '#64748b' }}>{debtor.phoneNumber || '-'}</td>
                  <td style={{ fontWeight: 700, color: '#e11d48' }}>
                    ₹{debtor.balanceInRupees.toFixed(2)}
                  </td>
                  <td>
                    <Link
                      to={`/customers/${debtor.customerId}`}
                      className="btn btn-secondary btn-sm"
                      style={{ padding: '4px 8px' }}
                    >
                      View
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
