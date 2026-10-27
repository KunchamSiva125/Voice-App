package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.Customer;
import com.tiffin.ledger.domain.CustomerStatus;
import com.tiffin.ledger.domain.LedgerTransaction;
import com.tiffin.ledger.dto.customer.CreateCustomerRequest;
import com.tiffin.ledger.dto.customer.CustomerDto;
import com.tiffin.ledger.dto.customer.UpdateCustomerRequest;
import com.tiffin.ledger.dto.transaction.ImportOpeningBalanceRequest;
import com.tiffin.ledger.repository.CustomerRepository;
import com.tiffin.ledger.repository.LedgerTransactionRepository;
import com.tiffin.ledger.security.UserPrincipal;
import com.tiffin.ledger.util.TeluguPhoneticMatcher;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Lazy;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class CustomerService {

    private static final Logger log = LoggerFactory.getLogger(CustomerService.class);

    private final CustomerRepository customerRepository;
    private final LedgerTransactionRepository transactionRepository;
    private final LedgerService ledgerService;
    private final AuditService auditService;

    public CustomerService(CustomerRepository customerRepository,
                           LedgerTransactionRepository transactionRepository,
                           @Lazy LedgerService ledgerService,
                           AuditService auditService) {
        this.customerRepository = customerRepository;
        this.transactionRepository = transactionRepository;
        this.ledgerService = ledgerService;
        this.auditService = auditService;
    }

    @PostConstruct
    public void syncSmartAliases() {
        try {
            List<Customer> allCustomers = customerRepository.findAll();
            int updatedCount = 0;
            for (Customer c : allCustomers) {
                List<String> current = c.getAliases() != null ? new ArrayList<>(c.getAliases()) : new ArrayList<>();
                List<String> generated = TeluguPhoneticMatcher.generateSmartAliases(c.getName());
                boolean changed = false;
                for (String g : generated) {
                    if (!current.contains(g)) {
                        current.add(g);
                        changed = true;
                    }
                }
                if (changed) {
                    c.setAliases(current);
                    customerRepository.save(c);
                    updatedCount++;
                }
            }
            if (updatedCount > 0) {
                log.info("Synchronized smart bilingual aliases for {} customer(s)", updatedCount);
            }
        } catch (Exception e) {
            log.warn("Could not synchronize customer smart aliases on startup: {}", e.getMessage());
        }

        try {
            List<Customer> allCustomers = customerRepository.findAll();
            int updatedBalances = 0;
            for (Customer c : allCustomers) {
                long trueBalance = ledgerService.calculateOutstandingBalancePaise(c.getId());
                if (c.getCurrentBalancePaise() != trueBalance) {
                    c.setCurrentBalancePaise(trueBalance);
                    customerRepository.save(c);
                    updatedBalances++;
                }
            }
            if (updatedBalances > 0) {
                log.info("Synchronized current balance for {} customer(s)", updatedBalances);
            }
        } catch (Exception e) {
            log.warn("Could not synchronize customer balances on startup: {}", e.getMessage());
        }
    }

    public Page<CustomerDto> listCustomers(String search, CustomerStatus status, Pageable pageable) {
        CustomerStatus targetStatus = status != null ? status : CustomerStatus.ACTIVE;
        Page<Customer> customers;

        if (search != null && !search.trim().isEmpty()) {
            customers = customerRepository.searchCustomers(targetStatus, search.trim(), pageable);
        } else {
            customers = customerRepository.findByStatus(targetStatus, pageable);
        }

        return customers.map(CustomerDto::new);
    }

    public CustomerDto getCustomerById(String id) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found with ID: " + id));
        return new CustomerDto(customer);
    }

    @Transactional
    public CustomerDto createCustomer(CreateCustomerRequest request, UserPrincipal actor) {
        String cleanName = request.getName().trim();

        // Check for potential duplicate name/phone
        if (request.getPhoneNumber() != null && !request.getPhoneNumber().trim().isEmpty()) {
            customerRepository.findByPhoneNumberAndStatus(request.getPhoneNumber().trim(), CustomerStatus.ACTIVE)
                    .ifPresent(existing -> {
                        throw new IllegalArgumentException("Another active customer already exists with phone number: " + request.getPhoneNumber());
                    });
        }

        Customer customer = new Customer(cleanName,
                request.getPhoneNumber() != null ? request.getPhoneNumber().trim() : null,
                request.getNotes() != null ? request.getNotes().trim() : null,
                actor.getUsername());

        List<String> aliases = request.getAliases() != null ? new ArrayList<>(request.getAliases()) : new ArrayList<>();
        List<String> smartAliases = TeluguPhoneticMatcher.generateSmartAliases(cleanName);
        for (String sa : smartAliases) {
            if (!aliases.contains(sa)) {
                aliases.add(sa);
            }
        }
        customer.setAliases(aliases);

        Customer saved = customerRepository.save(customer);

        // Record initial opening balance if specified
        if (request.getInitialOpeningBalancePaise() > 0) {
            ImportOpeningBalanceRequest importReq = new ImportOpeningBalanceRequest();
            importReq.setCustomerId(saved.getId());
            importReq.setAmountPaise(request.getInitialOpeningBalancePaise());
            importReq.setNotes("Initial opening balance on account creation");
            ledgerService.importOpeningBalance(importReq, actor, null);
        }

        long initialBalance = ledgerService.calculateOutstandingBalancePaise(saved.getId());

        auditService.logEvent(actor.getId(), actor.getUsername(), "CUSTOMER_CREATED",
                "CUSTOMER", saved.getId(), "Created customer: " + saved.getName(),
                null, Map.of("name", saved.getName(), "initialBalancePaise", initialBalance), null);

        return new CustomerDto(saved, initialBalance);
    }

    @Transactional
    public CustomerDto updateCustomer(String id, UpdateCustomerRequest request, UserPrincipal actor) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found: " + id));

        Map<String, Object> before = Map.of("name", customer.getName(), "status", customer.getStatus());

        if (request.getName() != null && !request.getName().trim().isEmpty()) {
            customer.setName(request.getName().trim());
        }
        if (request.getAliases() != null) {
            customer.setAliases(request.getAliases());
        }
        if (request.getPhoneNumber() != null) {
            customer.setPhoneNumber(request.getPhoneNumber().trim().isEmpty() ? null : request.getPhoneNumber().trim());
        }
        if (request.getNotes() != null) {
            customer.setNotes(request.getNotes().trim());
        }
        if (request.getStatus() != null) {
            customer.setStatus(request.getStatus());
        }

        customer.setUpdatedAt(Instant.now());
        customer.setUpdatedBy(actor.getUsername());

        Customer saved = customerRepository.save(customer);
        long balance = ledgerService.calculateOutstandingBalancePaise(saved.getId());

        auditService.logEvent(actor.getId(), actor.getUsername(), "CUSTOMER_UPDATED",
                "CUSTOMER", saved.getId(), "Updated customer profile",
                before, Map.of("name", saved.getName(), "status", saved.getStatus()), null);

        return new CustomerDto(saved, balance);
    }

    @Transactional
    public CustomerDto archiveCustomer(String id, UserPrincipal actor) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found: " + id));

        customer.setStatus(CustomerStatus.ARCHIVED);
        customer.setUpdatedAt(Instant.now());
        customer.setUpdatedBy(actor.getUsername());

        Customer saved = customerRepository.save(customer);
        long balance = ledgerService.calculateOutstandingBalancePaise(saved.getId());

        auditService.logEvent(actor.getId(), actor.getUsername(), "CUSTOMER_ARCHIVED",
                "CUSTOMER", saved.getId(), "Archived customer without deleting historical ledger records",
                null, null, null);

        return new CustomerDto(saved, balance);
    }

    /**
     * Resolves matching customers for voice input.
     * Matches across name, aliases (Telugu and English), phone, phonetic transliteration, and vowel stem variations.
     */
    public List<CustomerDto> matchCustomersForVoice(String spokenName) {
        if (spokenName == null || spokenName.trim().isEmpty()) {
            return List.of();
        }
        String clean = Customer.normalize(spokenName);

        // 1. Check exact/regex DB match first
        List<Customer> mongoMatches = customerRepository.matchByNameOrAlias(clean, clean);
        if (!mongoMatches.isEmpty()) {
            return mongoMatches.stream()
                    .filter(c -> c.getStatus() == CustomerStatus.ACTIVE)
                    .map(c -> new CustomerDto(c, ledgerService.calculateOutstandingBalancePaise(c.getId())))
                    .collect(Collectors.toList());
        }

        // 2. Comprehensive phonetic, bilingual, stem, and fuzzy matching across active customers
        List<Customer> activeCustomers = customerRepository.findByStatus(CustomerStatus.ACTIVE);

        class ScoredCustomer {
            final Customer customer;
            final int score;
            ScoredCustomer(Customer c, int s) { this.customer = c; this.score = s; }
        }

        List<ScoredCustomer> scored = new ArrayList<>();
        int maxScore = 0;
        for (Customer c : activeCustomers) {
            int score = TeluguPhoneticMatcher.calculateMatchScore(spokenName, c);
            if (score >= 80) {
                scored.add(new ScoredCustomer(c, score));
                if (score > maxScore) {
                    maxScore = score;
                }
            }
        }

        if (scored.isEmpty()) {
            return List.of();
        }

        // Keep top matches within 5 points of the top score
        final int threshold = Math.max(80, maxScore - 5);
        return scored.stream()
                .filter(sc -> sc.score >= threshold)
                .sorted((a, b) -> Integer.compare(b.score, a.score))
                .map(sc -> new CustomerDto(sc.customer, ledgerService.calculateOutstandingBalancePaise(sc.customer.getId())))
                .collect(Collectors.toList());
    }

    /**
     * Merge duplicate customer accounts (audited, OWNER only).
     * Reassigns all ledger transactions from sourceCustomer to targetCustomer.
     */
    @Transactional
    public CustomerDto mergeCustomers(String sourceCustomerId, String targetCustomerId, String reason, UserPrincipal actor) {
        if (sourceCustomerId.equals(targetCustomerId)) {
            throw new IllegalArgumentException("Source and target customer cannot be identical");
        }

        Customer source = customerRepository.findById(sourceCustomerId)
                .orElseThrow(() -> new IllegalArgumentException("Source customer not found: " + sourceCustomerId));
        Customer target = customerRepository.findById(targetCustomerId)
                .orElseThrow(() -> new IllegalArgumentException("Target customer not found: " + targetCustomerId));

        List<LedgerTransaction> sourceTxs = transactionRepository.findByCustomerIdOrderByEffectiveAtAsc(sourceCustomerId);
        for (LedgerTransaction tx : sourceTxs) {
            tx.setCustomerId(targetCustomerId);
            tx.setDescription(tx.getDescription() + " (Merged from " + source.getName() + " [" + source.getId() + "])");
            transactionRepository.save(tx);
        }

        // Archive source customer
        source.setStatus(CustomerStatus.ARCHIVED);
        source.setNotes(source.getNotes() + " [Merged into " + target.getName() + " on " + Instant.now() + "]");
        customerRepository.save(source);

        long updatedTargetBalance = ledgerService.calculateOutstandingBalancePaise(targetCustomerId);

        auditService.logEvent(actor.getId(), actor.getUsername(), "CUSTOMERS_MERGED",
                "CUSTOMER", targetCustomerId,
                "Merged source customer " + source.getName() + " (" + sourceCustomerId + ") into target. Reason: " + reason,
                Map.of("sourceCustomerId", sourceCustomerId, "txCount", sourceTxs.size()),
                Map.of("targetBalancePaise", updatedTargetBalance), null);

        return new CustomerDto(target, updatedTargetBalance);
    }

    @Transactional
    public void deleteCustomer(String id, UserPrincipal actor) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found: " + id));

        List<LedgerTransaction> txs = transactionRepository.findByCustomerIdOrderByEffectiveAtAsc(id);
        transactionRepository.deleteAll(txs);
        customerRepository.delete(customer);

        auditService.logEvent(actor.getId(), actor.getUsername(), "CUSTOMER_DELETED",
                "CUSTOMER", id, "Permanently deleted customer: " + customer.getName(),
                Map.of("deletedTxCount", txs.size()), null, null);
    }

    @Transactional
    public void purgeAllCustomers(UserPrincipal actor) {
        transactionRepository.deleteAll();
        customerRepository.deleteAll();
        auditService.logEvent(actor.getId(), actor.getUsername(), "ALL_CUSTOMERS_PURGED",
                "SYSTEM", "GLOBAL", "Purged all customers and ledger data for fresh production setup",
                null, null, null);
    }
}
