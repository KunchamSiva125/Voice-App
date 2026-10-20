import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

abstract class ISpeechRecognitionProvider {
  Future<bool> initialize();
  Future<void> startListening({
    required Function(String transcript, bool isFinal) onResult,
    required Function(String error) onError,
  });
  Future<void> stopListening();
  bool get isListening;
}

/// Native Android Speech Recognition Provider (uses Google Speech Services / Android SpeechRecognizer)
class AndroidNativeSpeechProvider implements ISpeechRecognitionProvider {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint('Microphone permission denied');
      return false;
    }

    try {
      _isAvailable = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech error: $val');
          _isListening = false;
        },
        onStatus: (val) {
          debugPrint('Speech status: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isAvailable;
    } catch (e) {
      debugPrint('Speech init failed: $e');
      return false;
    }
  }

  @override
  Future<void> startListening({
    required Function(String transcript, bool isFinal) onResult,
    required Function(String error) onError,
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        onError('Speech recognition not available on this device');
        return;
      }
    }

    _isListening = true;
    try {
      await _speech.listen(
        onResult: (val) {
          onResult(val.recognizedWords, val.finalResult);
        },
        localeId: 'te_IN', // Telugu (India)
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      _isListening = false;
      onError(e.toString());
    }
  }

  @override
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
}

/// Mock Speech Recognition Provider for automated testing and devices without Google Speech Services
class MockSpeechProvider implements ISpeechRecognitionProvider {
  bool _listening = false;
  String _mockText = "Ramesh ki 100 rupayalu appu raayi";

  void setMockUtterance(String utterance) {
    _mockText = utterance;
  }

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required Function(String transcript, bool isFinal) onResult,
    required Function(String error) onError,
  }) async {
    _listening = true;
    await Future.delayed(const Duration(milliseconds: 600));
    onResult(_mockText, true);
    _listening = false;
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
  }
}
