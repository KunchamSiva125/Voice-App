package com.tiffin.ledger.dto.transaction;

import jakarta.validation.constraints.NotBlank;

public class ReverseTransactionRequest {

    @NotBlank(message = "Reason for reversal is strictly required for audit compliance")
    private String reason;

    public ReverseTransactionRequest() {}
    public ReverseTransactionRequest(String reason) {
        this.reason = reason;
    }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}
