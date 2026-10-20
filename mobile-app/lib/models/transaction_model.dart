class TransactionModel {
  final String id;
  final String customerId;
  final String customerName;
  final String type;
  final int amountPaise;
  final double amountInRupees;
  final int balanceEffectPaise;
  final String status;
  final String effectiveAt;
  final String createdBy;
  final String? description;
  final String? correctionReason;
  final bool hasReversal;

  TransactionModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.amountPaise,
    required this.amountInRupees,
    required this.balanceEffectPaise,
    required this.status,
    required this.effectiveAt,
    required this.createdBy,
    this.description,
    this.correctionReason,
    required this.hasReversal,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? json['transactionId'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      type: json['type'] ?? 'CREDIT',
      amountPaise: json['amountPaise'] ?? 0,
      amountInRupees: (json['amountInRupees'] as num?)?.toDouble() ?? ((json['amountPaise'] ?? 0) / 100.0),
      balanceEffectPaise: json['balanceEffectPaise'] ?? 0,
      status: json['status'] ?? 'POSTED',
      effectiveAt: json['effectiveAt'] ?? json['createdAt'] ?? '',
      createdBy: json['createdBy'] ?? 'staff',
      description: json['description'],
      correctionReason: json['correctionReason'],
      hasReversal: json['hasReversal'] ?? false,
    );
  }
}
