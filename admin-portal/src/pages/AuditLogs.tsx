import React, { useEffect, useState } from 'react';
import { api, AuditEvent } from '../api/client';
import { ShieldAlert, Clock, User, FileText } from 'lucide-react';

export const AuditLogs: React.FC = () => {
  const [logs, setLogs] = useState<AuditEvent[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAuditLogs();
  }, []);

  const loadAuditLogs = async () => {
    setLoading(true);
    try {
      const data = await api.getAuditEvents(0, 50);
      setLogs(data.content || []);
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
          <h2>ఆడిట్ లాగ్ (Immutable System Audit Trail)</h2>
          <p>Chronological record of sensitive actions, user logins, corrections, and customer updates</p>
        </div>
      </div>

      <div className="card-table">
        <div className="table-header">
          <h3>Logged System Events ({logs.length})</h3>
        </div>

        <table>
          <thead>
            <tr>
              <th>Timestamp (IST)</th>
              <th>Actor / యూజర్</th>
              <th>Action / చర్య</th>
              <th>Entity</th>
              <th>Reason / వివరణ</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                  Loading audit logs...
                </td>
              </tr>
            ) : logs.length === 0 ? (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                  No audit logs recorded yet.
                </td>
              </tr>
            ) : (
              logs.map((log) => (
                <tr key={log.id}>
                  <td style={{ fontSize: '13px' }}>
                    {new Date(log.occurredAt).toLocaleString('en-IN', {
                      day: '2-digit', month: 'short', year: 'numeric',
                      hour: '2-digit', minute: '2-digit', second: '2-digit'
                    })}
                  </td>
                  <td style={{ fontWeight: 600 }}>{log.actorUsername}</td>
                  <td>
                    <span className="badge badge-reversal">{log.action}</span>
                  </td>
                  <td style={{ fontSize: '13px', color: '#64748b' }}>
                    {log.entityType}/{log.entityId}
                  </td>
                  <td style={{ fontSize: '13px', color: '#334155' }}>
                    {log.reason}
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
