package com.tiffin.ledger.domain;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

@Document(collection = "auditEvents")
public class AuditEvent {

    @Id
    private String id;

    @Indexed
    private String actorUserId;

    private String actorUsername;

    private String action; // e.g. TRANSACTION_CREATED, TRANSACTION_REVERSED, CUSTOMER_CREATED, OPENING_BALANCE_IMPORTED

    @Indexed
    private String entityType; // e.g. TRANSACTION, CUSTOMER, USER

    @Indexed
    private String entityId;

    @Indexed
    private Instant occurredAt = Instant.now();

    private String reason;

    private Map<String, Object> beforeSnapshot = new HashMap<>();

    private Map<String, Object> afterSnapshot = new HashMap<>();

    private String requestId;

    private String clientIp;

    private Map<String, Object> metadata = new HashMap<>();

    public AuditEvent() {
    }

    public AuditEvent(String actorUserId, String actorUsername, String action,
                      String entityType, String entityId, String reason) {
        this.actorUserId = actorUserId;
        this.actorUsername = actorUsername;
        this.action = action;
        this.entityType = entityType;
        this.entityId = entityId;
        this.reason = reason;
        this.occurredAt = Instant.now();
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getActorUserId() { return actorUserId; }
    public void setActorUserId(String actorUserId) { this.actorUserId = actorUserId; }

    public String getActorUsername() { return actorUsername; }
    public void setActorUsername(String actorUsername) { this.actorUsername = actorUsername; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getEntityType() { return entityType; }
    public void setEntityType(String entityType) { this.entityType = entityType; }

    public String getEntityId() { return entityId; }
    public void setEntityId(String entityId) { this.entityId = entityId; }

    public Instant getOccurredAt() { return occurredAt; }
    public void setOccurredAt(Instant occurredAt) { this.occurredAt = occurredAt; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public Map<String, Object> getBeforeSnapshot() { return beforeSnapshot; }
    public void setBeforeSnapshot(Map<String, Object> beforeSnapshot) {
        this.beforeSnapshot = beforeSnapshot != null ? beforeSnapshot : new HashMap<>();
    }

    public Map<String, Object> getAfterSnapshot() { return afterSnapshot; }
    public void setAfterSnapshot(Map<String, Object> afterSnapshot) {
        this.afterSnapshot = afterSnapshot != null ? afterSnapshot : new HashMap<>();
    }

    public String getRequestId() { return requestId; }
    public void setRequestId(String requestId) { this.requestId = requestId; }

    public String getClientIp() { return clientIp; }
    public void setClientIp(String clientIp) { this.clientIp = clientIp; }

    public Map<String, Object> getMetadata() { return metadata; }
    public void setMetadata(Map<String, Object> metadata) {
        this.metadata = metadata != null ? metadata : new HashMap<>();
    }
}
