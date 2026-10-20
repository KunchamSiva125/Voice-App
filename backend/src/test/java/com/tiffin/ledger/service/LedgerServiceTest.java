package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.*;
import com.tiffin.ledger.dto.transaction.*;
import com.tiffin.ledger.exception.ExcessPaymentException;
import com.tiffin.ledger.repository.CustomerRepository;
import com.tiffin.ledger.repository.LedgerTransactionRepository;
import com.tiffin.ledger.security.UserPrincipal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LedgerServiceTest {

    @Mock
    private LedgerTransactionRepository transactionRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private AuditService auditService;

    @InjectMocks
    private LedgerService ledgerService;

    private Customer testCustomer;
    private UserPrincipal testUser;

    @BeforeEach
    void setUp() {
        testCustomer = new Customer("Ramesh", "9848011111", "Regular", "owner");
        testCustomer.setId("cust_ramesh_001");

        User user = new User("usr_01", "Apparao", "owner@tiffin.local", "hashed", Role.OWNER);
        testUser = new UserPrincipal(user);
    }

    @Test
    @DisplayName("Financial Rule: Opening balance is included correctly")
    void testCalculateBalance_IncludesOpeningBalance() {
        LedgerTransaction op = new LedgerTransaction("cust_ramesh_001", TransactionType.OPENING_BALANCE,
                25000L, 25000L, Instant.now(), "owner", "idemp_1", "Opening notebook debt");

        when(transactionRepository.findByCustomerIdOrderByEffectiveAtAsc("cust_ramesh_001"))
                .thenReturn(List.of(op));

        long balance = ledgerService.calculateOutstandingBalancePaise("cust_ramesh_001");
        assertEquals(25000L, balance, "Balance must equal ₹250 (25000 paise)");
    }

    @Test
    @DisplayName("Scenario 1: Customer owes ₹250. Add ₹100 credit. Expected balance: ₹350.")
    void testScenario1_AddCreditIncreasesBalance() {
        // Mock current opening balance of ₹250
        LedgerTransaction op = new LedgerTransaction("cust_ramesh_001", TransactionType.OPENING_BALANCE,
                25000L, 25000L, Instant.now(), "owner", "idemp_1", "Opening");

        when(customerRepository.findById("cust_ramesh_001")).thenReturn(Optional.of(testCustomer));
        when(transactionRepository.findByCustomerIdOrderByEffectiveAtAsc("cust_ramesh_001"))
                .thenReturn(List.of(op));
        when(transactionRepository.save(any(LedgerTransaction.class))).thenAnswer(i -> {
            LedgerTransaction tx = i.getArgument(0);
            tx.setId("tx_credit_100");
            return tx;
        });

        RecordCreditRequest request = new RecordCreditRequest("cust_ramesh_001", 10000L, "2 Idli + Vada");
        TransactionResponse response = ledgerService.recordCredit(request, testUser, "idemp_credit_1");

        assertNotNull(response);
        assertEquals(10000L, response.getAmountPaise());
        assertEquals(10000L, response.getBalanceEffectPaise());
        assertEquals(25000L, response.getPreviousBalancePaise());
        assertEquals(35000L, response.getUpdatedBalancePaise(), "Expected balance is ₹350 (35000 paise)");
        assertTrue(response.getTeluguSpeechMessage().contains("350 రూపాయలు"));
    }

    @Test
    @DisplayName("Scenario 2: Record a ₹100 payment. Expected balance: ₹250.")
    void testScenario2_RecordPaymentDecreasesBalance() {
        // Customer previously had ₹350 debt
        LedgerTransaction op = new LedgerTransaction("cust_ramesh_001", TransactionType.OPENING_BALANCE,
                25000L, 25000L, Instant.now(), "owner", null, "Opening");
        LedgerTransaction cr = new LedgerTransaction("cust_ramesh_001", TransactionType.CREDIT,
                10000L, 10000L, Instant.now(), "owner", null, "Credit");

        when(customerRepository.findById("cust_ramesh_001")).thenReturn(Optional.of(testCustomer));
        when(transactionRepository.findByCustomerIdOrderByEffectiveAtAsc("cust_ramesh_001"))
                .thenReturn(List.of(op, cr));
        when(transactionRepository.save(any(LedgerTransaction.class))).thenAnswer(i -> {
            LedgerTransaction tx = i.getArgument(0);
            tx.setId("tx_pay_100");
            return tx;
        });

        RecordPaymentRequest request = new RecordPaymentRequest("cust_ramesh_001", 10000L, "Paid cash");
        TransactionResponse response = ledgerService.recordPayment(request, testUser, "idemp_pay_1");

        assertNotNull(response);
        assertEquals(10000L, response.getAmountPaise());
        assertEquals(-10000L, response.getBalanceEffectPaise());
        assertEquals(35000L, response.getPreviousBalancePaise());
        assertEquals(25000L, response.getUpdatedBalancePaise(), "Expected balance is ₹250 (25000 paise)");
    }

    @Test
    @DisplayName("Scenario 3: Apply a ₹50 discount. Expected balance: ₹200.")
    void testScenario3_ApplyDiscountDecreasesBalance() {
        LedgerTransaction op = new LedgerTransaction("cust_ramesh_001", TransactionType.OPENING_BALANCE,
                25000L, 25000L, Instant.now(), "owner", null, "Opening");

        when(customerRepository.findById("cust_ramesh_001")).thenReturn(Optional.of(testCustomer));
        when(transactionRepository.findByCustomerIdOrderByEffectiveAtAsc("cust_ramesh_001"))
                .thenReturn(List.of(op));
        when(transactionRepository.save(any(LedgerTransaction.class))).thenAnswer(i -> {
            LedgerTransaction tx = i.getArgument(0);
            tx.setId("tx_disc_50");
            return tx;
        });

        ApplyDiscountRequest request = new ApplyDiscountRequest();
        request.setCustomerId("cust_ramesh_001");
        request.setAmountPaise(5000L); // ₹50
        request.setReason("Owner festival waiver");

        TransactionResponse response = ledgerService.applyDiscount(request, testUser, "idemp_disc_1");

        assertNotNull(response);
        assertEquals(5000L, response.getAmountPaise());
        assertEquals(-5000L, response.getBalanceEffectPaise());
        assertEquals(25000L, response.getPreviousBalancePaise());
        assertEquals(20000L, response.getUpdatedBalancePaise(), "Expected balance is ₹200 (20000 paise)");
    }

    @Test
    @DisplayName("Scenario 4: Idempotency - duplicate submission returns original without re-entry")
    void testScenario4_DuplicateIdempotencyKeyReturnsOriginal() {
        LedgerTransaction existing = new LedgerTransaction("cust_ramesh_001", TransactionType.PAYMENT,
                10000L, -10000L, Instant.now(), "owner", "dup_key_123", "Payment");
        existing.setId("tx_orig_999");

        when(customerRepository.findById("cust_ramesh_001")).thenReturn(Optional.of(testCustomer));
        when(transactionRepository.findByIdempotencyKey("dup_key_123")).thenReturn(Optional.of(existing));
        when(transactionRepository.findByCustomerIdOrderByEffectiveAtAsc("cust_ramesh_001"))
                .thenReturn(List.of(existing));

        RecordPaymentRequest request = new RecordPaymentRequest("cust_ramesh_001", 10000L, "Payment");
        TransactionResponse response = ledgerService.recordPayment(request, testUser, "dup_key_123");

        assertNotNull(response);
        assertEquals("tx_orig_999", response.getTransactionId());
        assertTrue(response.isDuplicateReplay(), "Must flag as duplicate replay");
        verify(transactionRepository, never()).save(any());
    }

    @Test
    @DisplayName("Scenario 5: Reversal cancels original transaction effect exactly once (Zero-Sum Invariant)")
    void testScenario5_ReversalCancelsOriginalTransactionExactlyOnce() {
        // Original Credit of ₹100
        LedgerTransaction origCredit = new LedgerTransaction("cust_ramesh_001", TransactionType.CREDIT,
                10000L, 10000L, Instant.now(), "owner", null, "Erroneous credit");
        origCredit.setId("tx_err_100");

        when(transactionRepository.findById("tx_err_100")).thenReturn(Optional.of(origCredit));
        when(customerRepository.findById("cust_ramesh_001")).thenReturn(Optional.of(testCustomer));
        when(transactionRepository.findByCustomerIdOrderByEffectiveAtAsc("cust_ramesh_001"))
                .thenReturn(List.of(origCredit));

        when(transactionRepository.save(any(LedgerTransaction.class))).thenAnswer(i -> {
            LedgerTransaction tx = i.getArgument(0);
            if (tx.getId() == null) tx.setId("tx_reversal_200");
            return tx;
        });

        ReverseTransactionRequest revRequest = new ReverseTransactionRequest("Mistaken credit entry by cashier");
        TransactionResponse response = ledgerService.reverseTransaction("tx_err_100", revRequest, testUser);

        assertNotNull(response);
        assertEquals(TransactionType.REVERSAL, response.getType());
        assertEquals(-10000L, response.getBalanceEffectPaise(), "Reversal balance effect must be -1 * original");
        assertEquals(0L, response.getUpdatedBalancePaise(), "Net balance must return to 0 (100 - 100 = 0)");

        // Original transaction must be linked and marked hasReversal=true
        assertTrue(origCredit.isHasReversal());
        assertEquals("tx_reversal_200", origCredit.getReversalTransactionId());
    }

    @Test
    @DisplayName("Safety Rule: Excess payment requires explicit advance confirmation")
    void testExcessPaymentThrowsExceptionWhenUnconfirmed() {
        // Customer owes ₹100
        LedgerTransaction cr = new LedgerTransaction("cust_ramesh_001", TransactionType.CREDIT,
                10000L, 10000L, Instant.now(), "owner", null, "Credit");

        when(customerRepository.findById("cust_ramesh_001")).thenReturn(Optional.of(testCustomer));
        when(transactionRepository.findByCustomerIdOrderByEffectiveAtAsc("cust_ramesh_001"))
                .thenReturn(List.of(cr));

        // Customer attempts to pay ₹150 without allowExcessAsAdvance flag
        RecordPaymentRequest request = new RecordPaymentRequest("cust_ramesh_001", 15000L, "Payment");
        request.setAllowExcessAsAdvance(false);

        ExcessPaymentException ex = assertThrows(ExcessPaymentException.class, () ->
                ledgerService.recordPayment(request, testUser, "key_ex_1"));

        assertEquals(5000L, ex.getExcessAmountPaise());
        assertTrue(ex.getMessageTelugu().contains("అడ్వాన్స్‌గా జమ చేయాలా"));
    }

    @Test
    @DisplayName("Validation: Zero or negative credit amounts are rejected")
    void testZeroAndNegativeAmountsRejected() {
        when(customerRepository.findById("cust_ramesh_001")).thenReturn(Optional.of(testCustomer));

        RecordCreditRequest zeroReq = new RecordCreditRequest("cust_ramesh_001", 0L, "Zero");
        assertThrows(IllegalArgumentException.class, () ->
                ledgerService.recordCredit(zeroReq, testUser, null));

        RecordCreditRequest negReq = new RecordCreditRequest("cust_ramesh_001", -500L, "Negative");
        assertThrows(IllegalArgumentException.class, () ->
                ledgerService.recordCredit(negReq, testUser, null));
    }
}
