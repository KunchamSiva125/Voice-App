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
import org.springframework.context.annotation.Lazy;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CustomerService {

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

    public Page<CustomerDto> listCustomers(String search, CustomerStatus status, Pageable pageable) {
        CustomerStatus targetStatus = status != null ? status : CustomerStatus.ACTIVE;
        Page<Customer> customers;

        if (search != null && !search.trim().isEmpty()) {
            customers = customerRepository.searchCustomers(targetStatus, search.trim(), pageable);
        } else {
            customers = customerRepository.findByStatus(targetStatus, pageable);
        }

        return customers.map(c -> {
            long balance = ledgerService.calculateOutstandingBalancePaise(c.getId());
            return new CustomerDto(c, balance);
        });
    }

    public CustomerDto getCustomerById(String id) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Customer not found with ID: " + id));
        long balance = ledgerService.calculateOutstandingBalancePaise(customer.getId());
        return new CustomerDto(customer, balance);
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

        if (request.getAliases() != null && !request.getAliases().isEmpty()) {
            customer.setAliases(request.getAliases());
        }

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
     * Matches across name, aliases (Telugu and English), and phone.
     */
    public List<CustomerDto> matchCustomersForVoice(String spokenName) {
        if (spokenName == null || spokenName.trim().isEmpty()) {
            return List.of();
        }
        String clean = Customer.normalize(spokenName);
        List<Customer> matches = customerRepository.matchByNameOrAlias(clean, clean);

        return matches.stream()
                .filter(c -> c.getStatus() == CustomerStatus.ACTIVE)
                .map(c -> {
                    long balance = ledgerService.calculateOutstandingBalancePaise(c.getId());
                    return new CustomerDto(c, balance);
                })
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
}
