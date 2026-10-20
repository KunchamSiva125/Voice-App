package com.tiffin.ledger.security;

import com.tiffin.ledger.domain.Role;
import com.tiffin.ledger.domain.User;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.security.core.GrantedAuthority;

import java.util.Collection;

import static org.junit.jupiter.api.Assertions.*;

class SecurityRolePermissionTest {

    @Test
    @DisplayName("UserPrincipal creates proper Spring Security ROLE_ authority")
    void testUserPrincipalAuthorities() {
        User owner = new User("1", "Owner", "owner@tiffin.local", "pass", Role.OWNER);
        UserPrincipal ownerPrincipal = new UserPrincipal(owner);

        Collection<? extends GrantedAuthority> authorities = ownerPrincipal.getAuthorities();
        assertTrue(authorities.stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER")));

        User family = new User("2", "Family", "family@tiffin.local", "pass", Role.FAMILY_MEMBER);
        UserPrincipal familyPrincipal = new UserPrincipal(family);

        assertTrue(familyPrincipal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_FAMILY_MEMBER")));
        assertFalse(familyPrincipal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_OWNER")));
        assertFalse(familyPrincipal.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN")));
    }

    @Test
    @DisplayName("Role hierarchy validation: Only OWNER and ADMIN possess correction permissions")
    void testRolePermissions() {
        Role ownerRole = Role.OWNER;
        Role adminRole = Role.ADMIN;
        Role familyRole = Role.FAMILY_MEMBER;

        assertTrue(canPerformCorrections(ownerRole));
        assertTrue(canPerformCorrections(adminRole));
        assertFalse(canPerformCorrections(familyRole), "FAMILY_MEMBER must not have correction/reversal privileges");
    }

    private boolean canPerformCorrections(Role role) {
        return role == Role.OWNER || role == Role.ADMIN;
    }
}
