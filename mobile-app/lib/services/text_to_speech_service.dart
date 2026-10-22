import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setVolume(1.0);
      try {
        await _flutterTts.setLanguage("te-IN"); // Telugu India
      } catch (_) {
        // Fallback to default if te-IN not supported on this platform
      }
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(kIsWeb ? 0.9 : 0.85); // Slightly slower for clarity in noisy hotel
      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> speakTelugu(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> speak(String text) async {
    await speakTelugu(text);
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}
