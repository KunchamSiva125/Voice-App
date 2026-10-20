package com.tiffin.ledger.dto.customer;

import com.tiffin.ledger.domain.Customer;
import com.tiffin.ledger.domain.CustomerStatus;

import java.time.Instant;
import java.util.List;

public class CustomerDto {
    private String id;
    private String name;
    private String normalizedName;
    private List<String> aliases;
    private String phoneNumber;
    private String notes;
    private CustomerStatus status;
    private long outstandingBalancePaise;
    private double balanceInRupees;
    private Instant createdAt;
    private Instant updatedAt;

    public CustomerDto() {}
    public CustomerDto(Customer customer, long balancePaise) {
        if (customer != null) {
            this.id = customer.getId();
            this.name = customer.getName();
            this.normalizedName = customer.getNormalizedName();
            this.aliases = customer.getAliases();
            this.phoneNumber = customer.getPhoneNumber();
            this.notes = customer.getNotes();
            this.status = customer.getStatus();
            this.outstandingBalancePaise = balancePaise;
            this.balanceInRupees = balancePaise / 100.0;
            this.createdAt = customer.getCreatedAt();
            this.updatedAt = customer.getUpdatedAt();
        }
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getNormalizedName() { return normalizedName; }
    public void setNormalizedName(String normalizedName) { this.normalizedName = normalizedName; }

    public List<String> getAliases() { return aliases; }
    public void setAliases(List<String> aliases) { this.aliases = aliases; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public CustomerStatus getStatus() { return status; }
    public void setStatus(CustomerStatus status) { this.status = status; }

    public long getOutstandingBalancePaise() { return outstandingBalancePaise; }
    public void setOutstandingBalancePaise(long outstandingBalancePaise) {
        this.outstandingBalancePaise = outstandingBalancePaise;
        this.balanceInRupees = outstandingBalancePaise / 100.0;
    }

    public double getBalanceInRupees() { return balanceInRupees; }
    public void setBalanceInRupees(double balanceInRupees) { this.balanceInRupees = balanceInRupees; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
