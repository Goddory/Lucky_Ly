import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum AppThemeType {
  defaultTheme,
  tet,
  valentine,
}

AppThemeType appThemeTypeFromApi(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'tet':
      return AppThemeType.tet;
    case 'valentine':
      return AppThemeType.valentine;
    default:
      return AppThemeType.defaultTheme;
  }
}

String appThemeTypeToApi(AppThemeType type) {
  switch (type) {
    case AppThemeType.tet:
      return 'tet';
    case AppThemeType.valentine:
      return 'valentine';
    case AppThemeType.defaultTheme:
      return 'default';
  }
}

class ThemeProvider extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.defaultTheme;
  bool _isSyncing = false;
  String? _lastError;
  DateTime? _lastUpdatedAt;

  AppThemeType get currentTheme => _currentTheme;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  Map<String, dynamic> _decodeMap(String source) {
    if (source.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Future<void> syncThemeFromServer({
    required String apiBaseUrl,
    required String accessToken,
  }) async {
    if (apiBaseUrl.isEmpty || accessToken.isEmpty) {
      return;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http
          .get(
            Uri.parse('$apiBaseUrl/api/theme'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      final body = _decodeMap(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _currentTheme = appThemeTypeFromApi(body['theme']?.toString());
        final updatedAtRaw = body['updatedAt']?.toString();
        _lastUpdatedAt = updatedAtRaw == null ? null : DateTime.tryParse(updatedAtRaw);
      } else {
        _lastError = body['message']?.toString() ?? 'Cannot sync global theme.';
      }
    } catch (e) {
      _lastError = 'Cannot connect to theme service.';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> updateThemeAsAdmin({
    required AppThemeType theme,
    required String apiBaseUrl,
    required String accessToken,
  }) async {
    if (apiBaseUrl.isEmpty || accessToken.isEmpty) {
      _lastError = 'Missing API configuration.';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http
          .put(
            Uri.parse('$apiBaseUrl/api/theme'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({'theme': appThemeTypeToApi(theme)}),
          )
          .timeout(const Duration(seconds: 10));

      final body = _decodeMap(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _currentTheme = appThemeTypeFromApi(body['theme']?.toString());
        final updatedAtRaw = body['updatedAt']?.toString();
        _lastUpdatedAt = updatedAtRaw == null ? null : DateTime.tryParse(updatedAtRaw);
        return true;
      }

      _lastError = body['message']?.toString() ?? 'You do not have permission to update theme.';
      return false;
    } catch (e) {
      _lastError = 'Cannot update global theme right now.';
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
