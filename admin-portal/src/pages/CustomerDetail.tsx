import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import { api, Customer, CustomerBalance, LedgerTransaction } from '../api/client';
import {
  ArrowLeft,
  Volume2,
  PlusCircle,
  MinusCircle,
  Tag,
  RotateCcw,
  Clock,
  UserCheck,
  AlertTriangle,
  Receipt,
  Trash2
} from 'lucide-react';

export const CustomerDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [customer, setCustomer] = useState<Customer | null>(null);
  const [balance, setBalance] = useState<CustomerBalance | null>(null);
  const [transactions, setTransactions] = useState<LedgerTransaction[]>([]);
  const [loading, setLoading] = useState(true);

  // Modals
  const [actionType, setActionType] = useState<'CREDIT' | 'PAYMENT' | 'DISCOUNT' | null>(null);
  const [reversalTx, setReversalTx] = useState<LedgerTransaction | null>(null);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  // Form State
  const [amountRupees, setAmountRupees] = useState('');
  const [description, setDescription] = useState('');
  const [reason, setReason] = useState('');
  const [allowAdvance, setAllowAdvance] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [excessWarning, setExcessWarning] = useState<any | null>(null);

  useEffect(() => {
    if (id) {
      loadData(id);
    }
  }, [id]);

  const loadData = async (customerId: string) => {
    setLoading(true);
    try {
      const [custData, balData, txData] = await Promise.all([
        api.getCustomer(customerId),
        api.getCustomerBalance(customerId),
        api.getCustomerTransactions(customerId, 0, 50),
      ]);
      setCustomer(custData);
      setBalance(balData);
      setTransactions(txData.content || []);
    } catch (err) {
      console.error('Failed to load customer details', err);
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

  const handleTransactionSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!customer) return;
    setErrorMsg(null);
    setExcessWarning(null);

    const amountPaise = Math.round(parseFloat(amountRupees) * 100);
    if (isNaN(amountPaise) || amountPaise <= 0) {
      setErrorMsg('Please enter a valid positive amount.');
      return;
    }

    try {
      if (actionType === 'CREDIT') {
        await api.recordCredit(customer.id, amountPaise, description);
      } else if (actionType === 'PAYMENT') {
        await api.recordPayment(customer.id, amountPaise, allowAdvance, description);
      } else if (actionType === 'DISCOUNT') {
        if (!reason.trim()) {
          setErrorMsg('Reason for discount or waiver is required.');
          return;
        }
        await api.applyDiscount(customer.id, amountPaise, reason);
      }

      closeModal();
      loadData(customer.id);
    } catch (err: any) {
      if (err.response?.data?.error === 'EXCESS_PAYMENT_CONFIRMATION_REQUIRED') {
        setExcessWarning(err.response.data);
      } else {
        setErrorMsg(err.response?.data?.message || 'Transaction submission failed');
      }
    }
  };

  const handleReversalSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reversalTx || !customer) return;
    setErrorMsg(null);

    if (!reason.trim()) {
      setErrorMsg('Strict audit reason is required for reversal.');
      return;
    }

    try {
      await api.reverseTransaction(reversalTx.id, reason);
      setReversalTx(null);
      setReason('');
      loadData(customer.id);
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to reverse transaction');
    }
  };

  const handleDeleteCustomer = async () => {
    if (!customer) return;
    setIsDeleting(true);
    setErrorMsg(null);
    try {
      await api.deleteCustomer(customer.id);
      setShowDeleteModal(false);
      navigate('/customers');
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to remove customer');
      setIsDeleting(false);
    }
  };

  const closeModal = () => {
    setActionType(null);
    setAmountRupees('');
    setDescription('');
    setReason('');
    setAllowAdvance(false);
    setErrorMsg(null);
    setExcessWarning(null);
  };

  if (loading || !customer) {
    return <div style={{ padding: '40px', textAlign: 'center', color: '#64748b' }}>Loading customer profile...</div>;
  }

  return (
    <div>
      <div style={{ marginBottom: '16px' }}>
        <Link to="/customers" style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: '#64748b' }}>
          <ArrowLeft size={16} />
          <span>Back to Customers / వెనుకకు</span>
        </Link>
      </div>

      {/* Customer Header Card */}
      <div style={{
        background: '#ffffff',
        border: '1px solid #e2e8f0',
        borderRadius: '14px',
        padding: '24px',
        boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
        marginBottom: '24px',
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        flexWrap: 'wrap',
        gap: '20px'
      }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <h2 style={{ fontSize: '22px', fontWeight: 700, color: '#0f172a' }}>{customer.name}</h2>
            <span className="badge badge-active">{customer.status}</span>
          </div>

          <div style={{ display: 'flex', gap: '16px', marginTop: '8px', fontSize: '13px', color: '#64748b', flexWrap: 'wrap' }}>
            <span><strong>Phone:</strong> {customer.phoneNumber || 'Not provided'}</span>
            <span><strong>Aliases:</strong> {customer.aliases?.length ? customer.aliases.join(', ') : 'None'}</span>
            {customer.notes && <span><strong>Notes:</strong> {customer.notes}</span>}
          </div>
        </div>

        {/* Current Balance Box */}
        <div style={{
          background: balance && balance.outstandingBalancePaise > 0 ? '#fff1f2' : '#ecfdf5',
          border: `1px solid ${balance && balance.outstandingBalancePaise > 0 ? '#ffe4e6' : '#d1fae5'}`,
          borderRadius: '12px',
          padding: '16px 24px',
          textAlign: 'right'
        }}>
          <div style={{ fontSize: '12px', fontWeight: 600, color: balance && balance.outstandingBalancePaise > 0 ? '#be123c' : '#047857', textTransform: 'uppercase' }}>
            Current Outstanding Debt
          </div>
          <div style={{
            fontSize: '32px',
            fontWeight: 800,
            color: balance && balance.outstandingBalancePaise > 0 ? '#e11d48' : '#059669',
            marginTop: '2px'
          }}>
            ₹{balance?.balanceInRupees.toFixed(2)}
          </div>
          <button
            onClick={() => speakTelugu(balance?.teluguSpeechMessage || '')}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
              fontSize: '11.5px',
              color: '#d97706',
              fontWeight: 600,
              marginTop: '6px'
            }}
          >
            <Volume2 size={15} />
            <span>Speak Balance / వినిపించు</span>
          </button>
        </div>
      </div>

      {/* Balance Reconciliation Breakdown */}
      <div className="metrics-grid" style={{ marginBottom: '24px' }}>
        <div className="metric-card" style={{ padding: '16px 20px' }}>
          <div>
            <div style={{ fontSize: '12px', color: '#64748b' }}>Total Credits (Appulu)</div>
            <div style={{ fontSize: '20px', fontWeight: 700, color: '#e11d48' }}>
              +₹{((balance?.totalCreditsPaise || 0) / 100).toFixed(2)}
            </div>
          </div>
        </div>

        <div className="metric-card" style={{ padding: '16px 20px' }}>
          <div>
            <div style={{ fontSize: '12px', color: '#64748b' }}>Total Payments Received</div>
            <div style={{ fontSize: '20px', fontWeight: 700, color: '#059669' }}>
              -₹{((balance?.totalPaymentsPaise || 0) / 100).toFixed(2)}
            </div>
          </div>
        </div>

        <div className="metric-card" style={{ padding: '16px 20px' }}>
          <div>
            <div style={{ fontSize: '12px', color: '#64748b' }}>Total Discounts / Waivers</div>
            <div style={{ fontSize: '20px', fontWeight: 700, color: '#1d4ed8' }}>
              -₹{((balance?.totalDiscountsPaise || 0) / 100).toFixed(2)}
            </div>
          </div>
        </div>

        <div className="metric-card" style={{ padding: '16px 20px' }}>
          <div>
            <div style={{ fontSize: '12px', color: '#64748b' }}>Net Outstanding Balance</div>
            <div style={{ fontSize: '20px', fontWeight: 700, color: '#0f172a' }}>
              = ₹{balance?.balanceInRupees.toFixed(2)}
            </div>
          </div>
        </div>
      </div>

      {/* Quick Transaction Action Buttons */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '24px', flexWrap: 'wrap' }}>
        <button
          className="btn btn-primary"
          onClick={() => setActionType('CREDIT')}
        >
          <PlusCircle size={18} />
          <span>Add Credit / అప్పు రాయి (+ ₹)</span>
        </button>

        <button
          className="btn"
          style={{ background: '#059669', color: '#fff' }}
          onClick={() => setActionType('PAYMENT')}
        >
          <MinusCircle size={18} />
          <span>Record Payment / పేమెంట్ తీసుకో (- ₹)</span>
        </button>

        <button
          className="btn btn-secondary"
          onClick={() => setActionType('DISCOUNT')}
        >
          <Tag size={18} />
          <span>Give Discount / రాయితీ ఇవ్వు</span>
        </button>

        <button
          className="btn btn-danger"
          style={{ background: '#fff1f2', color: '#e11d48', border: '1px solid #fecdd3', marginLeft: 'auto' }}
          onClick={() => {
            setErrorMsg(null);
            setShowDeleteModal(true);
          }}
        >
          <Trash2 size={18} />
          <span>Remove Customer / ఖాతాను తొలగించండి</span>
        </button>
      </div>

      {/* Transaction History Table */}
      <div className="card-table">
        <div className="table-header">
          <h3>ఖాతా లావాదేవీల చిట్టా (Transaction Ledger History)</h3>
        </div>

        <table>
          <thead>
            <tr>
              <th>Date & Time</th>
              <th>Type / రకం</th>
              <th>Amount / మొత్తం</th>
              <th>Balance Effect</th>
              <th>Recorded By</th>
              <th>Description / Reason</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {transactions.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                  No transactions recorded yet for this customer.
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
                  <td style={{ fontSize: '12px', color: '#64748b' }}>
                    {tx.createdBy}
                  </td>
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
                  <td>
                    {!tx.hasReversal && tx.type !== 'REVERSAL' && (
                      <button
                        className="btn btn-secondary btn-sm"
                        style={{ padding: '4px 8px', color: '#e11d48' }}
                        onClick={() => setReversalTx(tx)}
                        title="Reverse transaction"
                      >
                        <RotateCcw size={14} />
                        <span>Reverse</span>
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Transaction Modal (Credit / Payment / Discount) */}
      {actionType && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h4>
                {actionType === 'CREDIT' && 'Add Credit / అప్పు రాయి'}
                {actionType === 'PAYMENT' && 'Record Payment / చెల్లింపు జమ'}
                {actionType === 'DISCOUNT' && 'Apply Discount / రాయితీ'}
              </h4>
              <button onClick={closeModal} style={{ color: '#94a3b8', fontSize: '18px' }}>✕</button>
            </div>

            <form onSubmit={handleTransactionSubmit}>
              <div className="modal-body">
                {errorMsg && (
                  <div style={{ padding: '10px', background: '#fff1f2', color: '#e11d48', borderRadius: '6px', marginBottom: '14px', fontSize: '13px' }}>
                    {errorMsg}
                  </div>
                )}

                {excessWarning && (
                  <div style={{ padding: '12px', background: '#fffbeb', border: '1px solid #fef3c7', borderRadius: '8px', marginBottom: '16px' }}>
                    <div style={{ display: 'flex', gap: '8px', color: '#b45309', fontWeight: 600, fontSize: '13.5px' }}>
                      <AlertTriangle size={18} />
                      <span>Excess Payment Warning / హెచ్చరిక</span>
                    </div>
                    <p style={{ fontSize: '13px', color: '#78350f', marginTop: '6px' }}>
                      {excessWarning.messageTelugu}
                    </p>
                    <label style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '10px', fontSize: '13px', fontWeight: 600, cursor: 'pointer' }}>
                      <input
                        type="checkbox"
                        checked={allowAdvance}
                        onChange={(e) => setAllowAdvance(e.target.checked)}
                      />
                      <span>Record excess as Advance / అడ్వాన్స్‌గా జమ చేయండి</span>
                    </label>
                  </div>
                )}

                <div className="form-group">
                  <label className="form-label">Amount in Rupees (₹) *</label>
                  <input
                    type="number"
                    step="0.01"
                    className="form-control"
                    placeholder="0.00"
                    value={amountRupees}
                    onChange={(e) => setAmountRupees(e.target.value)}
                    required
                  />
                </div>

                {actionType === 'DISCOUNT' ? (
                  <div className="form-group">
                    <label className="form-label">Reason for Discount / రాయితీ కారణం *</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="e.g. Regular customer concession"
                      value={reason}
                      onChange={(e) => setReason(e.target.value)}
                      required
                    />
                  </div>
                ) : (
                  <div className="form-group">
                    <label className="form-label">Description / వస్తువుల వివరాలు</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="e.g. 2 Idli + 1 Tea parcel"
                      value={description}
                      onChange={(e) => setDescription(e.target.value)}
                    />
                  </div>
                )}
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={closeModal}>
                  Cancel / రద్దు
                </button>
                <button type="submit" className="btn btn-primary">
                  Confirm & Post / ఖరారు చేయండి
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Reversal Confirmation Modal */}
      {reversalTx && (
        <div className="modal-overlay">
          <div className="modal-content">
            <div className="modal-header">
              <h4 style={{ color: '#e11d48' }}>Reverse Transaction / లావాదేవీ రద్దు</h4>
              <button onClick={() => setReversalTx(null)} style={{ color: '#94a3b8', fontSize: '18px' }}>✕</button>
            </div>

            <form onSubmit={handleReversalSubmit}>
              <div className="modal-body">
                <p style={{ fontSize: '13.5px', color: '#475569', marginBottom: '14px' }}>
                  You are about to cancel transaction <strong>{reversalTx.id}</strong> of <strong>₹{reversalTx.amountInRupees.toFixed(2)}</strong> ({reversalTx.type}).
                  This action strictly compensates the balance effect in the ledger and cannot be undone.
                </p>

                {errorMsg && (
                  <div style={{ padding: '10px', background: '#fff1f2', color: '#e11d48', borderRadius: '6px', marginBottom: '14px', fontSize: '13px' }}>
                    {errorMsg}
                  </div>
                )}

                <div className="form-group">
                  <label className="form-label">Audit Justification / రద్దు చేయడానికి కారణం *</label>
                  <textarea
                    className="form-control"
                    rows={3}
                    placeholder="e.g. Duplicate entry made by cashier in error"
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    required
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setReversalTx(null)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-danger">
                  Confirm Reversal / రద్దు ఖరారు చేయి
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Customer Confirmation Modal */}
      {showDeleteModal && customer && (
        <div className="modal-overlay">
          <div className="modal-content" style={{ maxWidth: '490px' }}>
            <div className="modal-header">
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '10px',
                  background: '#ffe4e6',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#e11d48'
                }}>
                  <Trash2 size={20} />
                </div>
                <div>
                  <h4 style={{ color: '#e11d48', margin: 0, fontSize: '16px' }}>Remove Customer Profile</h4>
                  <div style={{ fontSize: '11px', color: '#64748b' }}>కస్టమర్ ఖాతాను శాశ్వతంగా తొలగించండి</div>
                </div>
              </div>
              <button
                onClick={() => setShowDeleteModal(false)}
                style={{ color: '#94a3b8', fontSize: '18px', background: 'none', border: 'none', cursor: 'pointer' }}
              >
                ✕
              </button>
            </div>

            <div className="modal-body">
              <p style={{ fontSize: '14px', color: '#1e293b', marginBottom: '14px', lineHeight: 1.5 }}>
                Are you sure you want to permanently remove customer <strong>"{customer.name}"</strong>?
              </p>

              {balance && balance.outstandingBalancePaise > 0 && (
                <div style={{
                  padding: '14px',
                  background: '#fff1f2',
                  border: '1px solid #fecdd3',
                  borderRadius: '10px',
                  marginBottom: '16px',
                  display: 'flex',
                  gap: '12px',
                  alignItems: 'flex-start'
                }}>
                  <AlertTriangle size={20} color="#e11d48" style={{ flexShrink: 0, marginTop: '2px' }} />
                  <div style={{ fontSize: '12.5px', color: '#9f1239', lineHeight: 1.45 }}>
                    <strong>బాకీ హెచ్చరిక (Outstanding Debt Warning):</strong>
                    <div style={{ marginTop: '4px' }}>
                      This customer currently has an unpaid balance of <strong style={{ fontSize: '14px' }}>₹{balance.balanceInRupees.toFixed(2)}</strong>.
                      Deleting this customer will permanently delete this balance and ledger history without a settlement payment.
                    </div>
                  </div>
                </div>
              )}

              {errorMsg && (
                <div style={{ padding: '10px 14px', background: '#fff1f2', color: '#e11d48', borderRadius: '8px', marginBottom: '14px', fontSize: '13px' }}>
                  {errorMsg}
                </div>
              )}

              <p style={{ fontSize: '12px', color: '#64748b', background: '#f8fafc', padding: '10px 12px', borderRadius: '8px', border: '1px solid #e2e8f0', margin: 0 }}>
                ℹ️ All {transactions.length} transaction records linked to this customer will be removed. This action is irreversible and recorded in the audit log.
              </p>
            </div>

            <div className="modal-footer">
              <button
                type="button"
                className="btn btn-secondary"
                disabled={isDeleting}
                onClick={() => setShowDeleteModal(false)}
              >
                Cancel / రద్దు
              </button>
              <button
                type="button"
                className="btn btn-danger"
                disabled={isDeleting}
                onClick={handleDeleteCustomer}
                style={{ background: '#e11d48', color: '#fff', border: 'none' }}
              >
                {isDeleting ? 'Removing...' : 'Permanently Delete / ఖాతాను తొలగించు'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
