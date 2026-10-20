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
    'పది': 10, 'padhi': 10, 'padi': 10,
    'ఇరవై': 20, 'iravai': 20,
    'ముప్పై': 30, 'muppai': 30,
    'నలభై': 40, 'nalabhai': 40,
    'యాభై': 50, 'yabhai': 50, 'yabai': 50,
    'అరవై': 60, 'aravai': 60,
    'డెబ్బై': 70, 'debbai': 70,
    'ఎనభై': 80, 'enabhai': 80,
    'తొంభై': 90, 'tombhai': 90,
    'వంద': 100, 'vanda': 100, 'nooru': 100, 'hundred': 100,
    'రెండు వందలు': 200, 'rendu vandalu': 200,
    'ఐదు వందలు': 500, 'aidu vandalu': 500,
    'వెయ్యి': 1000, 'veyyi': 1000, 'thousand': 1000,
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

  static int? _extractAmountPaise(String text) {
    // Check digits
    final digitMatch = RegExp(r'\b(\d+)\b').firstMatch(text);
    if (digitMatch != null) {
      final rupees = int.tryParse(digitMatch.group(1)!);
      if (rupees != null) return rupees * 100;
    }

    // Check Telugu number words
    for (final entry in teluguNumbers.entries) {
      if (text.contains(entry.key)) {
        return entry.value * 100;
      }
    }
    return null;
  }

  static String? _extractCustomerName(String text) {
    String cleaned = text
        .replaceAll(RegExp(r'\b(ee roju|today|collection|total|report|mottham)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(rupayalu|rupayala|rupees|rs|paise|రూపాయలు)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(appu|baki|baaki|khata|account|entry|balance|అప్పు|బాకీ)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(raayi|rayi|veyyi|ichadu|iccharu|kattadu|kattaru|discount|ivvu|entha|undi|రాయి|ఇచ్చాడు|ఇవ్వు)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b(gariki|gari|ki|ku|గారికి|గారి|కి|కు)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\b\d+\b'), '')
        .trim();

    final tokens = cleaned.split(RegExp(r'\s+'));
    for (final token in tokens) {
      final clean = token.replaceAll(RegExp(r'[^a-zA-Z0-9\u0C00-\u0C7F]'), '').trim();
      if (clean.length >= 2 && !teluguNumbers.containsKey(clean.toLowerCase())) {
        if (RegExp(r'^[a-zA-Z]+$').hasMatch(clean)) {
          return clean[0].toUpperCase() + clean.substring(1).toLowerCase();
        }
        return clean;
      }
    }
    return null;
  }
}
