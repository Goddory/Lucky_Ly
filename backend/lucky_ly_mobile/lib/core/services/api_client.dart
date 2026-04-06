import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiClient {
  final String baseUrl;
  String? _accessToken;

  ApiClient({required this.baseUrl, String? accessToken}) : _accessToken = _normalizeToken(accessToken);

  static String? _normalizeToken(String? token) {
    if (token == null) return null;
    final trimmed = token.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void updateToken(String? token) {
    _accessToken = _normalizeToken(token);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<http.Response> get(String path) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('GET $url');
    return http.get(url, headers: _headers);
  }

  Future<http.Response> post(String path, dynamic body) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('POST $url');
    return http.post(url, headers: _headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String path, dynamic body) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('PUT $url');
    return http.put(url, headers: _headers, body: jsonEncode(body));
  }

  Future<http.Response> patch(String path, dynamic body) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('PATCH $url');
    return http.patch(url, headers: _headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String path) async {
    final url = Uri.parse('$baseUrl$path');
    debugPrint('DELETE $url');
    return http.delete(url, headers: _headers);
  }

  static String getBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) return 'http://localhost:4000';
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return 'https://lucky-ly-api.onrender.com';
    }
    
    return 'http://localhost:4000';
  }
}
