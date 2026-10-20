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
}
