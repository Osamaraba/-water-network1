import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static String baseUrl = 'http://192.168.1.102:8000';
  static const String defaultBaseUrl = 'http://192.168.1.102:8000';
  static const String _key = 'server_base_url';

  static String get apiBase => baseUrl;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && saved.isNotEmpty) {
        baseUrl = saved;
      }
    } catch (_) {}
  }

  static Future<void> setBaseUrl(String url) async {
    final trimmed = url.trim();
    baseUrl = trimmed.isEmpty ? defaultBaseUrl : trimmed;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, baseUrl);
    } catch (_) {}
  }
}
