package com.tiffin.ledger.dto.voice;

import com.tiffin.ledger.dto.customer.CustomerDto;

import java.util.ArrayList;
import java.util.List;

public class VoiceParseResponse {

    private String intent; // ADD_CREDIT, RECORD_PAYMENT, QUERY_BALANCE, APPLY_DISCOUNT, VIEW_HISTORY, DAILY_REPORT, UNKNOWN
    private String customerName;
    private Long amountPaise;
    private Double amountInRupees;
    private double confidence = 1.0;
    private List<CustomerDto> matchedCustomers = new ArrayList<>();
    private boolean requiresDisambiguation = false;
    private boolean requiresConfirmation = false;
    private String confirmationMessage;
    private String clarificationQuestion;
    private String rawTranscript;

    public VoiceParseResponse() {}

    public String getIntent() { return intent; }
    public void setIntent(String intent) { this.intent = intent; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public Long getAmountPaise() { return amountPaise; }
    public void setAmountPaise(Long amountPaise) {
        this.amountPaise = amountPaise;
        this.amountInRupees = amountPaise != null ? amountPaise / 100.0 : null;
    }

    public Double getAmountInRupees() { return amountInRupees; }
    public void setAmountInRupees(Double amountInRupees) { this.amountInRupees = amountInRupees; }

    public double getConfidence() { return confidence; }
    public void setConfidence(double confidence) { this.confidence = confidence; }

    public List<CustomerDto> getMatchedCustomers() { return matchedCustomers; }
    public void setMatchedCustomers(List<CustomerDto> matchedCustomers) {
        this.matchedCustomers = matchedCustomers != null ? matchedCustomers : new ArrayList<>();
    }

    public boolean isRequiresDisambiguation() { return requiresDisambiguation; }
    public void setRequiresDisambiguation(boolean requiresDisambiguation) { this.requiresDisambiguation = requiresDisambiguation; }

    public boolean isRequiresConfirmation() { return requiresConfirmation; }
    public void setRequiresConfirmation(boolean requiresConfirmation) { this.requiresConfirmation = requiresConfirmation; }

    public String getConfirmationMessage() { return confirmationMessage; }
    public void setConfirmationMessage(String confirmationMessage) { this.confirmationMessage = confirmationMessage; }

    public String getClarificationQuestion() { return clarificationQuestion; }
    public void setClarificationQuestion(String clarificationQuestion) { this.clarificationQuestion = clarificationQuestion; }

    public String getRawTranscript() { return rawTranscript; }
    public void setRawTranscript(String rawTranscript) { this.rawTranscript = rawTranscript; }
}
