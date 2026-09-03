import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  String? _token;

  Future<String?> get token async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  Future<Map<String, String>> _headers() async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<Map<String, dynamic>> get(String path) async {
    final h = await _headers();
    final response = await http.get(
      Uri.parse('${ApiConfig.apiBase}$path'),
      headers: h,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final h = await _headers();
    final response = await http.post(
      Uri.parse('${ApiConfig.apiBase}$path'),
      headers: h,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final h = await _headers();
    final response = await http.put(
      Uri.parse('${ApiConfig.apiBase}$path'),
      headers: h,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final h = await _headers();
    final response = await http.patch(
      Uri.parse('${ApiConfig.apiBase}$path'),
      headers: h,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final h = await _headers();
    final response = await http.delete(
      Uri.parse('${ApiConfig.apiBase}$path'),
      headers: h,
    );
    return _handleResponse(response);
  }

  Future<http.Response> downloadBytes(String path) async {
    final h = await _headers();
    return await http.get(
      Uri.parse('${ApiConfig.apiBase}$path'),
      headers: h,
    );
  }

  Future<http.Response> downloadFile(String path) async {
    final h = await _headers();
    return await http.get(
      Uri.parse('${ApiConfig.apiBase}$path'),
      headers: h,
    );
  }

  Future<Map<String, dynamic>> uploadFile(String path, String filePath) async {
    final t = await token;
    final uri = Uri.parse('${ApiConfig.apiBase}$path');
    final request = http.MultipartRequest('POST', uri);
    if (t != null) request.headers['Authorization'] = 'Bearer $t';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: body['detail']?.toString() ?? 'Unknown error',
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final body = jsonDecode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: body['detail'] ?? 'Unknown error',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

final apiService = ApiService();
