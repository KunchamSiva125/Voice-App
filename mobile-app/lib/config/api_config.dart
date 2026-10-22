import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _prefKey = 'custom_server_base_url';
  static String? _customBaseUrl;

  static const String defaultLanUrl = 'http://10.32.90.82:8080/api';
  static const String defaultWebUrl = 'http://localhost:8080/api';

  static Future<void> loadCustomBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _customBaseUrl = saved.trim();
      }
    } catch (_) {}
  }

  static Future<void> setCustomBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.endsWith('/api')) {
      cleanUrl = '$cleanUrl/api';
    }
    _customBaseUrl = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, cleanUrl);
    } catch (_) {}
  }

  static Future<void> resetToDefault() async {
    _customBaseUrl = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  static String get currentConfiguredUrl {
    return _customBaseUrl ?? ((kIsWeb || defaultTargetPlatform == TargetPlatform.windows) ? defaultWebUrl : defaultLanUrl);
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return defaultWebUrl;
    }
    return defaultLanUrl;
  }

  static String get adminPortalUrl {
    try {
      final uri = Uri.parse(baseUrl);
      return '${uri.scheme}://${uri.host}:5173';
    } catch (_) {
      return 'http://localhost:5173';
    }
  }
  
  // Storage keys
  static const String tokenKey = 'tiffin_auth_token';
  static const String userKey = 'tiffin_user_profile';
  
  // Timeout settings
  static const Duration requestTimeout = Duration(seconds: 15);
}
