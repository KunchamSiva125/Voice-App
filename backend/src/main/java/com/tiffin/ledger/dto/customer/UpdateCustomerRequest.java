package com.tiffin.ledger.dto.customer;

import com.tiffin.ledger.domain.CustomerStatus;
import java.util.List;

public class UpdateCustomerRequest {
    private String name;
    private List<String> aliases;
    private String phoneNumber;
    private String notes;
    private CustomerStatus status;

    public UpdateCustomerRequest() {}

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public List<String> getAliases() { return aliases; }
    public void setAliases(List<String> aliases) { this.aliases = aliases; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public CustomerStatus getStatus() { return status; }
    public void setStatus(CustomerStatus status) { this.status = status; }
}
