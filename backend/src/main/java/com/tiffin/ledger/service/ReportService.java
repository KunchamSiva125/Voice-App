package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.Customer;
import com.tiffin.ledger.domain.CustomerStatus;
import com.tiffin.ledger.domain.LedgerTransaction;
import com.tiffin.ledger.domain.TransactionStatus;
import com.tiffin.ledger.domain.TransactionType;
import com.tiffin.ledger.dto.report.DailyReportDto;
import com.tiffin.ledger.dto.report.OutstandingReportDto;
import com.tiffin.ledger.dto.report.TopDebtorDto;
import com.tiffin.ledger.dto.transaction.TransactionDto;
import com.tiffin.ledger.repository.CustomerRepository;
import com.tiffin.ledger.repository.LedgerTransactionRepository;
import com.tiffin.ledger.util.DateUtil;
import com.tiffin.ledger.util.TeluguVoiceUtil;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ReportService {

    private final LedgerTransactionRepository transactionRepository;
    private final CustomerRepository customerRepository;
    private final LedgerService ledgerService;

    public ReportService(LedgerTransactionRepository transactionRepository,
                         CustomerRepository customerRepository,
                         LedgerService ledgerService) {
        this.transactionRepository = transactionRepository;
        this.customerRepository = customerRepository;
        this.ledgerService = ledgerService;
    }

    public DailyReportDto getDailyReport(LocalDate businessDate) {
        LocalDate date = businessDate != null ? businessDate : DateUtil.getTodayIst();
        Instant start = DateUtil.getStartOfDayIst(date);
        Instant end = DateUtil.getEndOfDayIst(date);

        List<LedgerTransaction> dayTxs = transactionRepository.findByEffectiveAtBetween(start, end);

        long creditsPaise = 0L;
        long paymentsPaise = 0L;
        long discountsPaise = 0L;
        long txCount = 0L;

        for (LedgerTransaction tx : dayTxs) {
            if (tx.getStatus() == TransactionStatus.POSTED) {
                txCount++;
                if (tx.getType() == TransactionType.CREDIT || tx.getType() == TransactionType.OPENING_BALANCE) {
                    creditsPaise += tx.getAmountPaise();
                } else if (tx.getType() == TransactionType.PAYMENT) {
                    paymentsPaise += tx.getAmountPaise();
                } else if (tx.getType() == TransactionType.DISCOUNT) {
                    discountsPaise += tx.getAmountPaise();
                }
            }
        }

        // Calculate overall outstanding debt across all active customers
        List<Customer> activeCustomers = customerRepository.findByStatus(CustomerStatus.ACTIVE);
        long totalOutstandingDebt = 0L;
        for (Customer c : activeCustomers) {
            long bal = ledgerService.calculateOutstandingBalancePaise(c.getId());
            if (bal > 0) {
                totalOutstandingDebt += bal;
            }
        }

        DailyReportDto dto = new DailyReportDto();
        dto.setBusinessDate(date);
        dto.setTotalCreditsRecordedPaise(creditsPaise);
        dto.setTotalPaymentsCollectedPaise(paymentsPaise);
        dto.setTotalDiscountsPaise(discountsPaise);
        dto.setNetChangePaise(creditsPaise - paymentsPaise - discountsPaise);
        dto.setTotalOutstandingDebtPaise(totalOutstandingDebt);
        dto.setActiveCustomersCount(activeCustomers.size());
        dto.setTransactionsCountToday(txCount);
        dto.setTeluguSummary(TeluguVoiceUtil.buildDailyReportResponse(paymentsPaise, creditsPaise));

        return dto;
    }

    public OutstandingReportDto getOutstandingDebtReport(int topCount) {
        List<Customer> activeCustomers = customerRepository.findByStatus(CustomerStatus.ACTIVE);
        long totalDebt = 0L;
        long debtorsCount = 0L;

        List<TopDebtorDto> debtors = new ArrayList<>();

        for (Customer c : activeCustomers) {
            long bal = ledgerService.calculateOutstandingBalancePaise(c.getId());
            if (bal > 0) {
                totalDebt += bal;
                debtorsCount++;
                debtors.add(new TopDebtorDto(c.getId(), c.getName(), c.getPhoneNumber(), bal));
            }
        }

        // Sort descending by outstanding debt
        debtors.sort((a, b) -> Long.compare(b.getBalancePaise(), a.getBalancePaise()));

        OutstandingReportDto dto = new OutstandingReportDto();
        dto.setTotalOutstandingDebtPaise(totalDebt);
        dto.setTotalDebtorsCount(debtorsCount);
        dto.setTopDebtors(debtors.stream().limit(Math.max(topCount, 5)).collect(Collectors.toList()));

        return dto;
    }

    public Page<TransactionDto> getTransactionsByDateRange(LocalDate startDate, LocalDate endDate, Pageable pageable) {
        LocalDate startD = startDate != null ? startDate : DateUtil.getTodayIst().minusDays(30);
        LocalDate endD = endDate != null ? endDate : DateUtil.getTodayIst();

        Instant start = DateUtil.getStartOfDayIst(startD);
        Instant end = DateUtil.getEndOfDayIst(endD);

        Page<LedgerTransaction> page = transactionRepository.findByEffectiveAtBetweenOrderByEffectiveAtDesc(start, end, pageable);

        Map<String, String> customerNameCache = new HashMap<>();
        return page.map(tx -> {
            String name = customerNameCache.computeIfAbsent(tx.getCustomerId(), cid ->
                    customerRepository.findById(cid).map(Customer::getName).orElse("Unknown"));
            return new TransactionDto(tx, name);
        });
    }
}
