import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';

class CustomerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> searchCustomers(String query) async {
    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _apiService.searchCustomers(query);
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
