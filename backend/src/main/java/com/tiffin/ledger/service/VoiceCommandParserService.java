package com.tiffin.ledger.service;

import com.tiffin.ledger.dto.customer.CustomerDto;
import com.tiffin.ledger.dto.voice.VoiceParseRequest;
import com.tiffin.ledger.dto.voice.VoiceParseResponse;
import com.tiffin.ledger.util.CurrencyUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class VoiceCommandParserService {

    private static final Logger log = LoggerFactory.getLogger(VoiceCommandParserService.class);

    private final CustomerService customerService;

    // Word to amount in Rupees map
    private static final Map<String, Long> NUMBER_MAP = new HashMap<>();
    static {
        NUMBER_MAP.put("ఒకటి", 1L); NUMBER_MAP.put("okati", 1L);
        NUMBER_MAP.put("రెండు", 2L); NUMBER_MAP.put("rendu", 2L);
        NUMBER_MAP.put("మూడు", 3L); NUMBER_MAP.put("moodu", 3L);
        NUMBER_MAP.put("నాలుగు", 4L); NUMBER_MAP.put("naalugu", 4L);
        NUMBER_MAP.put("ఐదు", 5L); NUMBER_MAP.put("aidu", 5L);
        NUMBER_MAP.put("ఆరు", 6L); NUMBER_MAP.put("aaru", 6L);
        NUMBER_MAP.put("ఏడు", 7L); NUMBER_MAP.put("yedu", 7L);
        NUMBER_MAP.put("ఎనిమిది", 8L); NUMBER_MAP.put("enimidi", 8L);
        NUMBER_MAP.put("తొమ్మిది", 9L); NUMBER_MAP.put("tommidi", 9L);
        NUMBER_MAP.put("పది", 10L); NUMBER_MAP.put("padhi", 10L); NUMBER_MAP.put("padi", 10L);
        NUMBER_MAP.put("ఇరవై", 20L); NUMBER_MAP.put("iravai", 20L); NUMBER_MAP.put("iruvai", 20L);
        NUMBER_MAP.put("ముప్పై", 30L); NUMBER_MAP.put("muppai", 30L);
        NUMBER_MAP.put("నలభై", 40L); NUMBER_MAP.put("nalabhai", 40L); NUMBER_MAP.put("nalabai", 40L);
        NUMBER_MAP.put("యాభై", 50L); NUMBER_MAP.put("yabhai", 50L); NUMBER_MAP.put("yabai", 50L); NUMBER_MAP.put("yaabhai", 50L);
        NUMBER_MAP.put("అరవై", 60L); NUMBER_MAP.put("aravai", 60L);
        NUMBER_MAP.put("డెబ్బై", 70L); NUMBER_MAP.put("debbai", 70L);
        NUMBER_MAP.put("ఎనభై", 80L); NUMBER_MAP.put("enabhai", 80L); NUMBER_MAP.put("enabai", 80L);
        NUMBER_MAP.put("తొంభై", 90L); NUMBER_MAP.put("tombhai", 90L); NUMBER_MAP.put("tombai", 90L);
        NUMBER_MAP.put("వంద", 100L); NUMBER_MAP.put("vanda", 100L); NUMBER_MAP.put("nooru", 100L); NUMBER_MAP.put("hundred", 100L);
        NUMBER_MAP.put("రెండు వందలు", 200L); NUMBER_MAP.put("rendu vandalu", 200L);
        NUMBER_MAP.put("మూడు వందలు", 300L); NUMBER_MAP.put("moodu vandalu", 300L);
        NUMBER_MAP.put("నాలుగు వందలు", 400L); NUMBER_MAP.put("naalugu vandalu", 400L);
        NUMBER_MAP.put("ఐదు వందలు", 500L); NUMBER_MAP.put("aidu vandalu", 500L);
        NUMBER_MAP.put("వెయ్యి", 1000L); NUMBER_MAP.put("veyyi", 1000L); NUMBER_MAP.put("vei", 1000L); NUMBER_MAP.put("thousand", 1000L);
    }

    public VoiceCommandParserService(CustomerService customerService) {
        this.customerService = customerService;
    }

    public VoiceParseResponse parseCommand(VoiceParseRequest request) {
        String raw = request.getRawTranscript();
        VoiceParseResponse response = new VoiceParseResponse();
        response.setRawTranscript(raw);

        if (raw == null || raw.trim().isEmpty()) {
            response.setIntent("UNKNOWN");
            response.setClarificationQuestion("ఏమీ వినిపించలేదు. దయచేసి మళ్ళీ చెప్పండి.");
            return response;
        }

        String normalized = raw.trim().toLowerCase().replaceAll("\\s+", " ");

        // 1. Check for Daily Report query
        if (isDailyReportIntent(normalized)) {
            response.setIntent("DAILY_REPORT");
            response.setConfidence(0.98);
            return response;
        }

        // 2. Identify Intent
        String intent = determineIntent(normalized);
        response.setIntent(intent);

        // 3. Extract Amount
        Long amountPaise = extractAmountPaise(normalized);
        if (amountPaise != null) {
            response.setAmountPaise(amountPaise);
        }

        // 4. Extract Customer Name
        String customerName = extractCustomerName(normalized);
        response.setCustomerName(customerName);

        // 5. Query matching customers if customer name is detected
        if (customerName != null && !customerName.isEmpty()) {
            List<CustomerDto> matches = customerService.matchCustomersForVoice(customerName);
            response.setMatchedCustomers(matches);

            if (matches.size() > 1) {
                // Ambiguity: multiple customers match!
                response.setRequiresDisambiguation(true);
                response.setClarificationQuestion(customerName + " పేరుతో " + matches.size() + " ఖాతాలు ఉన్నాయి. దయచేసి సరైన కస్టమర్‌ను ఎంచుకోండి.");
            } else if (matches.isEmpty()) {
                response.setClarificationQuestion("'" + customerName + "' పేరుతో ఎటువంటి కస్టమర్ ఖాతా కనపడలేదు. కొత్త కస్టమర్ గా చేర్చాలా?");
            }
        }

        // 6. Ambiguity checks on Intent and Amount
        if ("UNKNOWN".equals(intent)) {
            if (normalized.contains("cut") || normalized.contains("కట్") || normalized.contains("tagginchu")) {
                response.setClarificationQuestion(customerName + " ఖాతాలో " + (amountPaise != null ? CurrencyUtil.formatInr(amountPaise) : "") +
                        " చెల్లింపుగా (Payment) రికార్డ్ చేయాలా లేక డిస్కౌంట్ ఇవ్వాలా?");
                response.setRequiresConfirmation(true);
            } else {
                response.setClarificationQuestion("మీ కమాండ్ అర్థం కాలేదు. అప్పు రాయాలా లేక పేమెంట్ చేయాలా స్పష్టంగా చెప్పండి.");
            }
        } else if (("ADD_CREDIT".equals(intent) || "RECORD_PAYMENT".equals(intent) || "APPLY_DISCOUNT".equals(intent)) && amountPaise == null) {
            response.setClarificationQuestion("ఎంత రూపాయలో స్పష్టంగా చెప్పలేదు. దయచేసి మొత్తాన్ని మళ్ళీ చెప్పండి.");
            response.setRequiresConfirmation(true);
        } else if ("APPLY_DISCOUNT".equals(intent)) {
            response.setRequiresConfirmation(true);
            response.setConfirmationMessage(customerName + " ఖాతాలో " + CurrencyUtil.formatInr(amountPaise != null ? amountPaise : 0) + " డిస్కౌంట్ ఇవ్వడానికి నిర్ధారించండి.");
        }

        return response;
    }

    private boolean isDailyReportIntent(String text) {
        return text.contains("ee roju collection") || text.contains("ఈ రోజు కలెక్షన్") ||
               text.contains("ee roju total") || text.contains("ఈ రోజు మొత్తం") ||
               text.contains("ee roju lekka") || text.contains("today collection") ||
               text.contains("today report");
    }

    private String determineIntent(String text) {
        // ADD_CREDIT patterns
        if (text.contains("appu raayi") || text.contains("appu rayi") || text.contains("appu veyyi") ||
            text.contains("credit raayi") || text.contains("credit veyyi") || text.contains("khata lo raayi") ||
            text.contains("అప్పు రాయి") || text.contains("అప్పు వెయ్యి") || text.contains("ఖాతాలో రాయి") ||
            text.contains("క్రెడిట్ రాయి") || text.contains("క్రెడిట్ వెయ్యి")) {
            return "ADD_CREDIT";
        }

        // RECORD_PAYMENT patterns
        if (text.contains("ichadu") || text.contains("iccharu") || text.contains("kattadu") ||
            text.contains("kattaru") || text.contains("pay chesadu") || text.contains("chellinchadu") ||
            text.contains("ఇచ్చాడు") || text.contains("ఇచ్చారు") || text.contains("కట్టాడు") ||
            text.contains("కట్టారు") || text.contains("చెల్లించాడు") || text.contains("చెల్లించారు")) {
            return "RECORD_PAYMENT";
        }

        // QUERY_BALANCE patterns
        if (text.contains("appu entha") || text.contains("baki entha") || text.contains("balance entha") ||
            text.contains("entha ivvali") || text.contains("entha undi") ||
            text.contains("అప్పు ఎంత") || text.contains("బాకీ ఎంత") || text.contains("బ్యాలెన్స్ ఎంత") ||
            text.contains("ఎంత ఇవ్వాలి") || text.contains("ఎంత ఉంది")) {
            return "QUERY_BALANCE";
        }

        // APPLY_DISCOUNT patterns
        if (text.contains("discount") || text.contains("డిస్కౌంట్") || text.contains("రాయితీ") ||
            text.contains("rayiti") || text.contains("vadileyi") || text.contains("వదిలేయి")) {
            return "APPLY_DISCOUNT";
        }

        // VIEW_HISTORY patterns
        if (text.contains("account chupinchu") || text.contains("khata chupinchu") ||
            text.contains("చూపించు") || text.contains("లెక్క చూపించు")) {
            return "VIEW_HISTORY";
        }

        return "UNKNOWN";
    }

    private Long extractAmountPaise(String text) {
        // 1. Check for numeric digits like "100", "50", "150", "2000"
        Pattern digitPattern = Pattern.compile("\\b(\\d+)\\b");
        Matcher digitMatcher = digitPattern.matcher(text);
        if (digitMatcher.find()) {
            try {
                long rupees = Long.parseLong(digitMatcher.group(1));
                return rupees * 100L;
            } catch (NumberFormatException ignored) {}
        }

        // 2. Check for multi-word phrases like "rendu vandalu", "aidu vandalu"
        for (Map.Entry<String, Long> entry : NUMBER_MAP.entrySet()) {
            if (entry.getKey().contains(" ") && text.contains(entry.getKey())) {
                return entry.getValue() * 100L;
            }
        }

        // 3. Check for single Telugu words like "vanda", "veyyi", "yabhai"
        for (Map.Entry<String, Long> entry : NUMBER_MAP.entrySet()) {
            if (!entry.getKey().contains(" ") && text.matches(".*\\b" + Pattern.quote(entry.getKey()) + "\\b.*")) {
                return entry.getValue() * 100L;
            }
        }

        return null;
    }

    private String extractCustomerName(String text) {
        // Strip common Telugu postpositions: ki, ku, gari, gariki, appu, account, etc.
        // e.g. "Ramesh ki 100 rupayalu appu raayi" -> "Ramesh"
        // "Ramesh gari balance entha" -> "Ramesh"
        String cleaned = text
                .replaceAll("(?i)\\b(ee roju|today|collection|total|report|mottham)\\b", "")
                .replaceAll("(?i)\\b(rupayalu|rupayala|rupees|rs|paise)\\b", "")
                .replaceAll("(?i)\\b(appu|baki|baaki|khata|account|entry|balance)\\b", "")
                .replaceAll("(?i)\\b(raayi|rayi|veyyi|ichadu|iccharu|kattadu|kattaru|chupinchu|discount|ivvu|entha|undi|ivvali)\\b", "")
                .replaceAll("(?i)\\b(రూపాయలు|రూపాయల|అప్పు|బాకీ|ఖాతా|ఎంట్రీ|రాయి|వెయ్యి|ఇచ్చాడు|ఇచ్చారు|కట్టాడు|చూపించు|డిస్కౌంట్|ఇవ్వు|ఎంత|ఉంది|ఇవ్వాలి)\\b", "")
                .replaceAll("\\b\\d+\\b", ""); // strip numbers

        // Strip "ki", "ku", "gari", "gariki", "కి", "కు", "గారి", "గారికి"
        cleaned = cleaned
                .replaceAll("(?i)\\b(gariki|gari|ki|ku)\\b", "")
                .replaceAll("(?i)(గారికి|గారి|కి|కు)", "")
                .trim();

        // Take the first non-empty word token as candidate customer name
        String[] tokens = cleaned.split("\\s+");
        for (String t : tokens) {
            String token = t.replaceAll("[^a-zA-Z0-9\u0C00-\u0C7F]", "").trim();
            if (token.length() >= 2 && !NUMBER_MAP.containsKey(token.toLowerCase())) {
                // Capitalize first letter if Latin
                if (token.matches("^[a-zA-Z]+$")) {
                    return token.substring(0, 1).toUpperCase() + token.substring(1).toLowerCase();
                }
                return token;
            }
        }

        return null;
    }
}
