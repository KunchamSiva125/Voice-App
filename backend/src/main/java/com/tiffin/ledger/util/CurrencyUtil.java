package com.tiffin.ledger.util;

import java.text.DecimalFormat;
import java.util.Locale;

public final class CurrencyUtil {

    private CurrencyUtil() {}

    /**
     * Converts paise to Rupees as double (for display only).
     */
    public static double paiseToRupees(long paise) {
        return paise / 100.0;
    }

    /**
     * Converts Rupees to paise safely without floating-point drift.
     */
    public static long rupeesToPaise(double rupees) {
        return Math.round(rupees * 100.0);
    }

    /**
     * Formats integer paise into Indian currency string, e.g. "₹350.00" or "₹1,250.00".
     */
    public static String formatInr(long paise) {
        double rupees = paiseToRupees(paise);
        DecimalFormat df = new DecimalFormat("##,##,##0.00");
        return "₹" + df.format(rupees);
    }

    /**
     * Formats integer paise into a human-readable Telugu speech string.
     * e.g., 35000 paise -> "350 రూపాయలు"
     */
    public static String toTeluguRupeesString(long paise) {
        long rupees = paise / 100;
        long remainingPaise = Math.abs(paise % 100);
        if (remainingPaise == 0) {
            return rupees + " రూపాయలు";
        } else {
            return rupees + " రూపాయల " + remainingPaise + " పైసలు";
        }
    }
}
