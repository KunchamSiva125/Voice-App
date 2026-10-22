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
    private static final List<Map.Entry<String, Long>> SORTED_NUMBER_ENTRIES;

    static {
        // English numbers & words
        NUMBER_MAP.put("one", 1L); NUMBER_MAP.put("two", 2L); NUMBER_MAP.put("three", 3L);
        NUMBER_MAP.put("four", 4L); NUMBER_MAP.put("five", 5L); NUMBER_MAP.put("six", 6L);
        NUMBER_MAP.put("seven", 7L); NUMBER_MAP.put("eight", 8L); NUMBER_MAP.put("nine", 9L);
        NUMBER_MAP.put("ten", 10L); NUMBER_MAP.put("eleven", 11L); NUMBER_MAP.put("twelve", 12L);
        NUMBER_MAP.put("thirteen", 13L); NUMBER_MAP.put("fourteen", 14L); NUMBER_MAP.put("fifteen", 15L);
        NUMBER_MAP.put("twenty", 20L); NUMBER_MAP.put("twenty five", 25L); NUMBER_MAP.put("thirty", 30L);
        NUMBER_MAP.put("forty", 40L); NUMBER_MAP.put("fifty", 50L); NUMBER_MAP.put("sixty", 60L);
        NUMBER_MAP.put("seventy", 70L); NUMBER_MAP.put("eighty", 80L); NUMBER_MAP.put("ninety", 90L);
        NUMBER_MAP.put("hundred", 100L); NUMBER_MAP.put("one hundred", 100L); NUMBER_MAP.put("a hundred", 100L);
        NUMBER_MAP.put("one hundred fifty", 150L); NUMBER_MAP.put("one hundred and fifty", 150L);
        NUMBER_MAP.put("one fifty", 150L);
        NUMBER_MAP.put("two hundred", 200L); NUMBER_MAP.put("two hundred fifty", 250L);
        NUMBER_MAP.put("two hundred and fifty", 250L); NUMBER_MAP.put("two fifty", 250L);
        NUMBER_MAP.put("three hundred", 300L); NUMBER_MAP.put("three hundred fifty", 350L);
        NUMBER_MAP.put("four hundred", 400L); NUMBER_MAP.put("four hundred fifty", 450L);
        NUMBER_MAP.put("five hundred", 500L); NUMBER_MAP.put("five hundred fifty", 550L);
        NUMBER_MAP.put("six hundred", 600L); NUMBER_MAP.put("seven hundred", 700L);
        NUMBER_MAP.put("eight hundred", 800L); NUMBER_MAP.put("nine hundred", 900L);
        NUMBER_MAP.put("thousand", 1000L); NUMBER_MAP.put("one thousand", 1000L);
        NUMBER_MAP.put("two thousand", 2000L); NUMBER_MAP.put("five thousand", 5000L);

        // Telugu numbers & compounds
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
        NUMBER_MAP.put("పాతిక", 25L); NUMBER_MAP.put("patika", 25L);
        NUMBER_MAP.put("ఇరవై", 20L); NUMBER_MAP.put("iravai", 20L); NUMBER_MAP.put("iruvai", 20L);
        NUMBER_MAP.put("ముప్పై", 30L); NUMBER_MAP.put("muppai", 30L);
        NUMBER_MAP.put("నలభై", 40L); NUMBER_MAP.put("nalabhai", 40L); NUMBER_MAP.put("nalabai", 40L);
        NUMBER_MAP.put("యాభై", 50L); NUMBER_MAP.put("yabhai", 50L); NUMBER_MAP.put("yabai", 50L); NUMBER_MAP.put("yaabhai", 50L);
        NUMBER_MAP.put("అరవై", 60L); NUMBER_MAP.put("aravai", 60L);
        NUMBER_MAP.put("డెబ్బై", 70L); NUMBER_MAP.put("debbai", 70L);
        NUMBER_MAP.put("ఎనభై", 80L); NUMBER_MAP.put("enabhai", 80L); NUMBER_MAP.put("enabai", 80L);
        NUMBER_MAP.put("తొంభై", 90L); NUMBER_MAP.put("tombhai", 90L); NUMBER_MAP.put("tombai", 90L);
        NUMBER_MAP.put("వంద", 100L); NUMBER_MAP.put("వందలు", 100L); NUMBER_MAP.put("vanda", 100L); NUMBER_MAP.put("nooru", 100L); NUMBER_MAP.put("నూరు", 100L);
        NUMBER_MAP.put("నూట యాభై", 150L); NUMBER_MAP.put("వంద యాభై", 150L); NUMBER_MAP.put("vanda yabhai", 150L); NUMBER_MAP.put("noota yabhai", 150L);
        NUMBER_MAP.put("నూట ఇరవై", 120L); NUMBER_MAP.put("వంద ఇరవై", 120L);
        NUMBER_MAP.put("రెండు వందలు", 200L); NUMBER_MAP.put("రెండు వందల", 200L); NUMBER_MAP.put("rendu vandalu", 200L);
        NUMBER_MAP.put("రెండు వందల యాభై", 250L); NUMBER_MAP.put("rendu vandala yabhai", 250L);
        NUMBER_MAP.put("మూడు వందలు", 300L); NUMBER_MAP.put("మూడు వందల", 300L); NUMBER_MAP.put("moodu vandalu", 300L);
        NUMBER_MAP.put("నాలుగు వందలు", 400L); NUMBER_MAP.put("నాలుగు వందల", 400L); NUMBER_MAP.put("naalugu vandalu", 400L);
        NUMBER_MAP.put("ఐదు వందలు", 500L); NUMBER_MAP.put("ఐదు వందల", 500L); NUMBER_MAP.put("aidu vandalu", 500L);
        NUMBER_MAP.put("వెయ్యి", 1000L); NUMBER_MAP.put("వేయి", 1000L); NUMBER_MAP.put("వేలు", 1000L); NUMBER_MAP.put("veyyi", 1000L); NUMBER_MAP.put("vei", 1000L);
        NUMBER_MAP.put("రెండు వేలు", 2000L); NUMBER_MAP.put("rendu velu", 2000L);
        NUMBER_MAP.put("ఐదు వేలు", 5000L); NUMBER_MAP.put("aidu velu", 5000L);

        // Pre-sort keys longest first so compound phrases match before sub-parts
        SORTED_NUMBER_ENTRIES = NUMBER_MAP.entrySet().stream()
                .sorted((a, b) -> Integer.compare(b.getKey().length(), a.getKey().length()))
                .toList();
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

        // 5. Handle ADD_CUSTOMER intent
        if ("ADD_CUSTOMER".equals(intent)) {
            if (customerName == null || customerName.isEmpty()) {
                response.setClarificationQuestion("కస్టమర్ పేరు స్పష్టంగా వినిపించలేదు. దయచేసి పేరు మళ్ళీ చెప్పండి.");
            } else {
                List<CustomerDto> matches = customerService.matchCustomersForVoice(customerName);
                if (!matches.isEmpty()) {
                    response.setMatchedCustomers(matches);
                    response.setClarificationQuestion(customerName + " గారి ఖాతా ఇప్పటికే ఉంది. వారి ప్రస్తుత బాకీ " +
                            CurrencyUtil.formatInr(matches.get(0).getOutstandingBalancePaise()) + ".");
                } else {
                    response.setConfirmationMessage(customerName + " గారిని కొత్త కస్టమర్‌గా చేర్చడానికి నిర్ధారించండి.");
                    response.setRequiresConfirmation(true);
                }
            }
            return response;
        }

        // 6. Query matching customers if customer name is detected
        if (customerName != null && !customerName.isEmpty()) {
            List<CustomerDto> matches = customerService.matchCustomersForVoice(customerName);
            response.setMatchedCustomers(matches);

            if (matches.size() > 1) {
                // Ambiguity: multiple customers match!
                response.setRequiresDisambiguation(true);
                response.setClarificationQuestion(customerName + " పేరుతో " + matches.size() + " ఖాతాలు ఉన్నాయి. దయచేసి సరైన కస్టమర్‌ను ఎంచుకోండి.");
            } else if (matches.isEmpty()) {
                response.setClarificationQuestion(customerName + " పేరుతో ఎటువంటి ఖాతా లేదు. కొత్త ఖాతా తెరవడానికి 'కొత్త కస్టమర్' బటన్ నొక్కండి.");
            }
        }

        // 7. Ambiguity checks on Intent and Amount
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
        } else if ("DELETE_CUSTOMER".equals(intent)) {
            response.setRequiresConfirmation(true);
            if (response.getMatchedCustomers() == null || response.getMatchedCustomers().isEmpty()) {
                response.setClarificationQuestion(customerName != null ? customerName + " పేరుతో ఖాతా ఏమీ కనపడలేదు." : "ఎవరి ఖాతా తొలగించాలో స్పష్టంగా చెప్పండి.");
            } else {
                CustomerDto target = response.getMatchedCustomers().get(0);
                response.setConfirmationMessage(target.getName() + " గారి ఖాతాను పూర్తిగా తొలగించడానికి నిర్ధారించండి.");
            }
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

        // RECORD_PAYMENT patterns (including deduction / thesayi)
        if (text.contains("ichadu") || text.contains("iccharu") || text.contains("kattadu") ||
            text.contains("kattaru") || text.contains("pay chesadu") || text.contains("chellinchadu") ||
            text.contains("chellimpu") || text.contains("jama") || text.contains("paid") || text.contains("payment") ||
            text.contains("thesayi") || text.contains("theseyi") || text.contains("theeseyi") ||
            text.contains("tesayi") || text.contains("teseyi") || text.contains("theesey") ||
            text.contains("thesey") || text.contains("tesey") || text.contains("debit chey") ||
            text.contains("ఇచ్చాడు") || text.contains("ఇచ్చారు") || text.contains("కట్టాడు") ||
            text.contains("కట్టారు") || text.contains("చెల్లించాడు") || text.contains("చెల్లించారు") ||
            text.contains("చెల్లింపు") || text.contains("జమ") || text.contains("పేమెంట్") ||
            text.contains("తీసేయి") || text.contains("తీసెయ్") || text.contains("తీసెయ్యి") ||
            text.contains("తీసేయండి") || text.contains("తీసేయ్") || text.contains("తీయి") ||
            text.contains("మినహాయించు") || text.contains("డెబిట్ చెయ్")) {
            return "RECORD_PAYMENT";
        }

        // QUERY_BALANCE patterns
        if (text.contains("appu entha") || text.contains("baki entha") || text.contains("balance entha") ||
            text.contains("entha baki") || text.contains("entha appu") || text.contains("entha ivvali") ||
            text.contains("entha undi") || text.contains("account unda") || text.contains("khata unda") ||
            text.contains("how much debt") || text.contains("how much debts") || text.contains("how much baki") ||
            text.contains("have how much debts") || text.contains("have how much debt") ||
            text.contains("has how much debt") || text.contains("has how much debts") ||
            text.contains("have an account") || text.contains("has an account") ||
            text.contains("have account") || text.contains("has account") ||
            text.contains("any debt") || text.contains("check balance") || text.contains("balance check") ||
            text.contains("అప్పు ఎంత") || text.contains("బాకీ ఎంత") || text.contains("ఎంత బాకీ") ||
            text.contains("బ్యాలెన్స్ ఎంత") || text.contains("ఎంత ఇవ్వాలి") || text.contains("ఎంత ఉంది") ||
            text.contains("ఖాతా ఉందా") || text.contains("అకౌంట్ ఉందా") || text.contains("బాకీ ఉందా") ||
            text.contains("అప్పు ఉందా")) {
            return "QUERY_BALANCE";
        }

        // APPLY_DISCOUNT patterns
        if (text.contains("discount") || text.contains("డిస్కౌంట్") || text.contains("రాయితీ") ||
            text.contains("rayiti") || text.contains("vadileyi") || text.contains("వదిలేయి")) {
            return "APPLY_DISCOUNT";
        }

        // ADD_CUSTOMER patterns
        if (text.contains("kotha customer") || text.contains("kottha customer") ||
            text.contains("kotha khata") || text.contains("kottha khata") ||
            text.contains("kotha account") || text.contains("add customer") ||
            text.contains("create customer") || text.contains("new customer") ||
            text.contains("కొత్త కస్టమర్") || text.contains("కొత్త ఖాతా") ||
            text.contains("కొత్త అకౌంట్") || text.contains("కస్టమర్‌గా చేర్చు") ||
            text.contains("కస్టమర్ గా చేర్చు") || text.contains("ఖాతా తెరువు") ||
            text.contains("ఖాతా తెరవండి") || text.contains("ఖాతా ఓపెన్")) {
            return "ADD_CUSTOMER";
        }

        // DELETE_CUSTOMER patterns
        if (text.contains("remove customer") || text.contains("delete customer") ||
            text.contains("remove chey") || text.contains("delete chey") ||
            text.contains("khata remove") || text.contains("account remove") ||
            text.contains("khata delete") || text.contains("account delete") ||
            text.contains("కస్టమర్‌ను తొలగించు") || text.contains("కస్టమర్ తొలగించు") ||
            text.contains("ఖాతా తొలగించు") || text.contains("ఖాతా డిలీట్") ||
            text.contains("ఖాతాను తొలగించు") || text.contains("అకౌంట్ డిలీట్") ||
            text.contains("అకౌంట్ తొలగించు") || text.contains("తొలగించు") ||
            text.contains("డిలీట్ చెయ్") || text.contains("డిలీట్ చేయండి")) {
            return "DELETE_CUSTOMER";
        }

        // VIEW_HISTORY patterns
        if (text.contains("account chupinchu") || text.contains("khata chupinchu") ||
            text.contains("చూపించు") || text.contains("లెక్క చూపించు")) {
            return "VIEW_HISTORY";
        }

        return "UNKNOWN";
    }

    private Long extractAmountPaise(String text) {
        if (text == null || text.trim().isEmpty()) {
            return null;
        }

        // 1. Check for numeric digits like "100", "50", "150", "2000"
        Pattern digitPattern = Pattern.compile("\\b(\\d+)\\b");
        Matcher digitMatcher = digitPattern.matcher(text);
        if (digitMatcher.find()) {
            try {
                long rupees = Long.parseLong(digitMatcher.group(1));
                return rupees * 100L;
            } catch (NumberFormatException ignored) {}
        }

        // 2. Check for number words in SORTED_NUMBER_ENTRIES (longest match first)
        String lower = text.toLowerCase();
        for (Map.Entry<String, Long> entry : SORTED_NUMBER_ENTRIES) {
            String key = entry.getKey().toLowerCase();
            // Match with whitespace, punctuation, or string start/end boundaries (works for Telugu and Latin)
            Pattern p = Pattern.compile("(?i)(^|[\\s.,!?:;])" + Pattern.quote(key) + "($|[\\s.,!?:;])");
            if (p.matcher(lower).find()) {
                return entry.getValue() * 100L;
            }
        }

        return null;
    }

    private String extractCustomerName(String text) {
        // Strip common Telugu postpositions: ki, ku, gari, gariki, appu, account, etc.
        // e.g. "Ramesh ki 100 rupayalu appu raayi" -> "Ramesh"
        // "Ramesh gari balance entha" -> "Ramesh"
        // "ramesh account lo nunchi 100 rupees thesayi" -> "Ramesh"
        String cleaned = text;

        // 1. First remove all known number words & phrases so numbers never leak into customer names
        for (Map.Entry<String, Long> entry : SORTED_NUMBER_ENTRIES) {
            cleaned = cleaned.replaceAll("(?i)(^|[\\s.,!?:;])" + Pattern.quote(entry.getKey()) + "($|[\\s.,!?:;])", " ");
        }

        cleaned = cleaned
                .replaceAll("(?i)\\b(ee roju|today|collection|total|report|mottham)\\b", " ")
                .replaceAll("(?i)\\b(rupayalu|rupayala|rupees|rs|paise)\\b", " ")
                .replaceAll("(?i)\\b(appu|baki|baaki|khata|account|entry|balance|debt|debts)\\b", " ")
                .replaceAll("(?i)\\b(have|has|had|how|much|many|does|is|are|there|an|the|a|and|or|check|for|in|telugu|of|from|to|please)\\b", " ")
                .replaceAll("(?i)\\b(kotha|kottha|new|add|create|customer|cherchu|open|teruvu|remove|delete)\\b", " ")
                .replaceAll("(?i)\\b(raayi|rayi|veyyi|ichadu|iccharu|kattadu|kattaru|chupinchu|discount|ivvu|entha|undi|ivvali|unda|leda|chellimpu|chellinchadu|jama|payment|paid|pay)\\b", " ")
                .replaceAll("(?i)\\b(thesayi|theseyi|theeseyi|tesayi|teseyi|theesey|thesey|tesey|cut|tagginchu|chey|cheyyi|chesadu|debit|debited|nunchi|nundi|lo)\\b", " ")
                .replaceAll("(?i)(రూపాయలు|రూపాయల|అప్పు|బాకీ|ఖాతా|అకౌంట్|ఎంట్రీ|రాయి|వెయ్యి|ఇచ్చాడు|ఇచ్చారు|కట్టాడు|చెల్లింపు|చెల్లించాడు|జమ|పేమెంట్|చూపించు|డిస్కౌంట్|ఇవ్వు|ఎంత|ఉంది|ఇవ్వాలి|ఉందా|లేదా)", " ")
                .replaceAll("(?i)(కొత్త|కస్టమర్‌గా|కస్టమర్గా|కస్టమర్|చేర్చండి|చేర్చు|తెరవండి|తెరువు|ఓపెన్|తొలగించు|తొలగించండి|తీసేయి|డిలీట్)", " ")
                .replaceAll("(?i)(తీసేయి|తీసెయ్|తీసెయ్యి|తీసేయండి|తీసేయ్|తీయి|కట్|తగ్గించు|చెయ్|చేయి|చేశాడు|డెబిట్|నుంచి|నుండి|లో|ఉందా|లేదా)", " ")
                .replaceAll("\\b\\d+\\b", " "); // strip numbers

        // Strip "ki", "ku", "gari", "gariki", "కి", "కు", "గారి", "గారికి"
        cleaned = cleaned
                .replaceAll("(?i)\\b(gariki|gari|ki|ku|lo|nunchi|nundi)\\b", " ")
                .replaceAll("(?i)(గారికి|గారి|కి|కు)", " ")
                .trim();

        // Extract all valid tokens to support full names (e.g. "Shiva Kumar", "రమేష్ బాబు", "కొంచెం లక్ష్మణరావు")
        String[] tokens = cleaned.split("\\s+");
        List<String> validTokens = new ArrayList<>();
        for (int i = 0; i < tokens.length; i++) {
            String token = tokens[i].replaceAll("[^a-zA-Z0-9\u0C00-\u0C7F]", "").trim();
            // If the last token has trailing suffix like "కి", "కు", "ని", "ను" attached without space, strip it
            if (i == tokens.length - 1 && (token.endsWith("కి") || token.endsWith("కు") || token.endsWith("ని") || token.endsWith("ను"))) {
                if (token.length() > 3) {
                    token = token.substring(0, token.length() - 2);
                }
            }
            if (token.length() >= 2 && !NUMBER_MAP.containsKey(token.toLowerCase())) {
                // Capitalize first letter if Latin
                if (token.matches("^[a-zA-Z]+$")) {
                    token = token.substring(0, 1).toUpperCase() + token.substring(1).toLowerCase();
                }
                validTokens.add(token);
            }
        }

        if (!validTokens.isEmpty()) {
            return String.join(" ", validTokens);
        }

        return null;
    }
}
