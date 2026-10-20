package com.tiffin.ledger.dto.auth;

import com.tiffin.ledger.domain.Role;
import com.tiffin.ledger.domain.User;

public class UserDto {
    private String id;
    private String name;
    private String username;
    private Role role;
    private boolean active;

    public UserDto() {}
    public UserDto(User user) {
        if (user != null) {
            this.id = user.getId();
            this.name = user.getName();
            this.username = user.getUsername();
            this.role = user.getRole();
            this.active = user.isActive();
        }
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }
}
