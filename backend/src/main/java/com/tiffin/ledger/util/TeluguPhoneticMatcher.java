package com.tiffin.ledger.util;

import com.tiffin.ledger.domain.Customer;

import java.util.*;

/**
 * Intelligent phonetic and script matcher for Telugu and English names.
 * Handles:
 * 1. Telugu <-> English transliteration (e.g., "శివా" / "శివ" <-> "Siva" / "Shiva").
 * 2. Telugu vowel elongation tolerance (e.g., "శివ" vs "శివా", "రమేష్" vs "రామేష్").
 * 3. Consonant variation tolerance (e.g., "s" vs "sh", "v" vs "w", "ee" vs "i", "oo" vs "u").
 * 4. Substring and token matching (e.g., "శివ" matching "Siva (Auto)" or "Siva Kumar").
 * 5. Automatic alias generation for new/updated customer accounts.
 */
public final class TeluguPhoneticMatcher {

    private TeluguPhoneticMatcher() {}

    // Pre-curated dictionary of high-frequency Telugu names with their bilingual variants
    private static final Map<String, Set<String>> CANONICAL_VARIANTS = new HashMap<>();

    static {
        addVariantGroup("siva", "shiva", "శివ", "శివా", "శివయ్య");
        addVariantGroup("ramesh", "రమేష్", "రామేష్");
        addVariantGroup("suresh", "సురేష్", "సూరేష్");
        addVariantGroup("mahesh", "మహేష్", "మాహేష్");
        addVariantGroup("naresh", "నరేష్");
        addVariantGroup("rajesh", "రాజేష్");
        addVariantGroup("venkat", "venkatesh", "వెంకట్", "వెంకటేష్", "వెంకటేశ్వర్లు");
        addVariantGroup("satish", "సతీష్", "సతీశ్");
        addVariantGroup("apparao", "అప్పారావు", "అప్పారావ్");
        addVariantGroup("subbarao", "సుబ్బారావు", "సుబ్బారావ్");
        addVariantGroup("laxmi", "lakshmi", "లక్ష్మి", "లక్ష్మీ");
        addVariantGroup("naidu", "నాయుడు");
        addVariantGroup("srinu", "seenu", "srinivas", "శ్రీను", "శీను", "శ్రీనివాస్", "శ్రీనివాసులు", "శ్రీనూ");
        addVariantGroup("raju", "రాజు", "నాగరాజు", "nagaraju");
        addVariantGroup("kumar", "కుమార్");
        addVariantGroup("prasad", "ప్రసాద్");
        addVariantGroup("kalyan", "కళ్యాణ్", "కల్యాణ్");
        addVariantGroup("ravi", "రవి");
        addVariantGroup("gopi", "గోపి", "గోపీ");
        addVariantGroup("krishna", "కృష్ణ");
        addVariantGroup("babu", "బాబు");
        addVariantGroup("nani", "నాని");
        addVariantGroup("chanti", "చంటి");
        addVariantGroup("reddy", "రెడ్డి");
        addVariantGroup("sekhar", "shekhar", "శేఖర్", "శేఖరు");
        addVariantGroup("vamsi", "vamshi", "వంశీ", "వంశి");
        addVariantGroup("chalam", "చలం");
        addVariantGroup("ramu", "రాము", "రాముడు");
        addVariantGroup("somu", "సోము");
        addVariantGroup("balu", "బాలు");
        addVariantGroup("sai", "సాయి");
        addVariantGroup("praveen", "ప్రవీణ్");
        addVariantGroup("anil", "అనిల్");
        addVariantGroup("sunil", "సునీల్");
        addVariantGroup("vijay", "విజయ్");
        addVariantGroup("ajay", "అజయ్");
        addVariantGroup("mohan", "మోహన్");
        addVariantGroup("madhu", "మధు");
    }

    private static void addVariantGroup(String... names) {
        Set<String> group = new HashSet<>();
        for (String n : names) {
            group.add(n.toLowerCase().trim());
        }
        for (String n : group) {
            CANONICAL_VARIANTS.put(n, group);
        }
    }

    /**
     * Converts any Telugu script string to phonetic Latin (English).
     */
    public static String teluguToLatin(String input) {
        if (input == null || input.isEmpty()) return "";

        StringBuilder sb = new StringBuilder();
        int len = input.length();

        for (int i = 0; i < len; i++) {
            char c = input.charAt(i);

            // Independent Vowels
            switch (c) {
                case 'అ': sb.append("a"); continue;
                case 'ఆ': sb.append("aa"); continue;
                case 'ఇ': sb.append("i"); continue;
                case 'ఈ': sb.append("ee"); continue;
                case 'ఉ': sb.append("u"); continue;
                case 'ఊ': sb.append("oo"); continue;
                case 'ఋ': sb.append("ru"); continue;
                case 'ఎ': sb.append("e"); continue;
                case 'ఏ': sb.append("e"); continue;
                case 'ఐ': sb.append("ai"); continue;
                case 'ఒ': sb.append("o"); continue;
                case 'ఓ': sb.append("o"); continue;
                case 'ఔ': sb.append("au"); continue;
                case 'ం': sb.append("m"); continue;
                case 'ః': sb.append("h"); continue;
            }

            // Consonants (Base with inherent 'a')
            String consonant = null;
            switch (c) {
                case 'క': consonant = "k"; break;
                case 'ఖ': consonant = "kh"; break;
                case 'గ': consonant = "g"; break;
                case 'ఘ': consonant = "gh"; break;
                case 'ఙ': consonant = "ng"; break;
                case 'చ': consonant = "ch"; break;
                case 'ఛ': consonant = "chh"; break;
                case 'జ': consonant = "j"; break;
                case 'ఝ': consonant = "jh"; break;
                case 'ఞ': consonant = "ny"; break;
                case 'ట': consonant = "t"; break;
                case 'ఠ': consonant = "th"; break;
                case 'డ': consonant = "d"; break;
                case 'ఢ': consonant = "dh"; break;
                case 'ణ': consonant = "n"; break;
                case 'త': consonant = "t"; break;
                case 'థ': consonant = "th"; break;
                case 'ద': consonant = "d"; break;
                case 'ధ': consonant = "dh"; break;
                case 'న': consonant = "n"; break;
                case 'ప': consonant = "p"; break;
                case 'ఫ': consonant = "ph"; break;
                case 'బ': consonant = "b"; break;
                case 'భ': consonant = "bh"; break;
                case 'మ': consonant = "m"; break;
                case 'య': consonant = "y"; break;
                case 'ర': consonant = "r"; break;
                case 'ల': consonant = "l"; break;
                case 'వ': consonant = "v"; break;
                case 'శ': consonant = "sh"; break;
                case 'ష': consonant = "sh"; break;
                case 'స': consonant = "s"; break;
                case 'హ': consonant = "h"; break;
                case 'ళ': consonant = "l"; break;
                case 'ఱ': consonant = "r"; break;
            }

            if (consonant != null) {
                // Peek next char for vowel sign / virama
                String vowel = "a"; // default inherent vowel
                if (i + 1 < len) {
                    char next = input.charAt(i + 1);
                    boolean isVowelSign = true;
                    switch (next) {
                        case '\u0C3E': vowel = "aa"; break; // Telugu vowel sign aa
                        case '\u0C3F': vowel = "i"; break;  // Telugu vowel sign i
                        case '\u0C40': vowel = "ee"; break; // Telugu vowel sign ii
                        case '\u0C41': vowel = "u"; break;  // Telugu vowel sign u
                        case '\u0C42': vowel = "oo"; break; // Telugu vowel sign uu
                        case '\u0C43': vowel = "ru"; break; // Telugu vowel sign vocalic r
                        case '\u0C46': vowel = "e"; break;  // Telugu vowel sign e
                        case '\u0C47': vowel = "e"; break;  // Telugu vowel sign ee
                        case '\u0C48': vowel = "ai"; break; // Telugu vowel sign ai
                        case '\u0C4A': vowel = "o"; break;  // Telugu vowel sign o
                        case '\u0C4B': vowel = "o"; break;  // Telugu vowel sign oo
                        case '\u0C4C': vowel = "au"; break; // Telugu vowel sign au
                        case '\u0C4D': vowel = ""; break;   // Telugu virama (drops inherent vowel)
                        default:
                            isVowelSign = false;
                            break;
                    }
                    if (isVowelSign) {
                        i++; // consume vowel sign
                    }
                }
                sb.append(consonant).append(vowel);
                continue;
            }

            // Other ASCII or space characters
            sb.append(c);
        }

        return sb.toString().trim();
    }

    /**
     * Normalizes a phonetic Latin string into a canonical phonetic key.
     * E.g., "shiva", "siva", "shivaa" all become "siv".
     */
    public static String normalizePhonetic(String text) {
        if (text == null) return "";
        String s = text.toLowerCase().trim();

        // If it contains Telugu characters, transliterate first
        if (containsTelugu(s)) {
            s = teluguToLatin(s).toLowerCase();
        }

        // Common phonetic simplifications
        s = s.replaceAll("[^a-z0-9]", "");
        s = s.replaceAll("sh", "s");
        s = s.replaceAll("kh", "k");
        s = s.replaceAll("gh", "g");
        s = s.replaceAll("ch", "c");
        s = s.replaceAll("jh", "j");
        s = s.replaceAll("th", "t");
        s = s.replaceAll("dh", "d");
        s = s.replaceAll("ph", "f");
        s = s.replaceAll("bh", "b");
        s = s.replaceAll("ee", "i");
        s = s.replaceAll("oo", "u");
        s = s.replaceAll("aa", "a");
        s = s.replaceAll("w", "v");
        s = s.replaceAll("y$", "i");

        // Collapse duplicate letters: "ss" -> "s", "tt" -> "t", etc.
        s = s.replaceAll("(.)\\1+", "$1");

        // Strip trailing vowel elongation for stem matching (e.g. siva -> siv, ramesha -> ramesh)
        if (s.length() > 3 && (s.endsWith("a") || s.endsWith("i") || s.endsWith("u"))) {
            s = s.substring(0, s.length() - 1);
        }

        return s;
    }

    /**
     * Strips Telugu vowel diacritics and halant to yield the pure consonant stem.
     * E.g., "శివా" -> "శవ", "శివ" -> "శవ". Both match!
     */
    public static String stripTeluguDiacritics(String text) {
        if (text == null) return "";
        // Telugu diacritic range: \u0C3E to \u0C4D plus anusvara \u0C02
        return text.replaceAll("[\u0C3E-\u0C4D\u0C01-\u0C03]", "").replaceAll("\\s+", "").trim();
    }

    public static boolean containsTelugu(String text) {
        if (text == null) return false;
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c >= '\u0C00' && c <= '\u0C7F') return true;
        }
        return false;
    }

    /**
     * Determines the match score (0 to 100) between a voice-spoken query name and a candidate Customer.
     * Returns 100 for exact match, >= 85 for high-confidence phonetic/stem matches.
     */
    public static int calculateMatchScore(String spokenQuery, Customer customer) {
        if (spokenQuery == null || spokenQuery.trim().isEmpty() || customer == null) {
            return 0;
        }

        String q = spokenQuery.trim().toLowerCase();
        String cName = customer.getName() != null ? customer.getName().trim().toLowerCase() : "";
        String cNorm = customer.getNormalizedName() != null ? customer.getNormalizedName().trim().toLowerCase() : "";

        // 1. Exact string match
        if (q.equalsIgnoreCase(cName) || q.equalsIgnoreCase(cNorm)) {
            return 100;
        }
        if (customer.getAliases() != null) {
            for (String alias : customer.getAliases()) {
                if (alias != null && q.equalsIgnoreCase(alias.trim())) {
                    return 100;
                }
            }
        }

        // 2. Canonical dictionary lookup (e.g., "శివా" in set of "siva")
        Set<String> queryVariants = CANONICAL_VARIANTS.get(q);
        if (queryVariants != null) {
            if (queryVariants.contains(cName) || queryVariants.contains(cNorm)) {
                return 98;
            }
            if (customer.getAliases() != null) {
                for (String alias : customer.getAliases()) {
                    if (alias != null && queryVariants.contains(alias.trim().toLowerCase())) {
                        return 98;
                    }
                }
            }
        }

        // Also check if customer name is in canonical dictionary
        Set<String> customerVariants = CANONICAL_VARIANTS.get(cName);
        if (customerVariants == null && !cNorm.isEmpty()) {
            customerVariants = CANONICAL_VARIANTS.get(cNorm);
        }
        if (customerVariants != null && customerVariants.contains(q)) {
            return 98;
        }

        // 3. Telugu Consonant Stem Match (e.g. "శివా" vs "శివ" -> both strip to "శవ")
        if (containsTelugu(q) && (containsTelugu(cName) || containsTelugu(cNorm))) {
            String qStem = stripTeluguDiacritics(q);
            String nameStem = stripTeluguDiacritics(cName);
            String normStem = stripTeluguDiacritics(cNorm);

            if (!qStem.isEmpty() && (qStem.equals(nameStem) || qStem.equals(normStem))) {
                return 95;
            }

            if (customer.getAliases() != null) {
                for (String alias : customer.getAliases()) {
                    if (alias != null && qStem.equals(stripTeluguDiacritics(alias))) {
                        return 95;
                    }
                }
            }
        }

        // 4. Normalized Phonetic Latin Match (e.g. "శివా" -> "siv", "Siva" -> "siv")
        String qPhonetic = normalizePhonetic(q);
        String namePhonetic = normalizePhonetic(cName);
        String normPhonetic = normalizePhonetic(cNorm);

        if (!qPhonetic.isEmpty()) {
            if (qPhonetic.equals(namePhonetic) || qPhonetic.equals(normPhonetic)) {
                return 90;
            }

            if (customer.getAliases() != null) {
                for (String alias : customer.getAliases()) {
                    if (alias != null && qPhonetic.equals(normalizePhonetic(alias))) {
                        return 90;
                    }
                }
            }

            // 5. Substring / Token Phonetic Match (e.g. spoken "siv" matches "siv drivr" or "siva kumar")
            if (namePhonetic.contains(qPhonetic) || qPhonetic.contains(namePhonetic)) {
                if (Math.min(namePhonetic.length(), qPhonetic.length()) >= 3) {
                    return 85;
                }
            }
            if (!normPhonetic.isEmpty() && (normPhonetic.contains(qPhonetic) || qPhonetic.contains(normPhonetic))) {
                if (Math.min(normPhonetic.length(), qPhonetic.length()) >= 3) {
                    return 85;
                }
            }

            // Also check individual words in customer name (e.g. "Ramesh (Auto)" -> "Ramesh")
            String[] tokens = cName.split("[\\s\\(\\)\\_\\-\\./]+");
            for (String tok : tokens) {
                String tokPhonetic = normalizePhonetic(tok);
                if (!tokPhonetic.isEmpty() && tokPhonetic.equals(qPhonetic)) {
                    return 88;
                }
            }
        }

        // 6. Levenshtein edit distance on normalized phonetics (distance <= 1)
        if (qPhonetic.length() >= 3 && namePhonetic.length() >= 3) {
            int dist = levenshteinDistance(qPhonetic, namePhonetic);
            if (dist == 1) {
                return 82;
            }
        }

        return 0;
    }

    /**
     * Auto-generates bilingual aliases for a given customer name upon creation/update.
     * Supports both single names and full names (First Name + Space + Last Name).
     */
    public static List<String> generateSmartAliases(String name) {
        if (name == null || name.trim().isEmpty()) {
            return Collections.emptyList();
        }

        Set<String> aliases = new LinkedHashSet<>();
        String clean = name.trim();
        aliases.add(clean);

        // Check canonical dictionary for full string
        Set<String> canonicals = CANONICAL_VARIANTS.get(clean.toLowerCase());
        if (canonicals != null) {
            aliases.addAll(canonicals);
        }

        String[] parts = clean.split("\\s+");

        if (containsTelugu(clean)) {
            // Full name transliteration to Latin
            String latin = teluguToLatin(clean);
            if (!latin.isEmpty()) {
                aliases.add(latin);
                aliases.add(capitalizeWords(latin));
            }

            // Telugu vowel elongation variants on full name
            if (clean.endsWith("ా")) {
                aliases.add(clean.substring(0, clean.length() - 1));
            } else {
                aliases.add(clean + "ా");
            }

            // If multi-word full name (e.g. "శివ కుమార్")
            if (parts.length > 1) {
                // First name vowel elongation variant: "శివ కుమార్" <-> "శివా కుమార్"
                String first = parts[0];
                String rest = String.join(" ", Arrays.copyOfRange(parts, 1, parts.length));
                if (first.endsWith("ా")) {
                    aliases.add(first.substring(0, first.length() - 1) + " " + rest);
                } else {
                    aliases.add(first + "ా " + rest);
                }

                // Also add first name aliases individually
                List<String> firstAliases = generateSmartAliases(first);
                aliases.addAll(firstAliases);
            }
        } else {
            // Latin name (e.g. "Shiva Kumar" or "Siva")
            String lower = clean.toLowerCase();
            aliases.add(capitalizeWords(clean));
            aliases.add(lower);

            // If multi-word (e.g. "Shiva Kumar")
            if (parts.length > 1) {
                String firstPart = parts[0].toLowerCase();
                String restPart = String.join(" ", Arrays.copyOfRange(parts, 1, parts.length)).toLowerCase();

                // Generate common Telugu for first name and rest
                List<String> firstTelugu = getCommonTeluguVariants(firstPart);
                List<String> restTelugu = getCommonTeluguVariants(restPart);

                for (String ft : firstTelugu) {
                    for (String rt : restTelugu) {
                        aliases.add(ft + " " + rt);
                    }
                    // Also add first name by itself
                    aliases.add(ft);
                }

                // Common alternate English spelling of first name (e.g. Siva <-> Shiva)
                if (firstPart.equals("shiva") || firstPart.equals("siva")) {
                    aliases.add("Siva " + capitalizeWords(restPart));
                    aliases.add("Shiva " + capitalizeWords(restPart));
                }

                // Add first name individually
                aliases.add(capitalizeWords(parts[0]));
            } else {
                // Single word Latin name
                aliases.addAll(getCommonTeluguVariants(lower));
            }
        }

        return new ArrayList<>(aliases);
    }

    private static String capitalizeWords(String input) {
        if (input == null || input.isEmpty()) return "";
        StringBuilder sb = new StringBuilder();
        for (String w : input.split("\\s+")) {
            if (!w.isEmpty()) {
                if (sb.length() > 0) sb.append(" ");
                sb.append(Character.toUpperCase(w.charAt(0))).append(w.substring(1).toLowerCase());
            }
        }
        return sb.toString();
    }

    private static List<String> getCommonTeluguVariants(String word) {
        List<String> res = new ArrayList<>();
        String w = word.toLowerCase().trim();
        if (w.equals("siva") || w.equals("shiva")) {
            res.add("శివ"); res.add("శివా"); res.add("Shiva"); res.add("Siva");
        } else if (w.equals("kumar")) {
            res.add("కుమార్"); res.add("Kumar");
        } else if (w.equals("ramesh")) {
            res.add("రమేష్"); res.add("రామేష్");
        } else if (w.equals("suresh")) {
            res.add("సురేష్"); res.add("సూరేష్");
        } else if (w.equals("mahesh")) {
            res.add("మహేష్"); res.add("మాహేష్");
        } else if (w.equals("venkat") || w.equals("venkatesh")) {
            res.add("వెంకట్"); res.add("వెంకటేష్");
        } else if (w.equals("laxmi") || w.equals("lakshmi")) {
            res.add("లక్ష్మి"); res.add("లక్ష్మీ");
        } else if (w.equals("srinu") || w.equals("seenu")) {
            res.add("శ్రీను"); res.add("శీను");
        } else if (w.equals("babu")) {
            res.add("బాబు");
        } else if (w.equals("naidu")) {
            res.add("నాయుడు");
        } else if (w.equals("rao")) {
            res.add("రావు");
        } else if (w.equals("reddy")) {
            res.add("రెడ్డి");
        } else if (w.equals("prasad")) {
            res.add("ప్రసాద్");
        } else if (w.equals("master")) {
            res.add("మాస్టారు");
        } else if (w.equals("auto")) {
            res.add("ఆటో");
        } else {
            // General transliteration if contains Telugu
            if (containsTelugu(w)) {
                res.add(teluguToLatin(w));
            }
        }
        return res;
    }

    private static int levenshteinDistance(String a, String b) {
        int[] costs = new int[b.length() + 1];
        for (int j = 0; j < costs.length; j++) {
            costs[j] = j;
        }
        for (int i = 1; i <= a.length(); i++) {
            costs[0] = i;
            int nw = i - 1;
            for (int j = 1; j <= b.length(); j++) {
                int cj = Math.min(1 + Math.min(costs[j], costs[j - 1]),
                        a.charAt(i - 1) == b.charAt(j - 1) ? nw : nw + 1);
                nw = costs[j];
                costs[j] = cj;
            }
        }
        return costs[b.length()];
    }
}
