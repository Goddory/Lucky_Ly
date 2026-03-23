import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiClient {
  final String baseUrl;
  String? _accessToken;

  ApiClient({required this.baseUrl, String? accessToken}) : _accessToken = accessToken;

  void updateToken(String token) {
    _accessToken = token;
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

  // Static helper to get base URL (matching main.dart logic)
  static String getBaseUrl() {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) return 'http://localhost:4000';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:4000';
    return 'http://localhost:4000';
  }
}
