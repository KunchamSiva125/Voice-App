package com.tiffin.ledger.domain;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Document(collection = "ledgerTransactions")
@CompoundIndexes({
    @CompoundIndex(name = "cust_effective_idx", def = "{'customerId': 1, 'effectiveAt': -1}"),
    @CompoundIndex(name = "type_effective_idx", def = "{'type': 1, 'effectiveAt': 1}")
})
public class LedgerTransaction {

    @Id
    private String id;

    @Indexed
    private String customerId;

    private TransactionType type;

    // Nominal positive amount in integer paise (e.g., 10000 = ₹100.00)
    private long amountPaise;

    // Signed balance impact in integer paise (+10000 for CREDIT, -10000 for PAYMENT, etc.)
    private long balanceEffectPaise;

    private TransactionStatus status = TransactionStatus.POSTED;

    // Business-effective timestamp (in Asia/Kolkata context)
    private Instant effectiveAt;

    // Immutable server-generated timestamp
    private Instant createdAt = Instant.now();

    private String createdBy;

    // Unique sparse idempotency key to prevent accidental duplicate entries
    @Indexed(unique = true, sparse = true)
    private String idempotencyKey;

    private String description;

    private String correctionReason;

    // If this transaction is a REVERSAL, references the transaction it cancels
    @Indexed(sparse = true)
    private String reversesTransactionId;

    // If this transaction itself was reversed, references the reversal transaction
    private String reversalTransactionId;

    private boolean hasReversal = false;

    private List<String> relatedTransactionIds = new ArrayList<>();

    // Optional metadata (e.g. voice utterance transcript, channel)
    private Map<String, Object> metadata = new HashMap<>();

    public LedgerTransaction() {
    }

    public LedgerTransaction(String customerId, TransactionType type, long amountPaise,
                             long balanceEffectPaise, Instant effectiveAt, String createdBy,
                             String idempotencyKey, String description) {
        this.customerId = customerId;
        this.type = type;
        this.amountPaise = amountPaise;
        this.balanceEffectPaise = balanceEffectPaise;
        this.effectiveAt = effectiveAt != null ? effectiveAt : Instant.now();
        this.createdAt = Instant.now();
        this.createdBy = createdBy;
        this.idempotencyKey = idempotencyKey;
        this.description = description;
        this.status = TransactionStatus.POSTED;
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public TransactionType getType() { return type; }
    public void setType(TransactionType type) { this.type = type; }

    public long getAmountPaise() { return amountPaise; }
    public void setAmountPaise(long amountPaise) { this.amountPaise = amountPaise; }

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

    public String getIdempotencyKey() { return idempotencyKey; }
    public void setIdempotencyKey(String idempotencyKey) { this.idempotencyKey = idempotencyKey; }

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

    public List<String> getRelatedTransactionIds() { return relatedTransactionIds; }
    public void setRelatedTransactionIds(List<String> relatedTransactionIds) {
        this.relatedTransactionIds = relatedTransactionIds != null ? relatedTransactionIds : new ArrayList<>();
    }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) {
        this.metadata = metadata != null ? metadata : new HashMap<>();
    }
}
