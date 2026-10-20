package com.tiffin.ledger.dto.customer;

import java.time.Instant;

public class CustomerBalanceDto {
    private String customerId;
    private String customerName;
    private String phoneNumber;
    private long outstandingBalancePaise;
    private double balanceInRupees;
    private long totalCreditsPaise;
    private long totalPaymentsPaise;
    private long totalDiscountsPaise;
    private Instant latestTransactionAt;
    private String teluguSpeechMessage;

    public CustomerBalanceDto() {}

    public String getCustomerId() { return customerId; }
    public void setCustomerId(String customerId) { this.customerId = customerId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public long getOutstandingBalancePaise() { return outstandingBalancePaise; }
    public void setOutstandingBalancePaise(long outstandingBalancePaise) {
        this.outstandingBalancePaise = outstandingBalancePaise;
        this.balanceInRupees = outstandingBalancePaise / 100.0;
    }

    public double getBalanceInRupees() { return balanceInRupees; }
    public void setBalanceInRupees(double balanceInRupees) { this.balanceInRupees = balanceInRupees; }

    public long getTotalCreditsPaise() { return totalCreditsPaise; }
    public void setTotalCreditsPaise(long totalCreditsPaise) { this.totalCreditsPaise = totalCreditsPaise; }

    public long getTotalPaymentsPaise() { return totalPaymentsPaise; }
    public void setTotalPaymentsPaise(long totalPaymentsPaise) { this.totalPaymentsPaise = totalPaymentsPaise; }

    public long getTotalDiscountsPaise() { return totalDiscountsPaise; }
    public void setTotalDiscountsPaise(long totalDiscountsPaise) { this.totalDiscountsPaise = totalDiscountsPaise; }

    public Instant getLatestTransactionAt() { return latestTransactionAt; }
    public void setLatestTransactionAt(Instant latestTransactionAt) { this.latestTransactionAt = latestTransactionAt; }

    public String getTeluguSpeechMessage() { return teluguSpeechMessage; }
    public void setTeluguSpeechMessage(String teluguSpeechMessage) { this.teluguSpeechMessage = teluguSpeechMessage; }
}
