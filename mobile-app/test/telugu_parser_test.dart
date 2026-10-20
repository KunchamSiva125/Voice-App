import 'package:flutter_test/flutter_test.dart';
import '../lib/services/telugu_voice_parser.dart';

void main() {
  group('Telugu Voice Parser Mobile Tests', () {
    test('Parses Add Credit with digits: "Ramesh ki 100 rupayalu appu raayi"', () {
      final res = TeluguVoiceParser.parse("Ramesh ki 100 rupayalu appu raayi");
      expect(res.intent, 'ADD_CREDIT');
      expect(res.customerName, 'Ramesh');
      expect(res.amountPaise, 10000);
    });

    test('Parses Payment with Telugu number word: "Ramesh vanda rupayalu ichadu"', () {
      final res = TeluguVoiceParser.parse("Ramesh vanda rupayalu ichadu");
      expect(res.intent, 'RECORD_PAYMENT');
      expect(res.customerName, 'Ramesh');
      expect(res.amountPaise, 10000); // 100 rupees = 10000 paise
    });

    test('Parses Balance Query: "Ramesh appu entha undi?"', () {
      final res = TeluguVoiceParser.parse("Ramesh appu entha undi?");
      expect(res.intent, 'QUERY_BALANCE');
      expect(res.customerName, 'Ramesh');
      expect(res.amountPaise, isNull);
    });

    test('Parses Discount: "Ramesh appulo 50 rupayalu discount ivvu"', () {
      final res = TeluguVoiceParser.parse("Ramesh appulo 50 rupayalu discount ivvu");
      expect(res.intent, 'APPLY_DISCOUNT');
      expect(res.customerName, 'Ramesh');
      expect(res.amountPaise, 5000);
    });

    test('Parses Daily Report Query: "Ee roju collection entha?"', () {
      final res = TeluguVoiceParser.parse("Ee roju collection entha?");
      expect(res.intent, 'DAILY_REPORT');
    });

    test('Parses Telugu script utterance: "రమేష్ కి 100 రూపాయలు అప్పు రాయి"', () {
      final res = TeluguVoiceParser.parse("రమేష్ కి 100 రూపాయలు అప్పు రాయి");
      expect(res.intent, 'ADD_CREDIT');
      expect(res.amountPaise, 10000);
    });
  });
}
