package com.tiffin.ledger.repository;

import com.tiffin.ledger.domain.LedgerTransaction;
import com.tiffin.ledger.domain.TransactionType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface LedgerTransactionRepository extends MongoRepository<LedgerTransaction, String> {

    List<LedgerTransaction> findByCustomerIdOrderByEffectiveAtAsc(String customerId);

    Page<LedgerTransaction> findByCustomerIdOrderByEffectiveAtDesc(String customerId, Pageable pageable);

    Optional<LedgerTransaction> findByIdempotencyKey(String idempotencyKey);

    boolean existsByIdempotencyKey(String idempotencyKey);

    List<LedgerTransaction> findByReversesTransactionId(String reversesTransactionId);

    Page<LedgerTransaction> findByEffectiveAtBetweenOrderByEffectiveAtDesc(
            Instant start, Instant end, Pageable pageable);

    List<LedgerTransaction> findByEffectiveAtBetween(Instant start, Instant end);

    List<LedgerTransaction> findByTypeAndEffectiveAtBetween(
            TransactionType type, Instant start, Instant end);

    long countByCustomerId(String customerId);
}
