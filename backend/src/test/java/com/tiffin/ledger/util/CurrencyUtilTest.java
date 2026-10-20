package com.tiffin.ledger.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class CurrencyUtilTest {

    @Test
    @DisplayName("Integer paise converts to rupees without floating point drift")
    void testPaiseToRupees() {
        assertEquals(100.0, CurrencyUtil.paiseToRupees(10000L));
        assertEquals(50.50, CurrencyUtil.paiseToRupees(5050L));
        assertEquals(0.0, CurrencyUtil.paiseToRupees(0L));
        assertEquals(350.25, CurrencyUtil.paiseToRupees(35025L));
    }

    @Test
    @DisplayName("Rupees converts to paise accurately")
    void testRupeesToPaise() {
        assertEquals(10000L, CurrencyUtil.rupeesToPaise(100.0));
        assertEquals(5050L, CurrencyUtil.rupeesToPaise(50.50));
        assertEquals(35000L, CurrencyUtil.rupeesToPaise(350.0));
    }

    @Test
    @DisplayName("Formats INR currency string with symbol")
    void testFormatInr() {
        assertEquals("₹100.00", CurrencyUtil.formatInr(10000L));
        assertEquals("₹1,250.00", CurrencyUtil.formatInr(125000L));
    }

    @Test
    @DisplayName("Generates natural Telugu rupees string")
    void testToTeluguRupeesString() {
        assertEquals("100 రూపాయలు", CurrencyUtil.toTeluguRupeesString(10000L));
        assertEquals("350 రూపాయలు", CurrencyUtil.toTeluguRupeesString(35000L));
        assertEquals("100 రూపాయల 50 పైసలు", CurrencyUtil.toTeluguRupeesString(10050L));
    }
}
