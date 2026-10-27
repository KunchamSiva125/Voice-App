import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';

class CustomerProvider extends ChangeNotifier {
  static const String _cacheKey = 'cached_customers_list';
  final ApiService _apiService = ApiService();

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  CustomerProvider() {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List list = jsonDecode(cachedJson);
        if (_customers.isEmpty && list.isNotEmpty) {
          _customers = list.map((c) => CustomerModel.fromJson(c)).toList();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached customers: $e');
    }
  }

  Future<void> _saveToCache(List<CustomerModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((c) => c.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving customers cache: $e');
    }
  }

  Future<void> searchCustomers(String query) async {
    _searchQuery = query;
    // If we have cached customers and this is a general fetch, don't flash a full blank spinner
    if (_customers.isEmpty || query.isNotEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final fresh = await _apiService.searchCustomers(query);
      _customers = fresh;
      if (query.trim().isEmpty) {
        _saveToCache(fresh);
      }
    } catch (e) {
      debugPrint('Error searching customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await searchCustomers(_searchQuery);
  }

  Future<CustomerModel> createCustomer({
    required String name,
    List<String>? aliases,
    String? phoneNumber,
    String? notes,
    int? initialDebtPaise,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final customer = await _apiService.createCustomer(
        name: name,
        aliases: aliases,
        phoneNumber: phoneNumber,
        notes: notes,
        initialDebtPaise: initialDebtPaise,
      );
      await searchCustomers(_searchQuery);
      return customer;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.deleteCustomer(customerId);
      await searchCustomers(_searchQuery);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
