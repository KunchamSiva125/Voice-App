package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.Role;
import com.tiffin.ledger.domain.User;
import com.tiffin.ledger.dto.auth.UserDto;
import com.tiffin.ledger.repository.UserRepository;
import com.tiffin.ledger.security.UserPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuditService auditService;

    public UserService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       AuditService auditService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.auditService = auditService;
    }

    public List<UserDto> getAllUsers() {
        return userRepository.findAll().stream()
                .map(UserDto::new)
                .collect(Collectors.toList());
    }

    public UserDto createUser(String name, String username, String rawPassword, Role role, UserPrincipal actor) {
        String cleanUsername = username.trim().toLowerCase();
        if (userRepository.existsByUsername(cleanUsername)) {
            throw new IllegalArgumentException("Username already exists: " + cleanUsername);
        }

        User user = new User();
        user.setName(name.trim());
        user.setUsername(cleanUsername);
        user.setPasswordHash(passwordEncoder.encode(rawPassword));
        user.setRole(role != null ? role : Role.FAMILY_MEMBER);
        user.setActive(true);
        user.setCreatedAt(Instant.now());
        user.setUpdatedAt(Instant.now());

        User saved = userRepository.save(user);

        auditService.logEvent(actor.getId(), actor.getUsername(), "USER_CREATED",
                "USER", saved.getId(), "Created user with role: " + saved.getRole(),
                null, null, null);

        return new UserDto(saved);
    }

    public UserDto toggleUserActive(String userId, boolean active, UserPrincipal actor) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        // Prevent deactivating the last active OWNER
        if (!active && user.getRole() == Role.OWNER) {
            long activeOwners = userRepository.findByRole(Role.OWNER).stream().filter(User::isActive).count();
            if (activeOwners <= 1) {
                throw new IllegalStateException("Cannot deactivate the only active OWNER account");
            }
        }

        user.setActive(active);
        user.setUpdatedAt(Instant.now());
        User saved = userRepository.save(user);

        auditService.logEvent(actor.getId(), actor.getUsername(), "USER_STATUS_CHANGED",
                "USER", saved.getId(), "Changed active status to: " + active,
                null, null, null);

        return new UserDto(saved);
    }
}
