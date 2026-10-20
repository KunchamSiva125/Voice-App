package com.tiffin.ledger.controller;

import com.tiffin.ledger.domain.AuditEvent;
import com.tiffin.ledger.domain.Role;
import com.tiffin.ledger.dto.auth.UserDto;
import com.tiffin.ledger.security.UserPrincipal;
import com.tiffin.ledger.service.AuditService;
import com.tiffin.ledger.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('OWNER')")
@Tag(name = "Administration", description = "User roles, access management, and system audit trail (OWNER only)")
public class AdminUserController {

    private final UserService userService;
    private final AuditService auditService;

    public AdminUserController(UserService userService, AuditService auditService) {
        this.userService = userService;
        this.auditService = auditService;
    }

    @GetMapping("/users")
    @Operation(summary = "List all registered staff and family members")
    public ResponseEntity<List<UserDto>> listUsers() {
        return ResponseEntity.ok(userService.getAllUsers());
    }

    @PostMapping("/users")
    @Operation(summary = "Create an authorized user or family member")
    public ResponseEntity<UserDto> createUser(
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserPrincipal principal) {
        String name = body.get("name");
        String username = body.get("username");
        String password = body.get("password");
        Role role = Role.valueOf(body.getOrDefault("role", "FAMILY_MEMBER"));

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(userService.createUser(name, username, password, role, principal));
    }

    @PatchMapping("/users/{id}/status")
    @Operation(summary = "Activate or deactivate a user account")
    public ResponseEntity<UserDto> toggleUserStatus(
            @PathVariable String id,
            @RequestBody Map<String, Boolean> body,
            @AuthenticationPrincipal UserPrincipal principal) {
        boolean active = body.getOrDefault("active", true);
        return ResponseEntity.ok(userService.toggleUserActive(id, active, principal));
    }

    @GetMapping("/audit-events")
    @Operation(summary = "Inspect operational audit trail")
    public ResponseEntity<Page<AuditEvent>> getAuditEvents(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "25") int size) {
        Pageable pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(auditService.getAuditTrail(pageable));
    }
}
