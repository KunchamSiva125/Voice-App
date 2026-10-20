import 'package:flutter/material.dart';
import '../models/daily_report_model.dart';
import '../services/api_service.dart';

class LedgerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  DailyReportModel? _dailyReport;
  bool _isLoading = false;
  bool _isOnline = true;

  DailyReportModel? get dailyReport => _dailyReport;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  Future<void> fetchTodaySummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      _dailyReport = await _apiService.getDailyReport();
      _isOnline = true;
    } catch (e) {
      debugPrint('Error loading daily report: $e');
      _isOnline = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
