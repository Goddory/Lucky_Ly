import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  String? _accessToken;
  // ignore: unused_field
  String? _refreshToken;
  String? _userEmail;
  Map<String, dynamic>? _userData;
  late final ApiClient _apiClient;

  AuthProvider() {
    _apiClient = ApiClient(baseUrl: ApiClient.getBaseUrl());
    _loadSession();
  }

  String? get accessToken => _accessToken;
  String? get userEmail => _userEmail;
  Map<String, dynamic>? get userData => _userData;
  ApiClient get apiClient => _apiClient;

  bool get isAuthenticated => _accessToken != null;

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _userEmail = prefs.getString('last_login_email');
    
    if (_accessToken != null) {
      _apiClient.updateToken(_accessToken!);
    }
    notifyListeners();
  }

  void setSession({
    required String accessToken,
    required String refreshToken,
    required String email,
    Map<String, dynamic>? userData,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userEmail = email;
    _userData = userData;
    
    _apiClient.updateToken(accessToken);
    notifyListeners();
  }

  Future<void> updatePrivacy(bool isSearchable) async {
    try {
      final response = await _apiClient.put('/api/users/me/privacy', {'isSearchable': isSearchable});
      if (response.statusCode == 200) {
        if (_userData != null) {
          _userData!['is_searchable'] = isSearchable;
        }
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
        _userEmail = _userData?['email'];
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
    _apiClient.updateToken('');
    notifyListeners();
  }
}
