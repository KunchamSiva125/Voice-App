package com.tiffin.ledger.controller;

import com.tiffin.ledger.dto.report.DailyReportDto;
import com.tiffin.ledger.dto.report.OutstandingReportDto;
import com.tiffin.ledger.dto.transaction.TransactionDto;
import com.tiffin.ledger.service.ReportService;
import com.tiffin.ledger.util.DateUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/reports")
@PreAuthorize("hasAnyRole('OWNER', 'ADMIN')")
@Tag(name = "Reports", description = "Daily summaries, outstanding debt analytics, and range reports")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/daily")
    @Operation(summary = "Get daily business summary in Asia/Kolkata date context")
    public ResponseEntity<DailyReportDto> getDailyReport(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(reportService.getDailyReport(date));
    }

    @GetMapping("/outstanding")
    @Operation(summary = "Get total outstanding debt aging and top debtors")
    public ResponseEntity<OutstandingReportDto> getOutstandingReport(
            @RequestParam(defaultValue = "10") int top) {
        return ResponseEntity.ok(reportService.getOutstandingDebtReport(top));
    }

    @GetMapping("/transactions")
    @Operation(summary = "Get ledger transactions over a selected date range")
    public ResponseEntity<Page<TransactionDto>> getTransactionsByRange(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(reportService.getTransactionsByDateRange(startDate, endDate, pageable));
    }
}
