class ApiConfig {
  // Default emulator host is 10.0.2.2 for Android Emulator, or physical LAN IP e.g. 192.168.1.100:8080
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  
  // Storage keys
  static const String tokenKey = 'tiffin_auth_token';
  static const String userKey = 'tiffin_user_profile';
  
  // Timeout settings
  static const Duration requestTimeout = Duration(seconds: 12);
}
