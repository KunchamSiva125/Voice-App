package com.tiffin.ledger.dto.transaction;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

public class ApplyDiscountRequest {

    @NotBlank(message = "Customer ID is required")
    private String customerId;

    @Min(value = 1, message = "Discount amount must be greater than zero")
    private long amountPaise;

    @NotBlank(message = "Reason for discount or waiver is required")
    private String reason;

    private Instant effectiveAt;

    public ApplyDiscountRequest() {}

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public long getAmountPaise() { return amountPaise; }
    public void setAmountPaise(long amountPaise) { this.amountPaise = amountPaise; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public Instant getEffectiveAt() { return effectiveAt; }
    public void setEffectiveAt(Instant effectiveAt) { this.effectiveAt = effectiveAt; }
}
