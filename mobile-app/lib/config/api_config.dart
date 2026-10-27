import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const String _prefKey = 'custom_server_base_url';
  static String? _customBaseUrl;

  static const String serverUrl = 'https://voice-app-0cys.onrender.com/api';
  static const String defaultCloudUrl = serverUrl;
  static const String defaultLanUrl = serverUrl;
  static const String defaultWebUrl = serverUrl;

  static Future<void> loadCustomBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        if (!saved.contains('voice-app-0cys.onrender.com')) {
          // Auto-migrate from any old local LAN IP or tunnels to the permanent Render backend
          await resetToDefault();
        } else {
          _customBaseUrl = saved.trim();
        }
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
    return _customBaseUrl ?? serverUrl;
  }

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    return serverUrl;
  }

  static const String liveAdminPortalUrl = 'https://mahima-tiffin-admin.onrender.com';

  static String get adminPortalUrl {
    return liveAdminPortalUrl;
  }
  
  // Storage keys
  static const String tokenKey = 'tiffin_auth_token';
  static const String userKey = 'tiffin_user_profile';
  
  // Timeout settings
  static const Duration requestTimeout = Duration(seconds: 35);
  static const Duration coldStartTimeout = Duration(seconds: 75);

  /// Silently pings the backend to initiate a cold start in the background as soon as the app opens.
  static void prewarmServer() {
    try {
      final uri = Uri.parse('$baseUrl/health');
      http.get(
        uri,
        headers: {'ngrok-skip-browser-warning': 'true', 'Accept': 'application/json'},
      ).timeout(coldStartTimeout).catchError((_) => http.Response('', 500));
    } catch (_) {}
  }

  /// Test connectivity to a given server base URL
  static Future<Map<String, dynamic>> testConnection(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.endsWith('/api')) {
      cleanUrl = '$cleanUrl/api';
    }
    try {
      final res = await http.get(
        Uri.parse('$cleanUrl/health'),
        headers: {'ngrok-skip-browser-warning': 'true', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return {'success': true, 'message': 'సర్వర్ సిద్ధంగా ఉంది (Connected: Status UP)'};
      } else if (res.statusCode == 530 || res.statusCode == 502) {
        return {'success': false, 'message': 'క్లౌడ్‌ఫ్లేర్ టన్నెల్ ఆఫ్ అయింది (Cloudflare tunnel down)'};
      } else {
        return {'success': false, 'message': 'సర్వర్ స్టేటస్ కోడ్: ${res.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'కనెక్ట్ కాలేకపోయాము (Unreachable: Check Wi-Fi or tunnel)'};
    }
  }
}
