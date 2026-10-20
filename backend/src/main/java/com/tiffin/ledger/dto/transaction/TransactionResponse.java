package com.tiffin.ledger.dto.transaction;

import com.tiffin.ledger.domain.TransactionType;
import java.time.Instant;

public class TransactionResponse {
    private String transactionId;
    private String customerId;
    private String customerName;
    private TransactionType type;
    private long amountPaise;
    private long balanceEffectPaise;
    private long previousBalancePaise;
    private long updatedBalancePaise;
    private double updatedBalanceInRupees;
    private Instant createdAt;
    private String teluguSpeechMessage;
    private boolean isDuplicateReplay = false;

    public TransactionResponse() {}

    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public TransactionType getType() { return type; }
    public void setType(TransactionType type) { this.type = type; }

    public long getAmountPaise() { return amountPaise; }
    public void setAmountPaise(long amountPaise) { this.amountPaise = amountPaise; }

    public long getBalanceEffectPaise() { return balanceEffectPaise; }
    public void setBalanceEffectPaise(long balanceEffectPaise) { this.balanceEffectPaise = balanceEffectPaise; }

    public long getPreviousBalancePaise() { return previousBalancePaise; }
    public void setPreviousBalancePaise(long previousBalancePaise) { this.previousBalancePaise = previousBalancePaise; }

    public long getUpdatedBalancePaise() { return updatedBalancePaise; }
    public void setUpdatedBalancePaise(long updatedBalancePaise) {
        this.updatedBalancePaise = updatedBalancePaise;
        this.updatedBalanceInRupees = updatedBalancePaise / 100.0;
    }

    public double getUpdatedBalanceInRupees() { return updatedBalanceInRupees; }
    public void setUpdatedBalanceInRupees(double updatedBalanceInRupees) { this.updatedBalanceInRupees = updatedBalanceInRupees; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public String getTeluguSpeechMessage() { return teluguSpeechMessage; }
    public void setTeluguSpeechMessage(String teluguSpeechMessage) { this.teluguSpeechMessage = teluguSpeechMessage; }

    public boolean isDuplicateReplay() { return isDuplicateReplay; }
    public void setDuplicateReplay(boolean duplicateReplay) { isDuplicateReplay = duplicateReplay; }
}
