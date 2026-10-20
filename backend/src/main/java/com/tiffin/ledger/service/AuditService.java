package com.tiffin.ledger.service;

import com.tiffin.ledger.domain.AuditEvent;
import com.tiffin.ledger.repository.AuditEventRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class AuditService {

    private static final Logger log = LoggerFactory.getLogger(AuditService.class);

    private final AuditEventRepository auditEventRepository;

    public AuditService(AuditEventRepository auditEventRepository) {
        this.auditEventRepository = auditEventRepository;
    }

    public void logEvent(String actorUserId, String actorUsername, String action,
                         String entityType, String entityId, String reason,
                         Map<String, Object> beforeSnapshot, Map<String, Object> afterSnapshot,
                         String clientIp) {
        try {
            AuditEvent event = new AuditEvent(actorUserId, actorUsername, action, entityType, entityId, reason);
            event.setBeforeSnapshot(beforeSnapshot);
            event.setAfterSnapshot(afterSnapshot);
            event.setClientIp(clientIp);
            auditEventRepository.save(event);
            log.info("AUDIT: User '{}' performed '{}' on {}/{}", actorUsername, action, entityType, entityId);
        } catch (Exception e) {
            log.error("Failed to write audit event", e);
        }
    }

    public Page<AuditEvent> getAuditTrail(Pageable pageable) {
        return auditEventRepository.findAllByOrderByOccurredAtDesc(pageable);
    }
}
