package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.Customer;
import com.tiffin.ledger.domain.CustomerStatus;
import com.tiffin.ledger.domain.LedgerTransaction;
import com.tiffin.ledger.domain.TransactionType;
import com.tiffin.ledger.dto.report.DailyReportDto;
import com.tiffin.ledger.dto.report.OutstandingReportDto;
import com.tiffin.ledger.repository.CustomerRepository;
import com.tiffin.ledger.repository.LedgerTransactionRepository;
import com.tiffin.ledger.util.DateUtil;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReportServiceTest {

    @Mock
    private LedgerTransactionRepository transactionRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private LedgerService ledgerService;

    @InjectMocks
    private ReportService reportService;

    @Test
    @DisplayName("Daily Report uses Asia/Kolkata date and computes credits, collections, and debt")
    void testDailyReportCalculations() {
        LocalDate date = LocalDate.of(2026, 10, 20);

        LedgerTransaction credit1 = new LedgerTransaction("c1", TransactionType.CREDIT, 10000L, 10000L, Instant.now(), "staff", null, "Breakfast");
        LedgerTransaction payment1 = new LedgerTransaction("c2", TransactionType.PAYMENT, 8000L, -8000L, Instant.now(), "staff", null, "Paid");
        LedgerTransaction discount1 = new LedgerTransaction("c3", TransactionType.DISCOUNT, 2000L, -2000L, Instant.now(), "owner", null, "Waiver");

        when(transactionRepository.findByEffectiveAtBetween(any(Instant.class), any(Instant.class)))
                .thenReturn(List.of(credit1, payment1, discount1));

        Customer c1 = new Customer("Ramesh", "9848011111", null, "owner");
        c1.setId("c1");
        when(customerRepository.findByStatus(CustomerStatus.ACTIVE)).thenReturn(List.of(c1));
        when(ledgerService.calculateOutstandingBalancePaise("c1")).thenReturn(35000L);

        DailyReportDto report = reportService.getDailyReport(date);

        assertEquals(date, report.getBusinessDate());
        assertEquals(10000L, report.getTotalCreditsRecordedPaise());
        assertEquals(8000L, report.getTotalPaymentsCollectedPaise());
        assertEquals(2000L, report.getTotalDiscountsPaise());
        assertEquals(0L, report.getNetChangePaise(), "10000 credits - 8000 payments - 2000 discounts = 0 net change");
        assertEquals(35000L, report.getTotalOutstandingDebtPaise());
        assertTrue(report.getTeluguSummary().contains("80 రూపాయలు"));
    }

    @Test
    @DisplayName("Top Debtors report orders debtors descending by balance")
    void testOutstandingDebtReportTopDebtors() {
        Customer c1 = new Customer("Ramesh", null, null, "owner"); c1.setId("c1");
        Customer c2 = new Customer("Suresh", null, null, "owner"); c2.setId("c2");
        Customer c3 = new Customer("Venkatesh", null, null, "owner"); c3.setId("c3");

        when(customerRepository.findByStatus(CustomerStatus.ACTIVE)).thenReturn(List.of(c1, c2, c3));
        when(ledgerService.calculateOutstandingBalancePaise("c1")).thenReturn(15000L); // ₹150
        when(ledgerService.calculateOutstandingBalancePaise("c2")).thenReturn(50000L); // ₹500
        when(ledgerService.calculateOutstandingBalancePaise("c3")).thenReturn(20000L); // ₹200

        OutstandingReportDto report = reportService.getOutstandingDebtReport(5);

        assertEquals(85000L, report.getTotalOutstandingDebtPaise());
        assertEquals(3, report.getTotalDebtorsCount());
        // Highest debtor must be first (Suresh with ₹500)
        assertEquals("Suresh", report.getTopDebtors().get(0).getCustomerName());
        assertEquals(50000L, report.getTopDebtors().get(0).getBalancePaise());
        // Second is Venkatesh (₹200)
        assertEquals("Venkatesh", report.getTopDebtors().get(1).getCustomerName());
        // Third is Ramesh (₹150)
        assertEquals("Ramesh", report.getTopDebtors().get(2).getCustomerName());
    }
}
