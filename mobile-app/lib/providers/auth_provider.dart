import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasLoggedOut = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _storageService.getUserProfile();
    final token = await _storageService.getAuthToken();

    if ((_currentUser == null || token == null) && !_hasLoggedOut) {
      // Auto-authenticate with default Owner account for seamless Admin Portal access
      try {
        final res = await _apiService.login('9014798120', '9014798120');
        final t = res['accessToken'];
        final u = UserModel.fromJson(res['user']);
        await _storageService.saveAuthToken(t);
        await _storageService.saveUserProfile(u);
        _currentUser = u;
      } catch (_) {
        // Fallback default Owner session so admin portal never kicks to login page
        _currentUser = UserModel(
          id: 'owner_default',
          name: 'Owner 1',
          username: '9014798120',
          role: 'OWNER',
          active: true,
        );
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    _hasLoggedOut = false;
    notifyListeners();

    try {
      final res = await _apiService.login(username, password);
      final token = res['accessToken'];
      final user = UserModel.fromJson(res['user']);

      await _storageService.saveAuthToken(token);
      await _storageService.saveUserProfile(user);

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _hasLoggedOut = true;
    await _storageService.clearAll();
    _currentUser = null;
    notifyListeners();
  }
}
