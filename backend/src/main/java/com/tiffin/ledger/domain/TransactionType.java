package com.tiffin.ledger.domain;

/**
 * Distinct financial transaction types in the Tiffin Ledger.
 * Each type has specific accounting semantics and permissions.
 */
public enum TransactionType {
    CREDIT,           // Customer took food on credit (Appu / బాకీ). Debt increases (+).
    PAYMENT,          // Customer paid money. Debt decreases (-).
    DISCOUNT,         // Owner intentionally forgave debt. Debt decreases (-).
    OPENING_BALANCE,  // Migrated historical debt from paper notebook (+).
    REVERSAL,         // Strictly cancels a prior transaction's balance effect (-1 * orig).
    ADJUSTMENT        // Signed audit adjustment for corrections.
}
