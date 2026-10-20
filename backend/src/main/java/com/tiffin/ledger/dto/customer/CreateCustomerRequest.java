package com.tiffin.ledger.dto.customer;

import jakarta.validation.constraints.NotBlank;
import java.util.List;

public class CreateCustomerRequest {

    @NotBlank(message = "Customer name is required")
    private String name;

    private List<String> aliases;

    // Optional phone number
    private String phoneNumber;

    private String notes;

    // Optional initial opening balance to migrate from paper notebook
    private long initialOpeningBalancePaise = 0L;

    public CreateCustomerRequest() {}

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public List<String> getAliases() { return aliases; }
    public void setAliases(List<String> aliases) { this.aliases = aliases; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public long getInitialOpeningBalancePaise() { return initialOpeningBalancePaise; }
    public void setInitialOpeningBalancePaise(long initialOpeningBalancePaise) {
        this.initialOpeningBalancePaise = initialOpeningBalancePaise;
    }
}
