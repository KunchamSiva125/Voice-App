package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.Customer;
import com.tiffin.ledger.domain.LedgerTransaction;
import com.tiffin.ledger.domain.TransactionStatus;
import com.tiffin.ledger.domain.TransactionType;
import com.tiffin.ledger.dto.customer.CustomerBalanceDto;
import com.tiffin.ledger.dto.transaction.*;
import com.tiffin.ledger.exception.ExcessPaymentException;
import com.tiffin.ledger.repository.CustomerRepository;
import com.tiffin.ledger.repository.LedgerTransactionRepository;
import com.tiffin.ledger.security.UserPrincipal;
import com.tiffin.ledger.util.CurrencyUtil;
import com.tiffin.ledger.util.TeluguVoiceUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

@Service
public class LedgerService {

    private static final Logger log = LoggerFactory.getLogger(LedgerService.class);

    private final LedgerTransactionRepository transactionRepository;
    private final CustomerRepository customerRepository;
    private final AuditService auditService;

    public LedgerService(LedgerTransactionRepository transactionRepository,
                         CustomerRepository customerRepository,
                         AuditService auditService) {
        this.transactionRepository = transactionRepository;
        this.customerRepository = customerRepository;
        this.auditService = auditService;
    }

    /**
     * Calculates the true outstanding balance from the ledger.
     * Invariant: outstandingBalance = sum(balanceEffectPaise) of all posted transactions.
     * Reversals cancel the original effect exactly once via opposite signed balanceEffectPaise.
     */
    public long calculateOutstandingBalancePaise(String customerId) {
        List<LedgerTransaction> txs = transactionRepository.findByCustomerIdOrderByEffectiveAtAsc(customerId);
        long totalBalance = 0L;
        for (LedgerTransaction tx : txs) {
            if (tx.getStatus() == TransactionStatus.POSTED) {
                totalBalance += tx.getBalanceEffectPaise();
            }
        }
        return totalBalance;
    }

    /**
     * Retrieves detailed balance breakdown for a customer.
     */
    public CustomerBalanceDto getCustomerBalanceDetails(String customerId) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found: " + customerId));

        List<LedgerTransaction> txs = transactionRepository.findByCustomerIdOrderByEffectiveAtAsc(customerId);

        long balance = 0L;
        long totalCredits = 0L;
        long totalPayments = 0L;
        long totalDiscounts = 0L;
        Instant latestTxDate = null;

        for (LedgerTransaction tx : txs) {
            if (tx.getStatus() == TransactionStatus.POSTED) {
                balance += tx.getBalanceEffectPaise();
                if (tx.getType() == TransactionType.CREDIT || tx.getType() == TransactionType.OPENING_BALANCE) {
                    totalCredits += tx.getAmountPaise();
                } else if (tx.getType() == TransactionType.PAYMENT) {
                    totalPayments += tx.getAmountPaise();
                } else if (tx.getType() == TransactionType.DISCOUNT) {
                    totalDiscounts += tx.getAmountPaise();
                }
                if (latestTxDate == null || (tx.getEffectiveAt() != null && tx.getEffectiveAt().isAfter(latestTxDate))) {
                    latestTxDate = tx.getEffectiveAt();
                }
            }
        }

        CustomerBalanceDto dto = new CustomerBalanceDto();
        dto.setCustomerId(customer.getId());
        dto.setCustomerName(customer.getName());
        dto.setPhoneNumber(customer.getPhoneNumber());
        dto.setOutstandingBalancePaise(balance);
        dto.setTotalCreditsPaise(totalCredits);
        dto.setTotalPaymentsPaise(totalPayments);
        dto.setTotalDiscountsPaise(totalDiscounts);
        dto.setLatestTransactionAt(latestTxDate);
        dto.setTeluguSpeechMessage(TeluguVoiceUtil.buildBalanceQueryResponse(customer.getName(), balance));

        return dto;
    }

    /**
     * Records a new credit transaction (Appu / బాకీ).
     */
    @Transactional
    public TransactionResponse recordCredit(RecordCreditRequest request, UserPrincipal actor, String idempotencyKey) {
        Customer customer = getActiveCustomer(request.getCustomerId());

        // Check Idempotency for safe replay
        if (idempotencyKey != null && !idempotencyKey.trim().isEmpty()) {
            Optional<LedgerTransaction> existing = transactionRepository.findByIdempotencyKey(idempotencyKey.trim());
            if (existing.isPresent()) {
                log.info("Idempotent replay detected for key: {}", idempotencyKey);
                return buildReplayResponse(existing.get(), customer);
            }
        }

        if (request.getAmountPaise() <= 0) {
            throw new IllegalArgumentException("Credit amount must be greater than zero");
        }

        long previousBalance = calculateOutstandingBalancePaise(customer.getId());
        long balanceEffect = request.getAmountPaise(); // positive: increases debt
        long updatedBalance = previousBalance + balanceEffect;

        Instant effectiveAt = request.getEffectiveAt() != null ? request.getEffectiveAt() : Instant.now();

        LedgerTransaction tx = new LedgerTransaction(
                customer.getId(),
                TransactionType.CREDIT,
                request.getAmountPaise(),
                balanceEffect,
                effectiveAt,
                actor.getUsername(),
                idempotencyKey != null && !idempotencyKey.trim().isEmpty() ? idempotencyKey.trim() : null,
                request.getDescription()
        );

        LedgerTransaction saved = transactionRepository.save(tx);

        auditService.logEvent(actor.getId(), actor.getUsername(), "TRANSACTION_CREATED",
                "TRANSACTION", saved.getId(), "Credit added: " + CurrencyUtil.formatInr(saved.getAmountPaise()),
                Map.of("previousBalancePaise", previousBalance),
                Map.of("updatedBalancePaise", updatedBalance), null);

        TransactionResponse response = new TransactionResponse();
        response.setTransactionId(saved.getId());
        response.setCustomerId(customer.getId());
        response.setCustomerName(customer.getName());
        response.setType(saved.getType());
        response.setAmountPaise(saved.getAmountPaise());
        response.setBalanceEffectPaise(saved.getBalanceEffectPaise());
        response.setPreviousBalancePaise(previousBalance);
        response.setUpdatedBalancePaise(updatedBalance);
        response.setCreatedAt(saved.getCreatedAt());
        response.setTeluguSpeechMessage(TeluguVoiceUtil.buildCreditRecordedResponse(
                customer.getName(), saved.getAmountPaise(), updatedBalance));

        return response;
    }

    /**
     * Records a customer payment.
     * Invariant: Payment must be positive. If payment exceeds outstanding debt,
     * requires explicit confirmation (allowExcessAsAdvance) to prevent silent errors.
     */
    @Transactional
    public TransactionResponse recordPayment(RecordPaymentRequest request, UserPrincipal actor, String idempotencyKey) {
        Customer customer = getActiveCustomer(request.getCustomerId());

        // Check Idempotency for safe replay
        if (idempotencyKey != null && !idempotencyKey.trim().isEmpty()) {
            Optional<LedgerTransaction> existing = transactionRepository.findByIdempotencyKey(idempotencyKey.trim());
            if (existing.isPresent()) {
                log.info("Idempotent replay detected for payment key: {}", idempotencyKey);
                return buildReplayResponse(existing.get(), customer);
            }
        }

        if (request.getAmountPaise() <= 0) {
            throw new IllegalArgumentException("Payment amount must be greater than zero");
        }

        long previousBalance = calculateOutstandingBalancePaise(customer.getId());

        // Excess payment check
        if (request.getAmountPaise() > previousBalance && !request.isAllowExcessAsAdvance()) {
            long excessPaise = request.getAmountPaise() - previousBalance;
            String messageTelugu = customer.getName() + " గారి చెల్లింపు " + CurrencyUtil.toTeluguRupeesString(request.getAmountPaise()) +
                    ", ప్రస్తుత బాకీ " + CurrencyUtil.toTeluguRupeesString(previousBalance) + " కంటే ఎక్కువగా ఉంది. అడ్వాన్స్‌గా జమ చేయాలా?";
            throw new ExcessPaymentException(
                    customer.getId(),
                    customer.getName(),
                    previousBalance,
                    request.getAmountPaise(),
                    excessPaise,
                    messageTelugu
            );
        }

        long balanceEffect = -request.getAmountPaise(); // negative: decreases debt
        long updatedBalance = previousBalance + balanceEffect;

        Instant effectiveAt = request.getEffectiveAt() != null ? request.getEffectiveAt() : Instant.now();

        LedgerTransaction tx = new LedgerTransaction(
                customer.getId(),
                TransactionType.PAYMENT,
                request.getAmountPaise(),
                balanceEffect,
                effectiveAt,
                actor.getUsername(),
                idempotencyKey != null && !idempotencyKey.trim().isEmpty() ? idempotencyKey.trim() : null,
                request.getDescription()
        );

        LedgerTransaction saved = transactionRepository.save(tx);

        auditService.logEvent(actor.getId(), actor.getUsername(), "TRANSACTION_CREATED",
                "TRANSACTION", saved.getId(), "Payment recorded: " + CurrencyUtil.formatInr(saved.getAmountPaise()),
                Map.of("previousBalancePaise", previousBalance),
                Map.of("updatedBalancePaise", updatedBalance), null);

        TransactionResponse response = new TransactionResponse();
        response.setTransactionId(saved.getId());
        response.setCustomerId(customer.getId());
        response.setCustomerName(customer.getName());
        response.setType(saved.getType());
        response.setAmountPaise(saved.getAmountPaise());
        response.setBalanceEffectPaise(saved.getBalanceEffectPaise());
        response.setPreviousBalancePaise(previousBalance);
        response.setUpdatedBalancePaise(updatedBalance);
        response.setCreatedAt(saved.getCreatedAt());
        response.setTeluguSpeechMessage(TeluguVoiceUtil.buildPaymentRecordedResponse(
                customer.getName(), saved.getAmountPaise(), updatedBalance));

        return response;
    }

    /**
     * Applies an intentional discount / waiver to forgive customer debt.
     * Requires OWNER or ADMIN.
     */
    @Transactional
    public TransactionResponse applyDiscount(ApplyDiscountRequest request, UserPrincipal actor, String idempotencyKey) {
        Customer customer = getActiveCustomer(request.getCustomerId());

        if (idempotencyKey != null && !idempotencyKey.trim().isEmpty()) {
            Optional<LedgerTransaction> existing = transactionRepository.findByIdempotencyKey(idempotencyKey.trim());
            if (existing.isPresent()) {
                return buildReplayResponse(existing.get(), customer);
            }
        }

        if (request.getAmountPaise() <= 0) {
            throw new IllegalArgumentException("Discount amount must be greater than zero");
        }

        long previousBalance = calculateOutstandingBalancePaise(customer.getId());
        long balanceEffect = -request.getAmountPaise(); // negative: decreases debt
        long updatedBalance = previousBalance + balanceEffect;

        Instant effectiveAt = request.getEffectiveAt() != null ? request.getEffectiveAt() : Instant.now();

        LedgerTransaction tx = new LedgerTransaction(
                customer.getId(),
                TransactionType.DISCOUNT,
                request.getAmountPaise(),
                balanceEffect,
                effectiveAt,
                actor.getUsername(),
                idempotencyKey != null && !idempotencyKey.trim().isEmpty() ? idempotencyKey.trim() : null,
                "Discount: " + request.getReason()
        );
        tx.setCorrectionReason(request.getReason());

        LedgerTransaction saved = transactionRepository.save(tx);

        auditService.logEvent(actor.getId(), actor.getUsername(), "DISCOUNT_APPLIED",
                "TRANSACTION", saved.getId(), "Discount applied: " + CurrencyUtil.formatInr(saved.getAmountPaise()) + " Reason: " + request.getReason(),
                Map.of("previousBalancePaise", previousBalance),
                Map.of("updatedBalancePaise", updatedBalance), null);

        TransactionResponse response = new TransactionResponse();
        response.setTransactionId(saved.getId());
        response.setCustomerId(customer.getId());
        response.setCustomerName(customer.getName());
        response.setType(saved.getType());
        response.setAmountPaise(saved.getAmountPaise());
        response.setBalanceEffectPaise(saved.getBalanceEffectPaise());
        response.setPreviousBalancePaise(previousBalance);
        response.setUpdatedBalancePaise(updatedBalance);
        response.setCreatedAt(saved.getCreatedAt());
        response.setTeluguSpeechMessage(TeluguVoiceUtil.buildDiscountResponse(
                customer.getName(), saved.getAmountPaise(), updatedBalance));

        return response;
    }

    /**
     * Imports opening balance migrated from the physical paper notebook.
     * Restricted to OWNER.
     */
    @Transactional
    public TransactionResponse importOpeningBalance(ImportOpeningBalanceRequest request, UserPrincipal actor, String idempotencyKey) {
        Customer customer = getActiveCustomer(request.getCustomerId());

        if (idempotencyKey != null && !idempotencyKey.trim().isEmpty()) {
            Optional<LedgerTransaction> existing = transactionRepository.findByIdempotencyKey(idempotencyKey.trim());
            if (existing.isPresent()) {
                return buildReplayResponse(existing.get(), customer);
            }
        }

        if (request.getAmountPaise() < 0) {
            throw new IllegalArgumentException("Opening balance cannot be negative");
        }

        long previousBalance = calculateOutstandingBalancePaise(customer.getId());
        long balanceEffect = request.getAmountPaise();
        long updatedBalance = previousBalance + balanceEffect;

        String description = "Opening Balance from notebook";
        if (request.getNotebookPageNumber() != null && !request.getNotebookPageNumber().trim().isEmpty()) {
            description += " (" + request.getNotebookPageNumber().trim() + ")";
        }
        if (request.getNotes() != null && !request.getNotes().trim().isEmpty()) {
            description += " - " + request.getNotes().trim();
        }

        Instant effectiveAt = request.getOpeningDate() != null ? request.getOpeningDate() : Instant.now();

        LedgerTransaction tx = new LedgerTransaction(
                customer.getId(),
                TransactionType.OPENING_BALANCE,
                request.getAmountPaise(),
                balanceEffect,
                effectiveAt,
                actor.getUsername(),
                idempotencyKey != null && !idempotencyKey.trim().isEmpty() ? idempotencyKey.trim() : null,
                description
        );

        LedgerTransaction saved = transactionRepository.save(tx);

        auditService.logEvent(actor.getId(), actor.getUsername(), "OPENING_BALANCE_IMPORTED",
                "TRANSACTION", saved.getId(), "Imported opening debt: " + CurrencyUtil.formatInr(saved.getAmountPaise()),
                Map.of("previousBalancePaise", previousBalance),
                Map.of("updatedBalancePaise", updatedBalance), null);

        TransactionResponse response = new TransactionResponse();
        response.setTransactionId(saved.getId());
        response.setCustomerId(customer.getId());
        response.setCustomerName(customer.getName());
        response.setType(saved.getType());
        response.setAmountPaise(saved.getAmountPaise());
        response.setBalanceEffectPaise(saved.getBalanceEffectPaise());
        response.setPreviousBalancePaise(previousBalance);
        response.setUpdatedBalancePaise(updatedBalance);
        response.setCreatedAt(saved.getCreatedAt());
        response.setTeluguSpeechMessage(customer.getName() + " గారి పాత బాకీ " +
                CurrencyUtil.toTeluguRupeesString(saved.getAmountPaise()) + " నమోదు చేయబడింది.");

        return response;
    }

    /**
     * Strictly cancels a prior transaction effect by creating a compensating REVERSAL transaction.
     * Invariant:
     * - Original transaction is preserved with hasReversal=true and linked to the reversal.
     * - Reversal has balanceEffectPaise = -1 * orig.balanceEffectPaise.
     * - Sum of all transactions yields (+X - X = 0), canceling exactly once without double counting.
     */
    @Transactional
    public TransactionResponse reverseTransaction(String transactionId, ReverseTransactionRequest request, UserPrincipal actor) {
        LedgerTransaction origTx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new IllegalArgumentException("Transaction not found: " + transactionId));

        if (origTx.isHasReversal()) {
            throw new IllegalStateException("Transaction has already been reversed by: " + origTx.getReversalTransactionId());
        }

        if (origTx.getType() == TransactionType.REVERSAL) {
            throw new IllegalStateException("Cannot reverse a reversal transaction");
        }

        Customer customer = customerRepository.findById(origTx.getCustomerId())
                .orElseThrow(() -> new IllegalArgumentException("Customer not found: " + origTx.getCustomerId()));

        long previousBalance = calculateOutstandingBalancePaise(customer.getId());
        long reversalBalanceEffect = -1 * origTx.getBalanceEffectPaise();
        long updatedBalance = previousBalance + reversalBalanceEffect;

        LedgerTransaction reversalTx = new LedgerTransaction();
        reversalTx.setCustomerId(origTx.getCustomerId());
        reversalTx.setType(TransactionType.REVERSAL);
        reversalTx.setAmountPaise(origTx.getAmountPaise());
        reversalTx.setBalanceEffectPaise(reversalBalanceEffect);
        reversalTx.setEffectiveAt(Instant.now());
        reversalTx.setCreatedAt(Instant.now());
        reversalTx.setCreatedBy(actor.getUsername());
        reversalTx.setDescription("Reversal of transaction " + origTx.getId() + ": " + request.getReason());
        reversalTx.setCorrectionReason(request.getReason());
        reversalTx.setReversesTransactionId(origTx.getId());
        reversalTx.setStatus(TransactionStatus.POSTED);

        LedgerTransaction savedReversal = transactionRepository.save(reversalTx);

        // Update original transaction linkage
        origTx.setHasReversal(true);
        origTx.setReversalTransactionId(savedReversal.getId());
        transactionRepository.save(origTx);

        auditService.logEvent(actor.getId(), actor.getUsername(), "TRANSACTION_REVERSED",
                "TRANSACTION", origTx.getId(), "Reversal created. Reason: " + request.getReason(),
                Map.of("originalTxId", origTx.getId(), "previousBalancePaise", previousBalance),
                Map.of("reversalTxId", savedReversal.getId(), "updatedBalancePaise", updatedBalance), null);

        TransactionResponse response = new TransactionResponse();
        response.setTransactionId(savedReversal.getId());
        response.setCustomerId(customer.getId());
        response.setCustomerName(customer.getName());
        response.setType(savedReversal.getType());
        response.setAmountPaise(savedReversal.getAmountPaise());
        response.setBalanceEffectPaise(savedReversal.getBalanceEffectPaise());
        response.setPreviousBalancePaise(previousBalance);
        response.setUpdatedBalancePaise(updatedBalance);
        response.setCreatedAt(savedReversal.getCreatedAt());
        response.setTeluguSpeechMessage(TeluguVoiceUtil.buildReversalResponse(customer.getName(), updatedBalance));

        return response;
    }

    public Page<TransactionDto> getCustomerTransactions(String customerId, Pageable pageable) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found: " + customerId));

        Page<LedgerTransaction> page = transactionRepository.findByCustomerIdOrderByEffectiveAtDesc(customerId, pageable);
        return page.map(tx -> new TransactionDto(tx, customer.getName()));
    }

    private Customer getActiveCustomer(String customerId) {
        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found with ID: " + customerId));
        return customer;
    }

    private TransactionResponse buildReplayResponse(LedgerTransaction tx, Customer customer) {
        long currentBalance = calculateOutstandingBalancePaise(customer.getId());
        TransactionResponse response = new TransactionResponse();
        response.setTransactionId(tx.getId());
        response.setCustomerId(customer.getId());
        response.setCustomerName(customer.getName());
        response.setType(tx.getType());
        response.setAmountPaise(tx.getAmountPaise());
        response.setBalanceEffectPaise(tx.getBalanceEffectPaise());
        response.setPreviousBalancePaise(currentBalance - tx.getBalanceEffectPaise());
        response.setUpdatedBalancePaise(currentBalance);
        response.setCreatedAt(tx.getCreatedAt());
        response.setDuplicateReplay(true);
        response.setTeluguSpeechMessage("గమనిక: ఈ లావాదేవీ ముందే నమోదైంది. ప్రస్తుత మొత్తం బాకీ " +
                CurrencyUtil.toTeluguRupeesString(currentBalance) + ".");
        return response;
    }
}
