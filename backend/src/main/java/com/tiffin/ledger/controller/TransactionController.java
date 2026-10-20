package com.tiffin.ledger.controller;

import com.tiffin.ledger.dto.transaction.*;
import com.tiffin.ledger.security.UserPrincipal;
import com.tiffin.ledger.service.LedgerService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/transactions")
@Tag(name = "Transactions & Ledger", description = "Financial credit entries, payments, discounts, and zero-sum reversals")
public class TransactionController {

    private final LedgerService ledgerService;

    public TransactionController(LedgerService ledgerService) {
        this.ledgerService = ledgerService;
    }

    @PostMapping("/credit")
    @Operation(summary = "Record customer credit (appu/బాకీ) - debt increases")
    public ResponseEntity<TransactionResponse> recordCredit(
            @Valid @RequestBody RecordCreditRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ledgerService.recordCredit(request, principal, idempotencyKey));
    }

    @PostMapping("/payment")
    @Operation(summary = "Record customer payment - debt decreases")
    public ResponseEntity<TransactionResponse> recordPayment(
            @Valid @RequestBody RecordPaymentRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ledgerService.recordPayment(request, principal, idempotencyKey));
    }

    @PostMapping("/discount")
    @PreAuthorize("hasAnyRole('OWNER', 'ADMIN')")
    @Operation(summary = "Apply intentional debt waiver or discount (OWNER/ADMIN only)")
    public ResponseEntity<TransactionResponse> applyDiscount(
            @Valid @RequestBody ApplyDiscountRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ledgerService.applyDiscount(request, principal, idempotencyKey));
    }

    @PostMapping("/opening-balance")
    @PreAuthorize("hasRole('OWNER')")
    @Operation(summary = "Import opening debt migrated from physical notebook (OWNER only)")
    public ResponseEntity<TransactionResponse> importOpeningBalance(
            @Valid @RequestBody ImportOpeningBalanceRequest request,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ledgerService.importOpeningBalance(request, principal, idempotencyKey));
    }

    @PostMapping("/{id}/reverse")
    @PreAuthorize("hasAnyRole('OWNER', 'ADMIN')")
    @Operation(summary = "Cancel an erroneous transaction via a zero-sum reversal (OWNER/ADMIN only)")
    public ResponseEntity<TransactionResponse> reverseTransaction(
            @PathVariable String id,
            @Valid @RequestBody ReverseTransactionRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(ledgerService.reverseTransaction(id, request, principal));
    }
}
