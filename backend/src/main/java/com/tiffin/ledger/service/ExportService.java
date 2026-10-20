package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.Customer;
import com.tiffin.ledger.domain.CustomerStatus;
import com.tiffin.ledger.domain.LedgerTransaction;
import com.tiffin.ledger.repository.CustomerRepository;
import com.tiffin.ledger.repository.LedgerTransactionRepository;
import com.tiffin.ledger.util.CurrencyUtil;
import com.tiffin.ledger.util.DateUtil;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ExportService {

    private final CustomerRepository customerRepository;
    private final LedgerTransactionRepository transactionRepository;
    private final LedgerService ledgerService;

    public ExportService(CustomerRepository customerRepository,
                         LedgerTransactionRepository transactionRepository,
                         LedgerService ledgerService) {
        this.customerRepository = customerRepository;
        this.transactionRepository = transactionRepository;
        this.ledgerService = ledgerService;
    }

    public byte[] exportCustomersCsv() {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (PrintWriter writer = new PrintWriter(out, true, StandardCharsets.UTF_8)) {
            // Write BOM for Excel UTF-8 compatibility
            out.write(0xEF); out.write(0xBB); out.write(0xBF);

            writer.println("Customer ID,Name,Phone Number,Aliases,Status,Outstanding Debt (Paise),Outstanding Debt (INR),Notes");

            List<Customer> customers = customerRepository.findAll();
            for (Customer c : customers) {
                long balance = ledgerService.calculateOutstandingBalancePaise(c.getId());
                writer.printf("\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",%d,%.2f,\"%s\"%n",
                        c.getId(),
                        escapeCsv(c.getName()),
                        escapeCsv(c.getPhoneNumber() != null ? c.getPhoneNumber() : ""),
                        escapeCsv(String.join("; ", c.getAliases())),
                        c.getStatus(),
                        balance,
                        balance / 100.0,
                        escapeCsv(c.getNotes() != null ? c.getNotes() : "")
                );
            }
        } catch (Exception e) {
            throw new RuntimeException("Error exporting customers CSV", e);
        }
        return out.toByteArray();
    }

    public byte[] exportTransactionsCsv(LocalDate startDate, LocalDate endDate) {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        try (PrintWriter writer = new PrintWriter(out, true, StandardCharsets.UTF_8)) {
            out.write(0xEF); out.write(0xBB); out.write(0xBF);

            writer.println("Transaction ID,Effective Date (IST),Customer ID,Customer Name,Type,Amount (Paise),Amount (INR),Balance Effect (Paise),Status,Created By,Reversal Reference,Description");

            LocalDate start = startDate != null ? startDate : DateUtil.getTodayIst().minusMonths(3);
            LocalDate end = endDate != null ? endDate : DateUtil.getTodayIst();

            List<LedgerTransaction> txs = transactionRepository.findByEffectiveAtBetween(
                    DateUtil.getStartOfDayIst(start), DateUtil.getEndOfDayIst(end));

            Map<String, String> customerNames = new HashMap<>();
            for (Customer c : customerRepository.findAll()) {
                customerNames.put(c.getId(), c.getName());
            }

            for (LedgerTransaction tx : txs) {
                String custName = customerNames.getOrDefault(tx.getCustomerId(), "Unknown");
                writer.printf("\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",%d,%.2f,%d,\"%s\",\"%s\",\"%s\",\"%s\"%n",
                        tx.getId(),
                        tx.getEffectiveAt(),
                        tx.getCustomerId(),
                        escapeCsv(custName),
                        tx.getType(),
                        tx.getAmountPaise(),
                        tx.getAmountPaise() / 100.0,
                        tx.getBalanceEffectPaise(),
                        tx.getStatus(),
                        escapeCsv(tx.getCreatedBy()),
                        escapeCsv(tx.getReversesTransactionId() != null ? tx.getReversesTransactionId() : ""),
                        escapeCsv(tx.getDescription() != null ? tx.getDescription() : "")
                );
            }
        } catch (Exception e) {
            throw new RuntimeException("Error exporting transactions CSV", e);
        }
        return out.toByteArray();
    }

    private String escapeCsv(String input) {
        if (input == null) return "";
        return input.replace("\"", "\"\"");
    }
}
