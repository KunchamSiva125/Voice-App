import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../models/voice_command_model.dart';
import '../services/api_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/text_to_speech_service.dart';

class VoiceCommandProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final TextToSpeechService _tts = TextToSpeechService();
  ISpeechRecognitionProvider _speechProvider = AndroidNativeSpeechProvider();

  bool _isListening = false;
  bool _isProcessing = false;
  String _currentTranscript = '';
  VoiceCommandModel? _lastParsedCommand;
  String? _lastServerConfirmedMessage;
  String? _errorMessage;

  // Disambiguation State
  bool _needsDisambiguation = false;
  List<CustomerModel> _ambiguousCustomers = [];

  // Excess Payment Confirmation State
  bool _needsExcessConfirmation = false;
  Map<String, dynamic>? _excessWarningData;

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get currentTranscript => _currentTranscript;
  VoiceCommandModel? get lastParsedCommand => _lastParsedCommand;
  String? get lastServerConfirmedMessage => _lastServerConfirmedMessage;
  String? get errorMessage => _errorMessage;

  bool get needsDisambiguation => _needsDisambiguation;
  List<CustomerModel> get ambiguousCustomers => _ambiguousCustomers;
  bool get needsExcessConfirmation => _needsExcessConfirmation;
  Map<String, dynamic>? get excessWarningData => _excessWarningData;

  void setSpeechProvider(ISpeechRecognitionProvider provider) {
    _speechProvider = provider;
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  Future<void> startListening() async {
    _currentTranscript = '';
    _errorMessage = null;
    _lastServerConfirmedMessage = null;
    _needsDisambiguation = false;
    _needsExcessConfirmation = false;

    final initialized = await _speechProvider.initialize();
    if (!initialized) {
      _errorMessage = "మైక్రోఫోన్ అనుమతి లేదా స్పీచ్ సర్వీస్ అందుబాటులో లేదు.";
      notifyListeners();
      return;
    }

    _isListening = true;
    notifyListeners();

    await _speechProvider.startListening(
      onResult: (transcript, isFinal) {
        _currentTranscript = transcript;
        notifyListeners();
        if (isFinal) {
          _isListening = false;
          notifyListeners();
          processTranscript(transcript);
        }
      },
      onError: (err) {
        _isListening = false;
        _errorMessage = "వాయిస్ గుర్తుపట్టడంలో లోపం: $err";
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    await _speechProvider.stopListening();
    notifyListeners();
    if (_currentTranscript.isNotEmpty) {
      await processTranscript(_currentTranscript);
    }
  }

  Future<void> processTranscript(String transcript) async {
    if (transcript.trim().isEmpty) return;

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final parsed = await _apiService.parseVoiceCommand(transcript);
      _lastParsedCommand = parsed;

      if (parsed.requiresDisambiguation && parsed.matchedCustomers.length > 1) {
        // Disambiguation needed: multiple customers found!
        _needsDisambiguation = true;
        _ambiguousCustomers = parsed.matchedCustomers;
        _isProcessing = false;
        notifyListeners();
        if (parsed.clarificationQuestion != null) {
          await _tts.speakTelugu(parsed.clarificationQuestion!);
        }
        return;
      }

      if (parsed.matchedCustomers.isEmpty) {
        _errorMessage = parsed.clarificationQuestion ?? "'${parsed.customerName}' ఖాతా కనపడలేదు.";
        _isProcessing = false;
        notifyListeners();
        if (parsed.clarificationQuestion != null) {
          await _tts.speakTelugu(parsed.clarificationQuestion!);
        }
        return;
      }

      // Single matched customer
      final customer = parsed.matchedCustomers.first;
      await executeCommandForCustomer(customer, parsed);
    } catch (e) {
      _isProcessing = false;
      _errorMessage = "సర్వర్ తో అనుసంధానం కాలేదు: $e";
      notifyListeners();
    }
  }

  Future<void> selectDisambiguatedCustomer(CustomerModel customer) async {
    _needsDisambiguation = false;
    _ambiguousCustomers = [];
    notifyListeners();

    if (_lastParsedCommand != null) {
      await executeCommandForCustomer(customer, _lastParsedCommand!);
    }
  }

  Future<void> executeCommandForCustomer(CustomerModel customer, VoiceCommandModel command,
      {bool allowExcess = false}) async {
    _isProcessing = true;
    notifyListeners();

    try {
      if (command.intent == 'ADD_CREDIT' && command.amountPaise != null) {
        final res = await _apiService.recordCredit(customer.id, command.amountPaise!);
        _lastServerConfirmedMessage = res['teluguSpeechMessage'];
        _isProcessing = false;
        notifyListeners();
        await _tts.speakTelugu(_lastServerConfirmedMessage!);
      } else if (command.intent == 'RECORD_PAYMENT' && command.amountPaise != null) {
        final res = await _apiService.recordPayment(
          customer.id,
          command.amountPaise!,
          allowExcessAsAdvance: allowExcess,
        );

        if (res['error'] == 'EXCESS_PAYMENT_CONFIRMATION_REQUIRED') {
          _needsExcessConfirmation = true;
          _excessWarningData = res;
          _isProcessing = false;
          notifyListeners();
          if (res['messageTelugu'] != null) {
            await _tts.speakTelugu(res['messageTelugu']);
          }
          return;
        }

        _lastServerConfirmedMessage = res['teluguSpeechMessage'];
        _isProcessing = false;
        notifyListeners();
        await _tts.speakTelugu(_lastServerConfirmedMessage!);
      } else if (command.intent == 'QUERY_BALANCE') {
        final bal = await _apiService.getCustomerBalance(customer.id);
        _lastServerConfirmedMessage = bal['teluguSpeechMessage'];
        _isProcessing = false;
        notifyListeners();
        await _tts.speakTelugu(_lastServerConfirmedMessage!);
      } else {
        _isProcessing = false;
        _errorMessage = command.clarificationQuestion ?? "దయచేసి కమాండ్ స్పష్టంగా చెప్పండి.";
        notifyListeners();
        if (command.clarificationQuestion != null) {
          await _tts.speakTelugu(command.clarificationQuestion!);
        }
      }
    } catch (e) {
      _isProcessing = false;
      _errorMessage = "లావాదేవీ నమోదు కాలేదు: $e";
      notifyListeners();
    }
  }

  void cancelDisambiguation() {
    _needsDisambiguation = false;
    _ambiguousCustomers = [];
    _isProcessing = false;
    notifyListeners();
  }

  void cancelExcessConfirmation() {
    _needsExcessConfirmation = false;
    _excessWarningData = null;
    _isProcessing = false;
    notifyListeners();
  }
}
