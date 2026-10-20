import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import '../models/customer_model.dart';
import '../models/transaction_model.dart';
import '../models/voice_command_model.dart';
import '../models/daily_report_model.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();

  Future<Map<String, String>> _getHeaders({bool includeIdempotency = false}) async {
    final token = await _storageService.getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (includeIdempotency) {
      headers['Idempotency-Key'] = _uuid.v4();
    }
    return headers;
  }

  // Auth: Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Login failed. Please verify credentials.');
    }
  }

  // Customers: Search & List
  Future<List<CustomerModel>> searchCustomers(String query) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/customers?search=$query&status=ACTIVE&size=50');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List content = body['content'] ?? [];
      return content.map((c) => CustomerModel.fromJson(c)).toList();
    } else {
      throw Exception('Failed to load customers');
    }
  }

  // Customers: Get Balance
  Future<Map<String, dynamic>> getCustomerBalance(String customerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/customers/$customerId/balance');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch balance');
    }
  }

  // Transactions: Record Credit
  Future<Map<String, dynamic>> recordCredit(String customerId, int amountPaise, {String? description}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/transactions/credit');
    final headers = await _getHeaders(includeIdempotency: true);
    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({
            'customerId': customerId,
            'amountPaise': amountPaise,
            'description': description ?? 'Voice Entry',
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to record credit');
    }
  }

  // Transactions: Record Payment
  Future<Map<String, dynamic>> recordPayment(String customerId, int amountPaise,
      {bool allowExcessAsAdvance = false, String? description}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/transactions/payment');
    final headers = await _getHeaders(includeIdempotency: true);
    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({
            'customerId': customerId,
            'amountPaise': amountPaise,
            'allowExcessAsAdvance': allowExcessAsAdvance,
            'description': description ?? 'Voice Payment',
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return body;
    } else if (body['error'] == 'EXCESS_PAYMENT_CONFIRMATION_REQUIRED') {
      return body; // Return structured warning for confirmation modal
    } else {
      throw Exception(body['message'] ?? 'Failed to record payment');
    }
  }

  // Transactions: Apply Discount
  Future<Map<String, dynamic>> applyDiscount(String customerId, int amountPaise, String reason) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/transactions/discount');
    final headers = await _getHeaders(includeIdempotency: true);
    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({
            'customerId': customerId,
            'amountPaise': amountPaise,
            'reason': reason,
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to apply discount');
    }
  }

  // Voice: Parse Command on Server
  Future<VoiceCommandModel> parseVoiceCommand(String rawTranscript) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/voice/parse');
    final headers = await _getHeaders();
    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({'rawTranscript': rawTranscript}),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      return VoiceCommandModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to parse voice command');
    }
  }

  // Reports: Daily Summary
  Future<DailyReportModel> getDailyReport() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/reports/daily');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      return DailyReportModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load daily report');
    }
  }
}
