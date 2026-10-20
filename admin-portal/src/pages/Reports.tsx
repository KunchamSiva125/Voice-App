import React, { useEffect, useState } from 'react';
import { api, DailyReport, OutstandingReport } from '../api/client';
import { Calendar, BarChart2, IndianRupee, ArrowDownLeft, ArrowUpRight, Tag } from 'lucide-react';

export const Reports: React.FC = () => {
  const [selectedDate, setSelectedDate] = useState(() => {
    const today = new Date();
    return today.toISOString().split('T')[0];
  });
  const [report, setReport] = useState<DailyReport | null>(null);
  const [outstanding, setOutstanding] = useState<OutstandingReport | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadReport();
  }, [selectedDate]);

  const loadReport = async () => {
    setLoading(true);
    try {
      const [rData, oData] = await Promise.all([
        api.getDailyReport(selectedDate),
        api.getOutstandingReport(15)
      ]);
      setReport(rData);
      setOutstanding(oData);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <div className="page-header">
        <div className="page-title">
          <h2>వ్యాపార నివేదికలు (Financial & Daily Reports)</h2>
          <p>Accounting reconciliation in Asia/Kolkata business date context</p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <label style={{ fontSize: '13px', fontWeight: 600, color: '#475569' }}>Business Date:</label>
          <input
            type="date"
            className="form-control"
            style={{ width: '170px' }}
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
          />
        </div>
      </div>

      {/* Metrics Row */}
      <div className="metrics-grid">
        <div className="metric-card">
          <div className="metric-info">
            <h5>Collections on Date</h5>
            <div className="metric-value" style={{ color: '#059669' }}>
              ₹{report?.totalPaymentsInRupees.toFixed(2) || '0.00'}
            </div>
            <div className="metric-sub">వసూలైన నగదు</div>
          </div>
          <div className="metric-icon-box emerald">
            <ArrowDownLeft size={24} />
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-info">
            <h5>New Credits on Date</h5>
            <div className="metric-value" style={{ color: '#e11d48' }}>
              ₹{report?.totalCreditsInRupees.toFixed(2) || '0.00'}
            </div>
            <div className="metric-sub">కొత్తగా ఇచ్చిన అప్పు</div>
          </div>
          <div className="metric-icon-box rose">
            <ArrowUpRight size={24} />
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-info">
            <h5>Discounts on Date</h5>
            <div className="metric-value" style={{ color: '#1d4ed8' }}>
              ₹{report?.totalDiscountsInRupees.toFixed(2) || '0.00'}
            </div>
            <div className="metric-sub">మినహాయింపులు (Waivers)</div>
          </div>
          <div className="metric-icon-box blue">
            <Tag size={24} />
          </div>
        </div>

        <div className="metric-card">
          <div className="metric-info">
            <h5>Net Debt Change</h5>
            <div className="metric-value">
              ₹{report?.netChangeInRupees.toFixed(2) || '0.00'}
            </div>
            <div className="metric-sub">నికర బాకీ మార్పు</div>
          </div>
          <div className="metric-icon-box amber">
            <BarChart2 size={24} />
          </div>
        </div>
      </div>

      {/* Top Debtors Table */}
      <div className="card-table">
        <div className="table-header">
          <h3>అత్యధిక బాకీ ఉన్న ఖాతాదారుల జాబితా (Outstanding Debt Aging Breakdown)</h3>
          <span style={{ fontSize: '13px', color: '#64748b' }}>
            Total Hotel Debt: <strong>₹{outstanding?.totalOutstandingDebtInRupees.toFixed(2)}</strong> across {outstanding?.totalDebtorsCount} customers
          </span>
        </div>

        <table>
          <thead>
            <tr>
              <th>Rank</th>
              <th>Customer Name</th>
              <th>Phone</th>
              <th>Outstanding Debt (INR)</th>
            </tr>
          </thead>
          <tbody>
            {outstanding?.topDebtors.map((debtor, idx) => (
              <tr key={debtor.customerId}>
                <td style={{ fontWeight: 700, color: '#64748b' }}>#{idx + 1}</td>
                <td style={{ fontWeight: 600 }}>{debtor.customerName}</td>
                <td style={{ color: '#64748b' }}>{debtor.phoneNumber || '-'}</td>
                <td style={{ fontWeight: 700, color: '#e11d48', fontSize: '15px' }}>
                  ₹{debtor.balanceInRupees.toFixed(2)}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
