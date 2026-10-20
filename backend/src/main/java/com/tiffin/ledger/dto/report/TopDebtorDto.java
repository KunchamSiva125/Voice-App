package com.tiffin.ledger.dto.report;

public class TopDebtorDto {
    private String customerId;
    private String customerName;
    private String phoneNumber;
    private long balancePaise;
    private double balanceInRupees;

    public TopDebtorDto() {}
    public TopDebtorDto(String customerId, String customerName, String phoneNumber, long balancePaise) {
        this.customerId = customerId;
        this.customerName = customerName;
        this.phoneNumber = phoneNumber;
        this.balancePaise = balancePaise;
        this.balanceInRupees = balancePaise / 100.0;
    }

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public long getBalancePaise() { return balancePaise; }
    public void setBalancePaise(long balancePaise) {
        this.balancePaise = balancePaise;
        this.balanceInRupees = balancePaise / 100.0;
    }

    public double getBalanceInRupees() { return balanceInRupees; }
    public void setBalanceInRupees(double balanceInRupees) { this.balanceInRupees = balanceInRupees; }
}
