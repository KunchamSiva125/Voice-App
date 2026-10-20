package com.tiffin.ledger.controller;

import com.tiffin.ledger.domain.CustomerStatus;
import com.tiffin.ledger.dto.customer.CreateCustomerRequest;
import com.tiffin.ledger.dto.customer.CustomerBalanceDto;
import com.tiffin.ledger.dto.customer.CustomerDto;
import com.tiffin.ledger.dto.customer.UpdateCustomerRequest;
import com.tiffin.ledger.dto.transaction.TransactionDto;
import com.tiffin.ledger.security.UserPrincipal;
import com.tiffin.ledger.service.CustomerService;
import com.tiffin.ledger.service.LedgerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/customers")
@Tag(name = "Customers", description = "Customer profile management and debt tracking")
public class CustomerController {

    private final CustomerService customerService;
    private final LedgerService ledgerService;

    public CustomerController(CustomerService customerService, LedgerService ledgerService) {
        this.customerService = customerService;
        this.ledgerService = ledgerService;
    }

    @GetMapping
    @Operation(summary = "List and search customers by name, alias or phone")
    public ResponseEntity<Page<CustomerDto>> listCustomers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) CustomerStatus status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("name").ascending());
        return ResponseEntity.ok(customerService.listCustomers(search, status, pageable));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('OWNER', 'ADMIN')")
    @Operation(summary = "Create a new customer profile")
    public ResponseEntity<CustomerDto> createCustomer(
            @Valid @RequestBody CreateCustomerRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.status(HttpStatus.CREATED).body(customerService.createCustomer(request, principal));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get customer details and computed outstanding balance")
    public ResponseEntity<CustomerDto> getCustomer(@PathVariable String id) {
        return ResponseEntity.ok(customerService.getCustomerById(id));
    }

    @PatchMapping("/{id}")
    @PreAuthorize("hasAnyRole('OWNER', 'ADMIN')")
    @Operation(summary = "Update customer details (does not change financial balance)")
    public ResponseEntity<CustomerDto> updateCustomer(
            @PathVariable String id,
            @RequestBody UpdateCustomerRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(customerService.updateCustomer(id, request, principal));
    }

    @GetMapping("/{id}/balance")
    @Operation(summary = "Get detailed balance calculation and Telugu spoken response")
    public ResponseEntity<CustomerBalanceDto> getBalance(@PathVariable String id) {
        return ResponseEntity.ok(ledgerService.getCustomerBalanceDetails(id));
    }

    @GetMapping("/{id}/transactions")
    @Operation(summary = "Get dated ledger transaction history for a customer")
    public ResponseEntity<Page<TransactionDto>> getTransactions(
            @PathVariable String id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("effectiveAt").descending());
        return ResponseEntity.ok(ledgerService.getCustomerTransactions(id, pageable));
    }

    @PostMapping("/{id}/archive")
    @PreAuthorize("hasRole('OWNER')")
    @Operation(summary = "Archive customer without destroying ledger history")
    public ResponseEntity<CustomerDto> archiveCustomer(
            @PathVariable String id,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(customerService.archiveCustomer(id, principal));
    }

    @PostMapping("/merge")
    @PreAuthorize("hasRole('OWNER')")
    @Operation(summary = "Carefully merge duplicate customer profiles (OWNER only)")
    public ResponseEntity<CustomerDto> mergeCustomers(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserPrincipal principal) {
        String sourceId = body.get("sourceCustomerId");
        String targetId = body.get("targetCustomerId");
        String reason = body.getOrDefault("reason", "Duplicate customer profile merged");
        return ResponseEntity.ok(customerService.mergeCustomers(sourceId, targetId, reason, principal));
    }
}
