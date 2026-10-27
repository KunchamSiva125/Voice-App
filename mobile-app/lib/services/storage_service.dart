import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveAuthToken(String token) async {
    try {
      await _secureStorage.write(key: ApiConfig.tokenKey, value: token);
    } catch (e) {
      debugPrint('SecureStorage write error, using fallback SharedPreferences: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConfig.tokenKey, token);
      } catch (_) {}
    }
  }

  Future<String?> getAuthToken() async {
    try {
      final token = await _secureStorage.read(key: ApiConfig.tokenKey);
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      debugPrint('SecureStorage read error, using fallback SharedPreferences: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(ApiConfig.tokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserProfile(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiConfig.userKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  Future<UserModel?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(ApiConfig.userKey);
      if (jsonStr != null) {
        try {
          return UserModel.fromJson(jsonDecode(jsonStr));
        } catch (e) {
          return null;
        }
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
    }
    return null;
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.delete(key: ApiConfig.tokenKey);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(ApiConfig.userKey);
    } catch (_) {}
  }
}
