package com.tiffin.ledger.util;

public final class TeluguVoiceUtil {

    private TeluguVoiceUtil() {}

    public static String buildCreditRecordedResponse(String customerName, long amountPaise, long newBalancePaise) {
        String amtStr = CurrencyUtil.toTeluguRupeesString(amountPaise);
        String balStr = CurrencyUtil.toTeluguRupeesString(newBalancePaise);
        return customerName + " గారికి " + amtStr + " అప్పు నమోదైంది. ప్రస్తుత మొత్తం బాకీ " + balStr + ".";
    }

    public static String buildPaymentRecordedResponse(String customerName, long amountPaise, long newBalancePaise) {
        String amtStr = CurrencyUtil.toTeluguRupeesString(amountPaise);
        String balStr = CurrencyUtil.toTeluguRupeesString(newBalancePaise);
        if (newBalancePaise <= 0) {
            return customerName + " గారి నుండి " + amtStr + " చెల్లింపు అందింది. బాకీ పూర్తిగా చెల్లించబడింది.";
        }
        return customerName + " గారి నుండి " + amtStr + " చెల్లింపు అందింది. ప్రస్తుత మిగిలిన బాకీ " + balStr + ".";
    }

    public static String buildBalanceQueryResponse(String customerName, long balancePaise) {
        if (balancePaise <= 0) {
            return customerName + " గారికి ఎటువంటి బాకీ లేదు. ఖాతా క్లియర్ గా ఉంది.";
        }
        String balStr = CurrencyUtil.toTeluguRupeesString(balancePaise);
        return customerName + " గారికి మొత్తం " + balStr + " బాకీ ఉంది.";
    }

    public static String buildDiscountResponse(String customerName, long amountPaise, long newBalancePaise) {
        String amtStr = CurrencyUtil.toTeluguRupeesString(amountPaise);
        String balStr = CurrencyUtil.toTeluguRupeesString(newBalancePaise);
        return customerName + " గారికి " + amtStr + " రాయితీ ఇవ్వబడింది. ప్రస్తుత బాకీ " + balStr + ".";
    }

    public static String buildReversalResponse(String customerName, long newBalancePaise) {
        String balStr = CurrencyUtil.toTeluguRupeesString(newBalancePaise);
        return customerName + " గారి పాత ఎంట్రీ విజయవంతంగా రద్దు చేయబడింది. ప్రస్తుత నికర బాకీ " + balStr + ".";
    }

    public static String buildDailyReportResponse(long collectionsPaise, long creditsPaise) {
        String colStr = CurrencyUtil.toTeluguRupeesString(collectionsPaise);
        String credStr = CurrencyUtil.toTeluguRupeesString(creditsPaise);
        return "ఈ రోజు వసూలైన మొత్తం " + colStr + ". కొత్తగా ఇచ్చిన అప్పు " + credStr + ".";
    }
}
