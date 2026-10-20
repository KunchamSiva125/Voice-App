package com.tiffin.ledger.repository;

import com.tiffin.ledger.domain.AuditEvent;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface AuditEventRepository extends MongoRepository<AuditEvent, String> {

    Page<AuditEvent> findAllByOrderByOccurredAtDesc(Pageable pageable);

    List<AuditEvent> findByEntityIdOrderByOccurredAtDesc(String entityId);

    Page<AuditEvent> findByEntityTypeOrderByOccurredAtDesc(String entityType, Pageable pageable);

    Page<AuditEvent> findByOccurredAtBetweenOrderByOccurredAtDesc(
            Instant start, Instant end, Pageable pageable);
}
