package com.tiffin.ledger.exception;

public class ExcessPaymentException extends RuntimeException {
    private final String customerId;
    private final String customerName;
    private final long currentBalancePaise;
    private final long paymentAmountPaise;
    private final long excessAmountPaise;
    private final String messageTelugu;

    public ExcessPaymentException(String customerId, String customerName, long currentBalancePaise,
                                  long paymentAmountPaise, long excessAmountPaise, String messageTelugu) {
        super(String.format("Payment amount (₹%.2f) exceeds outstanding debt (₹%.2f) by ₹%.2f for customer %s",
                paymentAmountPaise / 100.0, currentBalancePaise / 100.0, excessAmountPaise / 100.0, customerName));
        this.customerId = customerId;
        this.customerName = customerName;
        this.currentBalancePaise = currentBalancePaise;
        this.paymentAmountPaise = paymentAmountPaise;
        this.excessAmountPaise = excessAmountPaise;
        this.messageTelugu = messageTelugu;
    }

    public String getCustomerId() { return customerId; }
    public String getCustomerName() { return customerName; }
    public long getCurrentBalancePaise() { return currentBalancePaise; }
    public long getPaymentAmountPaise() { return paymentAmountPaise; }
    public long getExcessAmountPaise() { return excessAmountPaise; }
    public String getMessageTelugu() { return messageTelugu; }
}
