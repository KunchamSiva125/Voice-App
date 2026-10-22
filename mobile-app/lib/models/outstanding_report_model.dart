class TopDebtorModel {
  final String customerId;
  final String customerName;
  final String? phoneNumber;
  final int balancePaise;
  final double balanceInRupees;

  TopDebtorModel({
    required this.customerId,
    required this.customerName,
    this.phoneNumber,
    required this.balancePaise,
    required this.balanceInRupees,
  });

  factory TopDebtorModel.fromJson(Map<String, dynamic> json) {
    final paise = json['balancePaise'] ?? 0;
    return TopDebtorModel(
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      phoneNumber: json['phoneNumber'],
      balancePaise: paise,
      balanceInRupees: (json['balanceInRupees'] as num?)?.toDouble() ?? (paise / 100.0),
    );
  }
}

class OutstandingReportModel {
  final int totalOutstandingDebtPaise;
  final double totalOutstandingDebtInRupees;
  final int totalDebtorsCount;
  final List<TopDebtorModel> topDebtors;

  OutstandingReportModel({
    required this.totalOutstandingDebtPaise,
    required this.totalOutstandingDebtInRupees,
    required this.totalDebtorsCount,
    required this.topDebtors,
  });

  factory OutstandingReportModel.fromJson(Map<String, dynamic> json) {
    final paise = json['totalOutstandingDebtPaise'] ?? 0;
    final debtorsList = (json['topDebtors'] as List<dynamic>?) ?? [];
    return OutstandingReportModel(
      totalOutstandingDebtPaise: paise,
      totalOutstandingDebtInRupees: (json['totalOutstandingDebtInRupees'] as num?)?.toDouble() ?? (paise / 100.0),
      totalDebtorsCount: json['totalDebtorsCount'] ?? 0,
      topDebtors: debtorsList.map((d) => TopDebtorModel.fromJson(d)).toList(),
    );
  }
}
