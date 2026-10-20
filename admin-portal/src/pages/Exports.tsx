import React from 'react';
import { api } from '../api/client';
import { Download, FileSpreadsheet, Database, ShieldCheck } from 'lucide-react';

export const Exports: React.FC = () => {
  return (
    <div style={{ maxWidth: '800px' }}>
      <div className="page-header">
        <div className="page-title">
          <h2>డేటా ఎగుమతులు & బ్యాకప్ (Data Exports & Backups)</h2>
          <p>Export customer directories and full financial ledger records in CSV format</p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px', marginBottom: '32px' }}>
        {/* Customer Directory CSV */}
        <div className="metric-card" style={{ flexDirection: 'column', gap: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div className="metric-icon-box amber">
              <FileSpreadsheet size={24} />
            </div>
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#0f172a' }}>Customers Directory CSV</h4>
              <p style={{ fontSize: '12.5px', color: '#64748b' }}>Includes full names, aliases, phone numbers, notes, and balances</p>
            </div>
          </div>

          <a
            href={api.getExportCustomersUrl()}
            className="btn btn-primary"
            style={{ width: '100%' }}
            target="_blank"
            rel="noopener noreferrer"
          >
            <Download size={18} />
            <span>Download Customers CSV / డౌన్‌లోడ్</span>
          </a>
        </div>

        {/* Transaction Ledger CSV */}
        <div className="metric-card" style={{ flexDirection: 'column', gap: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div className="metric-icon-box emerald">
              <Database size={24} />
            </div>
            <div>
              <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#0f172a' }}>Transaction Ledger CSV</h4>
              <p style={{ fontSize: '12.5px', color: '#64748b' }}>Complete dated history of credits, payments, discounts, and reversals</p>
            </div>
          </div>

          <a
            href={api.getExportTransactionsUrl()}
            className="btn btn-primary"
            style={{ width: '100%', background: 'linear-gradient(135deg, #059669, #047857)' }}
            target="_blank"
            rel="noopener noreferrer"
          >
            <Download size={18} />
            <span>Download Transactions CSV / డౌన్‌లోడ్</span>
          </a>
        </div>
      </div>

      {/* Backup Instructions Box */}
      <div className="card-table" style={{ padding: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
          <ShieldCheck size={22} color="#059669" />
          <h3 style={{ fontSize: '16px', fontWeight: 700, color: '#0f172a' }}>
            MongoDB Database Backup & Restore Guide
          </h3>
        </div>

        <p style={{ fontSize: '13.5px', color: '#475569', lineHeight: 1.6, marginBottom: '16px' }}>
          To perform a cold binary backup of your entire cloud-hosted MongoDB Atlas database, run <code>mongodump</code>:
        </p>

        <pre style={{
          background: '#0f172a',
          color: '#38bdf8',
          padding: '14px 18px',
          borderRadius: '8px',
          fontSize: '13px',
          overflowX: 'auto',
          marginBottom: '16px'
        }}>
mongodump --uri="mongodb+srv://&lt;dbuser&gt;:&lt;password&gt;@cluster0.mongodb.net/tiffin_ledger_db" --out=./backup-$(date +%F)
        </pre>

        <p style={{ fontSize: '13.5px', color: '#475569', lineHeight: 1.6, marginBottom: '8px' }}>
          To restore the database:
        </p>

        <pre style={{
          background: '#0f172a',
          color: '#38bdf8',
          padding: '14px 18px',
          borderRadius: '8px',
          fontSize: '13px',
          overflowX: 'auto'
        }}>
mongorestore --uri="mongodb+srv://&lt;dbuser&gt;:&lt;password&gt;@cluster0.mongodb.net/tiffin_ledger_db" ./backup-2026-10-20/tiffin_ledger_db
        </pre>
      </div>
    </div>
  );
};
