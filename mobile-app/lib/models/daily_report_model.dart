class DailyReportModel {
  final String businessDate;
  final int totalCreditsRecordedPaise;
  final double totalCreditsInRupees;
  final int totalPaymentsCollectedPaise;
  final double totalPaymentsInRupees;
  final int totalDiscountsPaise;
  final double totalDiscountsInRupees;
  final int totalOutstandingDebtPaise;
  final double totalOutstandingDebtInRupees;
  final int activeCustomersCount;
  final int transactionsCountToday;
  final String teluguSummary;

  DailyReportModel({
    required this.businessDate,
    required this.totalCreditsRecordedPaise,
    required this.totalCreditsInRupees,
    required this.totalPaymentsCollectedPaise,
    required this.totalPaymentsInRupees,
    required this.totalDiscountsPaise,
    required this.totalDiscountsInRupees,
    required this.totalOutstandingDebtPaise,
    required this.totalOutstandingDebtInRupees,
    required this.activeCustomersCount,
    required this.transactionsCountToday,
    required this.teluguSummary,
  });

  factory DailyReportModel.fromJson(Map<String, dynamic> json) {
    return DailyReportModel(
      businessDate: json['businessDate'] ?? '',
      totalCreditsRecordedPaise: json['totalCreditsRecordedPaise'] ?? 0,
      totalCreditsInRupees: (json['totalCreditsInRupees'] as num?)?.toDouble() ?? 0.0,
      totalPaymentsCollectedPaise: json['totalPaymentsCollectedPaise'] ?? 0,
      totalPaymentsInRupees: (json['totalPaymentsInRupees'] as num?)?.toDouble() ?? 0.0,
      totalDiscountsPaise: json['totalDiscountsPaise'] ?? 0,
      totalDiscountsInRupees: (json['totalDiscountsInRupees'] as num?)?.toDouble() ?? 0.0,
      totalOutstandingDebtPaise: json['totalOutstandingDebtPaise'] ?? 0,
      totalOutstandingDebtInRupees: (json['totalOutstandingDebtInRupees'] as num?)?.toDouble() ?? 0.0,
      activeCustomersCount: json['activeCustomersCount'] ?? 0,
      transactionsCountToday: json['transactionsCountToday'] ?? 0,
      teluguSummary: json['teluguSummary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessDate': businessDate,
      'totalCreditsRecordedPaise': totalCreditsRecordedPaise,
      'totalCreditsInRupees': totalCreditsInRupees,
      'totalPaymentsCollectedPaise': totalPaymentsCollectedPaise,
      'totalPaymentsInRupees': totalPaymentsInRupees,
      'totalDiscountsPaise': totalDiscountsPaise,
      'totalDiscountsInRupees': totalDiscountsInRupees,
      'totalOutstandingDebtPaise': totalOutstandingDebtPaise,
      'totalOutstandingDebtInRupees': totalOutstandingDebtInRupees,
      'activeCustomersCount': activeCustomersCount,
      'transactionsCountToday': transactionsCountToday,
      'teluguSummary': teluguSummary,
    };
  }
}
