package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.Role;
import com.tiffin.ledger.domain.User;
import com.tiffin.ledger.dto.auth.AuthRequest;
import com.tiffin.ledger.dto.auth.AuthResponse;
import com.tiffin.ledger.dto.auth.UserDto;
import com.tiffin.ledger.repository.UserRepository;
import com.tiffin.ledger.security.JwtTokenProvider;
import com.tiffin.ledger.security.UserPrincipal;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider tokenProvider;
    private final AuditService auditService;

    @Value("${app.bootstrap.owner-name:Apparao (Owner)}")
    private String bootstrapOwnerName;

    @Value("${app.bootstrap.owner-username:owner@tiffin.local}")
    private String bootstrapOwnerUsername;

    @Value("${app.bootstrap.owner-password:Password123!}")
    private String bootstrapOwnerPassword;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager,
                       JwtTokenProvider tokenProvider,
                       AuditService auditService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.tokenProvider = tokenProvider;
        this.auditService = auditService;
    }

    @PostConstruct
    public void initBootstrapUsers() {
        // Ensure ONLY the approved 3 system accounts exist
        ensureUser("Owner 1", "9014798120", "9014798120", Role.OWNER);
        ensureUser("Owner 2", "9949795364", "9949795364", Role.OWNER);
        ensureUser("Siva (Admin)", "siva", "Siva@1250", Role.ADMIN);

        // Remove outdated bootstrap/placeholder accounts if present
        userRepository.findByUsername("owner@tiffin.local").ifPresent(userRepository::delete);
        userRepository.findByUsername("admin@tiffin.local").ifPresent(userRepository::delete);
        userRepository.findByUsername("kalyan@tiffin.local").ifPresent(userRepository::delete);
    }

    private void ensureUser(String name, String username, String rawPassword, Role role) {
        String cleanUser = username.trim().toLowerCase();
        User user = userRepository.findByUsername(cleanUser).orElseGet(User::new);
        user.setName(name);
        user.setUsername(cleanUser);
        user.setPasswordHash(passwordEncoder.encode(rawPassword));
        user.setRole(role);
        user.setActive(true);
        if (user.getCreatedAt() == null) {
            user.setCreatedAt(Instant.now());
        }
        user.setUpdatedAt(Instant.now());
        userRepository.save(user);
        log.info("Synchronized user account: {} [{}]", cleanUser, role);
    }

    public AuthResponse login(AuthRequest request, String clientIp) {
        String cleanUsername = request.getUsername().trim().toLowerCase();
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(cleanUsername, request.getPassword())
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);
            UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();

            User user = userRepository.findById(principal.getId()).orElse(null);
            if (user != null) {
                user.setLastLoginAt(Instant.now());
                userRepository.save(user);
            }

            String token = tokenProvider.generateToken(principal);
            UserDto userDto = new UserDto(user);

            auditService.logEvent(principal.getId(), principal.getUsername(), "USER_LOGIN",
                    "USER", principal.getId(), "Successful login", null, null, clientIp);

            return new AuthResponse(token, tokenProvider.getExpirationMs(), userDto);
        } catch (BadCredentialsException e) {
            log.warn("Failed login attempt for username: {}", cleanUsername);
            throw new BadCredentialsException("Invalid username or password");
        }
    }

    public UserDto getCurrentUser(UserPrincipal principal) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + principal.getId()));
        return new UserDto(user);
    }
}
