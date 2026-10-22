package com.tiffin.ledger.repository;

import com.tiffin.ledger.domain.Customer;
import com.tiffin.ledger.domain.CustomerStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.data.mongodb.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CustomerRepository extends MongoRepository<Customer, String> {

    List<Customer> findByStatus(CustomerStatus status);

    Page<Customer> findByStatus(CustomerStatus status, Pageable pageable);

    @Query("{ 'status': ?0, '$or': [ " +
           "{ 'normalizedName': { '$regex': ?1, '$options': 'i' } }, " +
           "{ 'name': { '$regex': ?1, '$options': 'i' } }, " +
           "{ 'aliases': { '$regex': ?1, '$options': 'i' } }, " +
           "{ 'phoneNumber': { '$regex': ?1, '$options': 'i' } } " +
           "] }")
    Page<Customer> searchCustomers(CustomerStatus status, String searchTerm, Pageable pageable);

    @Query("{ 'status': 'ACTIVE', '$or': [ " +
           "{ 'normalizedName': ?0 }, " +
           "{ 'aliases': ?0 }, " +
           "{ 'name': { '$regex': ?1, '$options': 'i' } } " +
           "] }")
    List<Customer> matchByNameOrAlias(String exactNormalized, String regexTerm);

    Optional<Customer> findByPhoneNumberAndStatus(String phoneNumber, CustomerStatus status);

    long countByStatus(CustomerStatus status);
}
