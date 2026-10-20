class CustomerModel {
  final String id;
  final String name;
  final String normalizedName;
  final List<String> aliases;
  final String? phoneNumber;
  final String? notes;
  final String status;
  final int outstandingBalancePaise;
  final double balanceInRupees;

  CustomerModel({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.aliases,
    this.phoneNumber,
    this.notes,
    required this.status,
    required this.outstandingBalancePaise,
    required this.balanceInRupees,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      normalizedName: json['normalizedName'] ?? '',
      aliases: (json['aliases'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      phoneNumber: json['phoneNumber'],
      notes: json['notes'],
      status: json['status'] ?? 'ACTIVE',
      outstandingBalancePaise: json['outstandingBalancePaise'] ?? 0,
      balanceInRupees: (json['balanceInRupees'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
