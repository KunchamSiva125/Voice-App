package com.tiffin.ledger.util;

import com.tiffin.ledger.domain.Customer;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class TeluguPhoneticMatcherTest {

    @Test
    @DisplayName("Phonetic Match: Telugu 'శివా' and 'శివ' match English customer 'Siva'")
    void testShivaMatching() {
        Customer siva = new Customer("Siva", "9000000000", "test", "admin");
        
        // Spoken in Telugu with dirgham
        int scoreWithDirgham = TeluguPhoneticMatcher.calculateMatchScore("శివా", siva);
        assertTrue(scoreWithDirgham >= 85, "Expected high match score for 'శివా' -> 'Siva', got " + scoreWithDirgham);

        // Spoken in Telugu without dirgham
        int scoreWithoutDirgham = TeluguPhoneticMatcher.calculateMatchScore("శివ", siva);
        assertTrue(scoreWithoutDirgham >= 85, "Expected high match score for 'శివ' -> 'Siva', got " + scoreWithoutDirgham);

        // Customer named in English 'Shiva'
        Customer shiva = new Customer("Shiva", "9000000000", "test", "admin");
        int scoreShiva = TeluguPhoneticMatcher.calculateMatchScore("శివా", shiva);
        assertTrue(scoreShiva >= 85, "Expected high match score for 'శివా' -> 'Shiva', got " + scoreShiva);
    }

    @Test
    @DisplayName("Phonetic Match: Telugu 'రమేష్' matches 'Ramesh'")
    void testRameshMatching() {
        Customer ramesh = new Customer("Ramesh", "9111111111", "test", "admin");
        int score = TeluguPhoneticMatcher.calculateMatchScore("రమేష్", ramesh);
        assertTrue(score >= 85, "Expected match score >= 85, got " + score);

        // Elongated 'రామేష్'
        int scoreElongated = TeluguPhoneticMatcher.calculateMatchScore("రామేష్", ramesh);
        assertTrue(scoreElongated >= 85, "Expected match score >= 85, got " + scoreElongated);
    }

    @Test
    @DisplayName("Smart Alias Generation: 'Siva' gets Telugu variants, 'శివ' gets English variants")
    void testSmartAliasGeneration() {
        List<String> sivaAliases = TeluguPhoneticMatcher.generateSmartAliases("Siva");
        assertTrue(sivaAliases.contains("శివ") || sivaAliases.contains("శివా"), "Siva should have Telugu aliases");

        List<String> teluguAliases = TeluguPhoneticMatcher.generateSmartAliases("శివా");
        assertTrue(teluguAliases.contains("శివ"), "శివా should include short vowel stem 'శివ'");
    }

    @Test
    @DisplayName("Full Name Match: 'Shiva Kumar' matches Telugu 'శివ కుమార్' and 'శివా కుమార్'")
    void testFullNameMatching() {
        Customer shivaKumar = new Customer("Shiva Kumar", "9848011223", "Regular", "admin");

        // Exact full name match in Telugu
        int scoreTelugu = TeluguPhoneticMatcher.calculateMatchScore("శివ కుమార్", shivaKumar);
        assertTrue(scoreTelugu >= 85, "Expected >= 85 for full name 'శివ కుమార్', got " + scoreTelugu);

        // Full name with vowel elongation on first name
        int scoreElongated = TeluguPhoneticMatcher.calculateMatchScore("శివా కుమార్", shivaKumar);
        assertTrue(scoreElongated >= 85, "Expected >= 85 for full name 'శివా కుమార్', got " + scoreElongated);

        // First name only query matching full name customer
        int scoreFirstOnly = TeluguPhoneticMatcher.calculateMatchScore("శివా", shivaKumar);
        assertTrue(scoreFirstOnly >= 85, "Expected >= 85 for first name only matching full name customer, got " + scoreFirstOnly);
    }

    @Test
    @DisplayName("Full Name Alias Generation: 'Shiva Kumar' produces Telugu full name and first name aliases")
    void testFullNameAliasGeneration() {
        List<String> aliases = TeluguPhoneticMatcher.generateSmartAliases("Shiva Kumar");
        assertTrue(aliases.contains("శివ కుమార్") || aliases.contains("శివా కుమార్"), 
                "Expected Telugu full name variant in aliases, got " + aliases);
        assertTrue(aliases.contains("Shiva") || aliases.contains("Siva"), 
                "Expected first name variant in aliases, got " + aliases);
    }
}
