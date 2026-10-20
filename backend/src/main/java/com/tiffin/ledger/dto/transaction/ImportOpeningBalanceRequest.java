package com.tiffin.ledger.dto.transaction;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import java.time.Instant;

public class ImportOpeningBalanceRequest {

    @NotBlank(message = "Customer ID is required")
    private String customerId;

    @Min(value = 0, message = "Opening balance cannot be negative")
    private long amountPaise;

    private String notebookPageNumber;

    private String notes;

    private Instant openingDate;

    public ImportOpeningBalanceRequest() {}

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public long getAmountPaise() { return amountPaise; }
    public void setAmountPaise(long amountPaise) { this.amountPaise = amountPaise; }

    public String getNotebookPageNumber() { return notebookPageNumber; }
    public void setNotebookPageNumber(String notebookPageNumber) { this.notebookPageNumber = notebookPageNumber; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public Instant getOpeningDate() { return openingDate; }
    public void setOpeningDate(Instant openingDate) { this.openingDate = openingDate; }
}
