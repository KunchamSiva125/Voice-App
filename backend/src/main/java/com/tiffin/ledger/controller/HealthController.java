package com.tiffin.ledger.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
@Tag(name = "Health & Monitoring", description = "Liveness and operational readiness checks")
public class HealthController {

    @GetMapping
    @Operation(summary = "Check backend API health and server time")
    public ResponseEntity<Map<String, Object>> checkHealth() {
        return ResponseEntity.ok(Map.of(
                "status", "UP",
                "service", "Telugu Voice Tiffin Debt Management API",
                "version", "1.0.0",
                "serverTimeUtc", Instant.now().toString(),
                "timeZone", "Asia/Kolkata"
        ));
    }
}
