import 'customer_model.dart';

class VoiceCommandModel {
  final String intent;
  final String? customerName;
  final int? amountPaise;
  final double? amountInRupees;
  final double confidence;
  final List<CustomerModel> matchedCustomers;
  final bool requiresDisambiguation;
  final bool requiresConfirmation;
  final String? confirmationMessage;
  final String? clarificationQuestion;
  final String rawTranscript;

  VoiceCommandModel({
    required this.intent,
    this.customerName,
    this.amountPaise,
    this.amountInRupees,
    required this.confidence,
    required this.matchedCustomers,
    required this.requiresDisambiguation,
    required this.requiresConfirmation,
    this.confirmationMessage,
    this.clarificationQuestion,
    required this.rawTranscript,
  });

  factory VoiceCommandModel.fromJson(Map<String, dynamic> json) {
    return VoiceCommandModel(
      intent: json['intent'] ?? 'UNKNOWN',
      customerName: json['customerName'],
      amountPaise: json['amountPaise'],
      amountInRupees: (json['amountInRupees'] as num?)?.toDouble(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      matchedCustomers: (json['matchedCustomers'] as List<dynamic>?)
              ?.map((c) => CustomerModel.fromJson(c))
              .toList() ??
          [],
      requiresDisambiguation: json['requiresDisambiguation'] ?? false,
      requiresConfirmation: json['requiresConfirmation'] ?? false,
      confirmationMessage: json['confirmationMessage'],
      clarificationQuestion: json['clarificationQuestion'],
      rawTranscript: json['rawTranscript'] ?? '',
    );
  }
}
