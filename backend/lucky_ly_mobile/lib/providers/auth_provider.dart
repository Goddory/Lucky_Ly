import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  String? _refreshToken;
  String? _userEmail;
  Map<String, dynamic>? _userData;
  bool _isSessionHydrated = false;
  late final ApiClient _apiClient;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  AuthProvider() {
    _apiClient = ApiClient(baseUrl: ApiClient.getBaseUrl());
    _loadSession();
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userEmail => _userEmail;
  Map<String, dynamic>? get userData => _userData;
  bool get isSessionHydrated => _isSessionHydrated;
  ApiClient get apiClient => _apiClient;

  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  String? _normalizeToken(String? token) {
    if (token == null) return null;
    final trimmed = token.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _normalizeEmail(String? email) {
    if (email == null) return null;
    final normalized = email.trim().toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }

  Future<void> _persistSessionToLocal() async {
    final prefs = await SharedPreferences.getInstance();

    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('accessToken', _accessToken!);
    } else {
      await prefs.remove('access_token');
      await prefs.remove('accessToken');
    }

    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
      await prefs.setString('refreshToken', _refreshToken!);
    } else {
      await prefs.remove('refresh_token');
      await prefs.remove('refreshToken');
    }

    if (_userEmail != null) {
      await prefs.setString('last_login_email', _userEmail!);
      if (_refreshToken != null) {
        await _secureStorage.write(
          key: 'refresh_token_${_userEmail!}',
          value: _refreshToken!,
        );
      }
    } else {
      await prefs.remove('last_login_email');
    }

    if (_userData != null) {
      await prefs.setString('user_data_json', jsonEncode(_userData));
    } else {
      await prefs.remove('user_data_json');
    }
  }

  Future<void> _clearSessionFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final email = _normalizeEmail(_userEmail ?? prefs.getString('last_login_email'));

    await prefs.remove('access_token');
    await prefs.remove('accessToken');
    await prefs.remove('refresh_token');
    await prefs.remove('refreshToken');
    await prefs.remove('user_data_json');
    await prefs.remove('last_login_email');

    if (email != null) {
      await _secureStorage.delete(key: 'refresh_token_$email');
    }
  }

  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = _normalizeToken(
        prefs.getString('access_token') ?? prefs.getString('accessToken'),
      );
      _refreshToken = _normalizeToken(
        prefs.getString('refresh_token') ?? prefs.getString('refreshToken'),
      );
      _userEmail = _normalizeEmail(prefs.getString('last_login_email'));

      final rawUser = prefs.getString('user_data_json');
      if (rawUser != null && rawUser.isNotEmpty) {
        final parsed = jsonDecode(rawUser);
        if (parsed is Map<String, dynamic>) {
          _userData = parsed;
        }
      }

      _userEmail = _userEmail ?? _normalizeEmail(_userData?['email']?.toString());
      _apiClient.updateToken(_accessToken);
    } catch (e) {
      debugPrint('Error loading local session: $e');
    } finally {
      _isSessionHydrated = true;
      notifyListeners();
    }
  }

  void setSession({
    required String accessToken,
    required String refreshToken,
    required String email,
    Map<String, dynamic>? userData,
  }) {
    _accessToken = _normalizeToken(accessToken);
    _refreshToken = _normalizeToken(refreshToken);
    _userData = userData ?? _userData;
    _userEmail = _normalizeEmail(_userData?['email']?.toString()) ?? _normalizeEmail(email);

    _apiClient.updateToken(_accessToken);
    unawaited(_persistSessionToLocal());
    notifyListeners();
  }

  Future<void> updatePrivacy(bool isSearchable) async {
    try {
      final response = await _apiClient.put('/api/users/me/privacy', {'isSearchable': isSearchable});
      if (response.statusCode == 200) {
        if (_userData != null) {
          _userData!['is_searchable'] = isSearchable;
        }
        unawaited(_persistSessionToLocal());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating privacy: $e');
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _apiClient.put('/api/users/me/fcm-token', {'fcmToken': fcmToken});
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiClient.get('/api/users/me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userData = data['user'];
        _userEmail = _normalizeEmail(_userData?['email']?.toString()) ?? _userEmail;
        unawaited(_persistSessionToLocal());
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  void logout() {
    _accessToken = null;
    _refreshToken = null;
    _userEmail = null;
    _userData = null;
    _apiClient.updateToken(null);
    unawaited(_clearSessionFromLocal());
    notifyListeners();
  }
}
