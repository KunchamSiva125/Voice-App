class ParsedVoiceIntent {
  final String intent;
  final String? customerName;
  final int? amountPaise;
  final String? clarificationQuestion;

  ParsedVoiceIntent({
    required this.intent,
    this.customerName,
    this.amountPaise,
    this.clarificationQuestion,
  });
}

class TeluguVoiceParser {
  static final Map<String, int> teluguNumbers = {
    // English words
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
    'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
    'fifteen': 15, 'twenty': 20, 'thirty': 30, 'forty': 40,
    'fifty': 50, 'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
    'hundred': 100, 'one hundred': 100, 'one hundred fifty': 150, 'one fifty': 150,
    'two hundred': 200, 'two hundred fifty': 250, 'two fifty': 250,
    'three hundred': 300, 'four hundred': 400, 'five hundred': 500,
    'thousand': 1000, 'one thousand': 1000, 'two thousand': 2000, 'five thousand': 5000,

    // Telugu words & script
    'ఒకటి': 1, 'okati': 1,
    'రెండు': 2, 'rendu': 2,
    'మూడు': 3, 'moodu': 3,
    'నాలుగు': 4, 'naalugu': 4,
    'ఐదు': 5, 'aidu': 5,
    'ఆరు': 6, 'aaru': 6,
    'ఏడు': 7, 'yedu': 7,
    'ఎనిమిది': 8, 'enimidi': 8,
    'తొమ్మిది': 9, 'tommidi': 9,
    'పది': 10, 'padhi': 10, 'padi': 10,
    'పాతిక': 25, 'patika': 25,
    'ఇరవై': 20, 'iravai': 20,
    'ముప్పై': 30, 'muppai': 30,
    'నలభై': 40, 'nalabhai': 40,
    'యాభై': 50, 'yabhai': 50, 'yabai': 50,
    'అరవై': 60, 'aravai': 60,
    'డెబ్బై': 70, 'debbai': 70,
    'ఎనభై': 80, 'enabhai': 80,
    'తొంభై': 90, 'tombhai': 90,
    'వంద': 100, 'వందలు': 100, 'vanda': 100, 'nooru': 100, 'నూరు': 100,
    'నూట యాభై': 150, 'వంద యాభై': 150, 'vanda yabhai': 150,
    'నూట ఇరవై': 120, 'వంద ఇరవై': 120,
    'రెండు వందలు': 200, 'రెండు వందల': 200, 'rendu vandalu': 200,
    'రెండు వందల యాభై': 250, 'rendu vandala yabhai': 250,
    'మూడు వందలు': 300, 'మూడు వందల': 300, 'moodu vandalu': 300,
    'నాలుగు వందలు': 400, 'నాలుగు వందల': 400, 'naalugu vandalu': 400,
    'ఐదు వందలు': 500, 'ఐదు వందల': 500, 'aidu vandalu': 500,
    'వెయ్యి': 1000, 'వేయి': 1000, 'వేలు': 1000, 'veyyi': 1000,
    'రెండు వేలు': 2000, 'rendu velu': 2000,
    'ఐదు వేలు': 5000, 'aidu velu': 5000,
  };

  static ParsedVoiceIntent parse(String rawTranscript) {
    if (rawTranscript.trim().isEmpty) {
      return ParsedVoiceIntent(
        intent: 'UNKNOWN',
        clarificationQuestion: 'ఏమీ వినిపించలేదు. దయచేసి మళ్ళీ చెప్పండి.',
      );
    }

    final normalized = rawTranscript.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    // 1. Daily Report Check
    if (normalized.contains('ee roju collection') ||
        normalized.contains('ఈ రోజు కలెక్షన్') ||
        normalized.contains('ee roju total') ||
        normalized.contains('today collection')) {
      return ParsedVoiceIntent(intent: 'DAILY_REPORT');
    }

    // 2. Identify Intent
    String intent = 'UNKNOWN';
    if (normalized.contains('appu raayi') ||
        normalized.contains('appu veyyi') ||
        normalized.contains('credit veyyi') ||
        normalized.contains('అప్పు రాయి') ||
        normalized.contains('ఖాతాలో రాయి')) {
      intent = 'ADD_CREDIT';
    } else if (normalized.contains('ichadu') ||
        normalized.contains('iccharu') ||
        normalized.contains('kattadu') ||
        normalized.contains('pay chesadu') ||
        normalized.contains('ఇచ్చాడు') ||
        normalized.contains('చెల్లించాడు')) {
      intent = 'RECORD_PAYMENT';
    } else if (normalized.contains('appu entha') ||
        normalized.contains('balance entha') ||
        normalized.contains('entha undi') ||
        normalized.contains('బాకీ ఎంత') ||
        normalized.contains('బ్యాలెన్స్ ఎంత')) {
      intent = 'QUERY_BALANCE';
    } else if (normalized.contains('discount') ||
        normalized.contains('డిస్కౌంట్') ||
        normalized.contains('రాయితీ')) {
      intent = 'APPLY_DISCOUNT';
    }

    // 3. Extract Amount
    int? amountPaise = _extractAmountPaise(normalized);

    // 4. Extract Customer Name
    String? customerName = _extractCustomerName(normalized);

    return ParsedVoiceIntent(
      intent: intent,
      customerName: customerName,
      amountPaise: amountPaise,
    );
  }

  static final List<MapEntry<String, int>> _sortedEntries = teluguNumbers.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));

  static int? _extractAmountPaise(String text) {
    // Check digits
    final digitMatch = RegExp(r'\b(\d+)\b').firstMatch(text);
    if (digitMatch != null) {
      final rupees = int.tryParse(digitMatch.group(1)!);
      if (rupees != null) return rupees * 100;
    }

    // Check Telugu / English number words (longest match first)
    for (final entry in _sortedEntries) {
      final pattern = RegExp('(^|[\\s.,!?:;])' + RegExp.escape(entry.key) + r'($|[\s.,!?:;])', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        return entry.value * 100;
      }
    }
    return null;
  }

  static String? _extractCustomerName(String text) {
    String cleaned = text;

    // Strip known number words and phrases first
    for (final entry in _sortedEntries) {
      final pattern = RegExp('(^|[\\s.,!?:;])' + RegExp.escape(entry.key) + r'($|[\s.,!?:;])', caseSensitive: false);
      cleaned = cleaned.replaceAll(pattern, ' ');
    }

    cleaned = cleaned
        .replaceAll(RegExp(r'\b(ee roju|today|collection|total|report|mottham)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(rupayalu|rupayala|rupees|rs|paise)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'(రూపాయలు|రూపాయల)', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(appu|appulo|baki|baaki|bakilo|khata|account|entry|balance|credit|debt|debts)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'(అప్పులో|అప్పు|బాకీలో|బాకీ|ఖాతాలో|ఖాతా|క్రెడిట్|డెబిట్)', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(raayi|rayi|veyyi|ichadu|iccharu|kattadu|kattaru|discount|ivvu|entha|undi|chellimpu|chellinchadu|jama|payment|paid|pay)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'(రాయి|వెయ్యి|ఇచ్చాడు|ఇచ్చారు|కట్టాడు|కట్టారు|డిస్కౌంట్|ఇవ్వు|ఎంత|ఉంది|ఇవ్వాలి|ఉందా|లేదా|చెల్లించాడు|చెల్లింపు|జమ|పేమెంట్|చూపించు)', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b(gariki|gari|ki|ku|lo|nundi|nunchi)\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'(గారికి|గారి|కి|కు|లో|నుంచి|నుండి)', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b\d+\b'), ' ')
        .trim();

    final tokens = cleaned.split(RegExp(r'\s+'));
    final validTokens = <String>[];
    for (int i = 0; i < tokens.length; i++) {
      String clean = tokens[i].replaceAll(RegExp(r'[^a-zA-Z0-9\u0C00-\u0C7F]'), '').trim();
      // Strip trailing suffixes like "కి", "కు", "ని", "ను" attached without space
      if ((clean.endsWith('కి') || clean.endsWith('కు') || clean.endsWith('ని') || clean.endsWith('ను')) &&
          clean.length > 3) {
        clean = clean.substring(0, clean.length - 2);
      }
      if (clean.length >= 2 && !teluguNumbers.containsKey(clean.toLowerCase())) {
        if (RegExp(r'^[a-zA-Z]+$').hasMatch(clean)) {
          clean = clean[0].toUpperCase() + clean.substring(1).toLowerCase();
        }
        validTokens.add(clean);
      }
    }
    return validTokens.isNotEmpty ? validTokens.join(' ') : null;
  }
}
