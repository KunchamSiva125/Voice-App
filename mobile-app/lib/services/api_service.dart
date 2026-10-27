import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import '../models/customer_model.dart';
import '../models/voice_command_model.dart';
import '../models/daily_report_model.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();

  Future<Map<String, String>> _getHeaders({bool includeIdempotency = false}) async {
    final token = await _storageService.getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (includeIdempotency) {
      headers['Idempotency-Key'] = _uuid.v4();
    }
    return headers;
  }

  String _parseErrorMessage(http.Response response, {String defaultMessage = 'Operation failed'}) {
    if (response.statusCode == 401) {
      return 'యూజర్‌నేమ్ లేదా పాస్‌వర్డ్ తప్పు (Invalid username or password).';
    }
    if (response.statusCode == 403) {
      return 'ఈ ఆపరేషన్‌కు అనుమతి లేదు (Access denied).';
    }
    if (response.statusCode == 530 || response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
      return 'క్లౌడ్‌ఫ్లేర్ లేదా సర్వర్ టన్నెల్ ఆఫ్ అయింది (Cloudflare tunnel down/inactive).\nదయచేసి మీ కంప్యూటర్‌లో start-tunnel.bat ప్రారంభించి కొత్త URL ను Server Settings లో ఇవ్వండి.';
    }
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null && body['message'].toString().trim().isNotEmpty) {
        return body['message'].toString();
      }
    } catch (_) {}
    return '$defaultMessage (Status ${response.statusCode})';
  }

  // Auth: Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(ApiConfig.coldStartTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_parseErrorMessage(response, defaultMessage: 'Login failed. Please verify credentials.'));
      }
    } on SocketException catch (_) {
      throw Exception('సర్వర్ అందుబాటులో లేదు (Server unreachable).\nదయచేసి ఇంటర్నెట్ కనెక్షన్ సరిచూసుకోండి.');
    } on TimeoutException catch (_) {
      throw Exception('క్లౌడ్ సర్వర్ మేల్కొనడంలో ఆలస్యమైంది (Server waking up timeout).\nదయచేసి కొన్ని సెకన్లు ఆగి మళ్ళీ లాగిన్ నొక్కండి.');
    } on http.ClientException catch (_) {
      throw Exception('సర్వర్‌కు కనెక్ట్ కాలేకపోయాము (Failed to connect to server).\nదయచేసి Server Settings లో సరైన URL ఇవ్వండి.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
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

  // Customers: Create New Customer
  Future<CustomerModel> createCustomer({
    required String name,
    List<String>? aliases,
    String? phoneNumber,
    String? notes,
    int? initialDebtPaise,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/customers');
    final headers = await _getHeaders();
    final body = {
      'name': name,
      'aliases': aliases ?? [],
      'phoneNumber': phoneNumber,
      'notes': notes,
    };

    final response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final customerData = jsonDecode(response.body);
      final customer = CustomerModel.fromJson(customerData);

      if (initialDebtPaise != null && initialDebtPaise > 0) {
        await recordCredit(customer.id, initialDebtPaise, description: 'ప్రారంభ బాకీ (Opening balance)');
      }

      return customer;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Failed to create customer');
    }
  }

  // Customers: Delete Customer
  Future<void> deleteCustomer(String customerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/customers/$customerId');
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers).timeout(ApiConfig.requestTimeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Failed to delete customer');
      } catch (_) {
        throw Exception('Failed to delete customer (status ${response.statusCode})');
      }
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

  // Customers: Get Transactions / Debt History with Dates for Proof
  Future<List<Map<String, dynamic>>> getCustomerTransactions(String customerId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/customers/$customerId/transactions?size=50');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List content = body['content'] ?? [];
      return content.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch customer transactions');
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
  Future<DailyReportModel> getDailyReport({String? date}) async {
    final query = date != null && date.isNotEmpty ? '?date=$date' : '';
    final url = Uri.parse('${ApiConfig.baseUrl}/reports/daily$query');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      return DailyReportModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load daily report');
    }
  }


  // Reports / Ledger: Transactions by Date Range
  Future<List<TransactionModel>> getTransactionsByRange({
    String? startDate,
    String? endDate,
    int page = 0,
    int size = 50,
  }) async {
    final params = <String>[];
    if (startDate != null && startDate.isNotEmpty) params.add('startDate=$startDate');
    if (endDate != null && endDate.isNotEmpty) params.add('endDate=$endDate');
    params.add('page=$page');
    params.add('size=$size');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = Uri.parse('${ApiConfig.baseUrl}/reports/transactions$queryString');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List content = body['content'] ?? [];
      return content.map((t) => TransactionModel.fromJson(t)).toList();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  // Transactions: Reverse Transaction (Double-entry compensatory reversal)
  Future<Map<String, dynamic>> reverseTransaction(String id, String reason) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/transactions/$id/reverse');
    final headers = await _getHeaders();
    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({'reason': reason}),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to reverse transaction');
    }
  }

  // Transactions: Import Opening Balance from Physical Notebook
  Future<Map<String, dynamic>> importOpeningBalance({
    required String customerId,
    required int amountPaise,
    String? notebookPageNumber,
    String? notes,
    String? openingDate,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/transactions/opening-balance');
    final headers = await _getHeaders(includeIdempotency: true);
    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({
            'customerId': customerId,
            'amountPaise': amountPaise,
            'notebookPageNumber': notebookPageNumber,
            'notes': notes,
            'openingDate': openingDate,
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to import opening balance');
    }
  }

  // Customers: Update Customer details
  Future<CustomerModel> updateCustomer(
    String id, {
    String? name,
    List<String>? aliases,
    String? phoneNumber,
    String? notes,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/customers/$id');
    final headers = await _getHeaders();
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (aliases != null) body['aliases'] = aliases;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (notes != null) body['notes'] = notes;

    final response = await http
        .patch(url, headers: headers, body: jsonEncode(body))
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      return CustomerModel.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to update customer');
    }
  }

  // Customers: Archive Customer
  Future<CustomerModel> archiveCustomer(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/customers/$id/archive');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      return CustomerModel.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to archive customer');
    }
  }

  // Customers: Merge Duplicate Customers
  Future<CustomerModel> mergeCustomers({
    required String sourceCustomerId,
    required String targetCustomerId,
    required String reason,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/customers/merge');
    final headers = await _getHeaders();
    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({
            'sourceCustomerId': sourceCustomerId,
            'targetCustomerId': targetCustomerId,
            'reason': reason,
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      return CustomerModel.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to merge customers');
    }
  }

  // Admin: List Users
  Future<List<UserModel>> getUsers() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/users');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers).timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((u) => UserModel.fromJson(u)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  // Admin: Create User
  Future<UserModel> createUser({
    required String name,
    required String username,
    required String password,
    required String role,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/users');
    final headers = await _getHeaders();
    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({
            'name': name,
            'username': username,
            'password': password,
            'role': role,
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to create user');
    }
  }

  // Admin: Toggle User Status
  Future<UserModel> toggleUserStatus(String id, bool active) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/users/$id/status');
    final headers = await _getHeaders();
    final response = await http
        .patch(
          url,
          headers: headers,
          body: jsonEncode({'active': active}),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to update user status');
    }
  }

}

