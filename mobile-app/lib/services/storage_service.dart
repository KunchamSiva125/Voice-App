import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: ApiConfig.tokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: ApiConfig.tokenKey);
  }

  Future<void> saveUserProfile(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(ApiConfig.userKey);
    if (jsonStr != null) {
      try {
        return UserModel.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> clearAll() async {
    await _secureStorage.delete(key: ApiConfig.tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.userKey);
  }
}
