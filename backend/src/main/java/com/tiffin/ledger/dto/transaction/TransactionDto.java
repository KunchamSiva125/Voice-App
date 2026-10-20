package com.tiffin.ledger.dto.transaction;

import com.tiffin.ledger.domain.LedgerTransaction;
import com.tiffin.ledger.domain.TransactionStatus;
import com.tiffin.ledger.domain.TransactionType;

import java.time.Instant;
import java.util.Map;

public class TransactionDto {
    private String id;
    private String customerId;
    private String customerName;
    private TransactionType type;
    private long amountPaise;
    private double amountInRupees;
    private long balanceEffectPaise;
    private TransactionStatus status;
    private Instant effectiveAt;
    private Instant createdAt;
    private String createdBy;
    private String description;
    private String correctionReason;
    private String reversesTransactionId;
    private String reversalTransactionId;
    private boolean hasReversal;
    private Long balanceAfterPaise;
    private Map<String, Object> metadata;

    public TransactionDto() {}

    public TransactionDto(LedgerTransaction tx, String customerName) {
        if (tx != null) {
            this.id = tx.getId();
            this.customerId = tx.getCustomerId();
            this.customerName = customerName;
            this.type = tx.getType();
            this.amountPaise = tx.getAmountPaise();
            this.amountInRupees = tx.getAmountPaise() / 100.0;
            this.balanceEffectPaise = tx.getBalanceEffectPaise();
            this.status = tx.getStatus();
            this.effectiveAt = tx.getEffectiveAt();
            this.createdAt = tx.getCreatedAt();
            this.createdBy = tx.getCreatedBy();
            this.description = tx.getDescription();
            this.correctionReason = tx.getCorrectionReason();
            this.reversesTransactionId = tx.getReversesTransactionId();
            this.reversalTransactionId = tx.getReversalTransactionId();
            this.hasReversal = tx.isHasReversal();
            this.metadata = tx.getMetadata();
        }
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public TransactionType getType() { return type; }
    public void setType(TransactionType type) { this.type = type; }

    public long getAmountPaise() { return amountPaise; }
    public void setAmountPaise(long amountPaise) { 
        this.amountPaise = amountPaise;
        this.amountInRupees = amountPaise / 100.0;
    }

    public double getAmountInRupees() { return amountInRupees; }
    public void setAmountInRupees(double amountInRupees) { this.amountInRupees = amountInRupees; }

    public long getBalanceEffectPaise() { return balanceEffectPaise; }
    public void setBalanceEffectPaise(long balanceEffectPaise) { this.balanceEffectPaise = balanceEffectPaise; }

    public TransactionStatus getStatus() { return status; }
    public void setStatus(TransactionStatus status) { this.status = status; }

    public Instant getEffectiveAt() { return effectiveAt; }
    public void setEffectiveAt(Instant effectiveAt) { this.effectiveAt = effectiveAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getCorrectionReason() { return correctionReason; }
    public void setCorrectionReason(String correctionReason) { this.correctionReason = correctionReason; }

    public String getReversesTransactionId() { return reversesTransactionId; }
    public void setReversesTransactionId(String reversesTransactionId) { this.reversesTransactionId = reversesTransactionId; }

    public String getReversalTransactionId() { return reversalTransactionId; }
    public void setReversalTransactionId(String reversalTransactionId) { this.reversalTransactionId = reversalTransactionId; }

    public boolean isHasReversal() { return hasReversal; }
    public void setHasReversal(boolean hasReversal) { this.hasReversal = hasReversal; }

    public Long getBalanceAfterPaise() { return balanceAfterPaise; }
    public void setBalanceAfterPaise(Long balanceAfterPaise) { this.balanceAfterPaise = balanceAfterPaise; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) { this.metadata = metadata; }
}
