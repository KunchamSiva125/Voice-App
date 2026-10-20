package com.tiffin.ledger.dto.transaction;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

public class RecordCreditRequest {

    @NotBlank(message = "Customer ID is required")
    private String customerId;

    @Min(value = 1, message = "Credit amount must be greater than zero")
    private long amountPaise;

    private String description;

    // Optional effective date/time; defaults to now
    private Instant effectiveAt;

    public RecordCreditRequest() {}
    public RecordCreditRequest(String customerId, long amountPaise, String description) {
        this.customerId = customerId;
        this.amountPaise = amountPaise;
        this.description = description;
    }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public long getAmountPaise() { return amountPaise; }
    public void setAmountPaise(long amountPaise) { this.amountPaise = amountPaise; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Instant getEffectiveAt() { return effectiveAt; }
    public void setEffectiveAt(Instant effectiveAt) { this.effectiveAt = effectiveAt; }
}
