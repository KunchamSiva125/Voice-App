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
  String? _unmatchedCustomerName;
  double? _unmatchedAmount;

  // Disambiguation State
  bool _needsDisambiguation = false;
  List<CustomerModel> _ambiguousCustomers = [];

  // Excess Payment Confirmation State
  bool _needsExcessConfirmation = false;
  Map<String, dynamic>? _excessWarningData;

  // Delete Customer Confirmation State
  bool _needsDeleteConfirmation = false;
  CustomerModel? _deleteCandidate;

  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get currentTranscript => _currentTranscript;
  VoiceCommandModel? get lastParsedCommand => _lastParsedCommand;
  String? get lastServerConfirmedMessage => _lastServerConfirmedMessage;
  String? get errorMessage => _errorMessage;
  String? get unmatchedCustomerName => _unmatchedCustomerName;
  double? get unmatchedAmount => _unmatchedAmount;

  bool get needsDisambiguation => _needsDisambiguation;
  List<CustomerModel> get ambiguousCustomers => _ambiguousCustomers;
  bool get needsExcessConfirmation => _needsExcessConfirmation;
  Map<String, dynamic>? get excessWarningData => _excessWarningData;
  bool get needsDeleteConfirmation => _needsDeleteConfirmation;
  CustomerModel? get deleteCandidate => _deleteCandidate;

  void setSpeechProvider(ISpeechRecognitionProvider provider) {
    _speechProvider = provider;
  }

  Future<void> repeatLastVoiceMessage() async {
    if (_lastServerConfirmedMessage != null && _lastServerConfirmedMessage!.isNotEmpty) {
      await _tts.speakTelugu(_lastServerConfirmedMessage!);
    } else if (_errorMessage != null && _errorMessage!.isNotEmpty) {
      await _tts.speakTelugu(_errorMessage!);
    }
  }

  void clearMessages() {
    _lastServerConfirmedMessage = null;
    _errorMessage = null;
    _unmatchedCustomerName = null;
    _unmatchedAmount = null;
    notifyListeners();
  }

  Future<void> queryCustomerBalanceDirectly(CustomerModel customer) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final bal = await _apiService.getCustomerBalance(customer.id);
      _lastServerConfirmedMessage = bal['teluguSpeechMessage'] ??
          "${customer.name} గారి ప్రస్తుత బాకీ ${bal['balanceInRupees']} రూపాయలు.";
      _isProcessing = false;
      notifyListeners();
      await _tts.speakTelugu(_lastServerConfirmedMessage!);
    } catch (e) {
      _isProcessing = false;
      _errorMessage = "బాకీ వివరాలు పొందడంలో లోపం: $e";
      notifyListeners();
    }
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
    _unmatchedCustomerName = null;
    _unmatchedAmount = null;
    _needsDisambiguation = false;
    _needsExcessConfirmation = false;
    _needsDeleteConfirmation = false;
    _deleteCandidate = null;

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

      // Handle voice command to add a new customer
      if (parsed.intent == 'ADD_CUSTOMER') {
        if (parsed.matchedCustomers.isNotEmpty) {
          final existing = parsed.matchedCustomers.first;
          _lastServerConfirmedMessage = "${existing.name} గారి ఖాతా ఇప్పటికే ఉంది. వారి ప్రస్తుత బాకీ ₹${existing.balanceInRupees.toStringAsFixed(2)}.";
          _isProcessing = false;
          notifyListeners();
          await _tts.speakTelugu(_lastServerConfirmedMessage!);
          return;
        } else if (parsed.customerName != null && parsed.customerName!.isNotEmpty) {
          final created = await _apiService.createCustomer(
            name: parsed.customerName!,
            aliases: [parsed.customerName!],
            initialDebtPaise: parsed.amountPaise ?? 0,
          );
          String msg = "${created.name} గారి కొత్త ఖాతా విజయవంతంగా చేర్చబడింది.";
          if (parsed.amountInRupees != null && parsed.amountInRupees! > 0) {
            msg += " ${parsed.amountInRupees!.toInt()} రూపాయలు అప్పు నమోదైంది.";
          }
          _lastServerConfirmedMessage = msg;
          _isProcessing = false;
          notifyListeners();
          await _tts.speakTelugu(msg);
          return;
        }
      }

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
        _unmatchedCustomerName = parsed.customerName;
        _unmatchedAmount = parsed.amountInRupees;
        _errorMessage = parsed.clarificationQuestion ?? "'${parsed.customerName ?? "కస్టమర్"}' ఖాతా కనపడలేదు.";
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
      } else if (command.intent == 'DELETE_CUSTOMER') {
        _deleteCandidate = customer;
        _needsDeleteConfirmation = true;
        _isProcessing = false;
        notifyListeners();
        String confirmMsg = "${customer.name} గారి ఖాతాను తొలగించడానికి నిర్ధారించండి.";
        if (customer.outstandingBalancePaise > 0) {
          confirmMsg += " హెచ్చరిక: వీరి ప్రస్తుత బాకీ ${(customer.outstandingBalancePaise / 100).toStringAsFixed(0)} రూపాయలు ఉంది.";
        }
        await _tts.speakTelugu(confirmMsg);
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

  Future<void> confirmDeleteCandidate() async {
    if (_deleteCandidate == null) return;
    final target = _deleteCandidate!;
    _isProcessing = true;
    _needsDeleteConfirmation = false;
    notifyListeners();

    try {
      await _apiService.deleteCustomer(target.id);
      final msg = "${target.name} గారి ఖాతా విజయవంతంగా తొలగించబడింది.";
      _lastServerConfirmedMessage = msg;
      _deleteCandidate = null;
      _isProcessing = false;
      notifyListeners();
      await _tts.speakTelugu(msg);
    } catch (e) {
      _isProcessing = false;
      _errorMessage = "ఖాతా తొలగించడంలో లోపం: $e";
      notifyListeners();
    }
  }

  void cancelDeleteCandidate() {
    _needsDeleteConfirmation = false;
    _deleteCandidate = null;
    _isProcessing = false;
    notifyListeners();
  }
}
