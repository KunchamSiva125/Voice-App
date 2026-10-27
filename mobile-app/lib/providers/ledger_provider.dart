import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_report_model.dart';
import '../services/api_service.dart';

class LedgerProvider extends ChangeNotifier {
  static const String _cacheKey = 'cached_daily_report_summary';
  final ApiService _apiService = ApiService();

  DailyReportModel? _dailyReport;
  bool _isLoading = false;
  bool _isOnline = true;

  DailyReportModel? get dailyReport => _dailyReport;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  LedgerProvider() {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        if (_dailyReport == null) {
          _dailyReport = DailyReportModel.fromJson(jsonDecode(cachedJson));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached daily report: $e');
    }
  }

  Future<void> _saveToCache(DailyReportModel report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(report.toJson()));
    } catch (e) {
      debugPrint('Error saving daily report cache: $e');
    }
  }

  Future<void> fetchTodaySummary() async {
    // If we don't have cached data yet, show loading
    if (_dailyReport == null) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final fresh = await _apiService.getDailyReport();
      _dailyReport = fresh;
      _isOnline = true;
      _saveToCache(fresh);
    } catch (e) {
      debugPrint('Error loading daily report: $e');
      _isOnline = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
