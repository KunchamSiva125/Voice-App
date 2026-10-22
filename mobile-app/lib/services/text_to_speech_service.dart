import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage("te-IN"); // Telugu India
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.85); // Slightly slower for clarity in noisy hotel
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

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }
}
