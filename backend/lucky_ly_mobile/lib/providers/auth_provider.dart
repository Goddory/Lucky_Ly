import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/services/api_client.dart';

/// AuthProvider - State management cho authentication & user session
/// 
/// Extends ChangeNotifier để:
/// - Notify listeners khi auth state thay đổi
/// - Integration với Provider pattern
/// - Tạo access token, user data, email globally
/// 
/// Các tính năng:
/// 1. Session Persistence - Lưu token đến SharedPreferences & SecureStorage
/// 2. Token Management - Normalize, validate, automatic API client update
/// 3. Session Hydration - Load previous session khi app start
/// 4. User Profile - Fetch & cache user data
/// 5. Privacy Settings - Control searchability (public/private profile)
/// 6. FCM Token - Register device token cho push notifications
/// 7. Logout - Clear all session data
/// 
/// Storage Strategy:
/// - AccessToken: SharedPreferences (not sensitive, quick access)
/// - RefreshToken: SecureStorage (sensitive, encrypted per-user)
/// - UserData: SharedPreferences (cache user info)
/// - Last Email: SharedPreferences (remember last login)
/// 
/// Lifecycle:
/// 1. App Start: Constructor → _loadSession() → hydrate from local storage
/// 2. Login: setSession() → _persistSessionToLocal() → notify listeners
/// 3. API Calls: _apiClient use accessToken (auto-added to headers)
/// 4. Logout: logout() → _clearSessionFromLocal() → clear all data
class AuthProvider extends ChangeNotifier {
  /// JWT access token - used for API authentication
  /// 
  /// Lifecycle:
  /// - null: User logged out
  /// - Set on login via setSession()
  /// - Stored in SharedPreferences
  /// - Auto-added to API request headers
  String? _accessToken;
  
  /// JWT refresh token - used to get new accessToken when expired
  /// 
  /// Lifecycle:
  /// - null: User logged out
  /// - Set on login via setSession()
  /// - Stored in SecureStorage (encrypted, per-user)
  /// - Used by backend to verify refresh requests
  String? _refreshToken;
  
  /// Last logged-in email - remember user for next login
  String? _userEmail;
  
  /// Cached user profile data - avoid fetching repeatedly
  /// 
  /// Contains:
  /// - _id: User ID
  /// - fullName: Tên đầy đủ
  /// - email: Email address
  /// - avatar: Avatar URL
  /// - is_searchable: Privacy setting
  /// - etc.
  Map<String, dynamic>? _userData;
  
  /// Flag: Has local session been loaded? (prevent loading twice)
  /// 
  /// Workflow:
  /// - false: Constructor started, waiting for _loadSession()
  /// - true: _loadSession() completed (error or success)
  /// 
  /// Usage:
  /// ```dart
  /// if (authProvider.isSessionHydrated) {
  ///   // Bắt đầu build app
  /// } else {
  ///   // Show splash screen
  /// }
  /// ```
  bool _isSessionHydrated = false;
  
  /// HTTP client - injects accessToken automatically
  /// 
  /// Constructor tạo instance:
  /// ```dart
  /// _apiClient = ApiClient(baseUrl: ApiClient.getBaseUrl());
  /// ```
  /// 
  /// Mỗi API request sᷝ gọi: updateToken(accessToken)
  late final ApiClient _apiClient;
  
  /// Secure storage - đổi với dữ liệu nhấy (refresh token)
  /// 
  /// Platform:
  /// - iOS: Keychain (encrypted at OS level)
  /// - Android: Keystore (encrypted at OS level)
  /// - Web: localStorage (not truly secure, use HTTP-only cookie instead)
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Constructor - initialize AuthProvider
  /// 
  /// Quy trình:
  /// 1. Tạo ApiClient instance (without token initially)
  /// 2. Gọi _loadSession() để hydrate session từ local storage
  /// 3. Khi _loadSession() hoàn tẤt:
  ///    - Set _isSessionHydrated = true
  ///    - Call notifyListeners() để notify listeners
  /// 
  /// Best Practice:
  /// ```dart
  /// final authProvider = context.read<AuthProvider>();
  /// // authProvider.isSessionHydrated = true khi app ready
  /// ```
  AuthProvider() {
    _apiClient = ApiClient(baseUrl: ApiClient.getBaseUrl());
    _loadSession();
  }

  /// Public getters để access auth state
  
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get userEmail => _userEmail;
  Map<String, dynamic>? get userData => _userData;
  bool get isSessionHydrated => _isSessionHydrated;
  ApiClient get apiClient => _apiClient;

  /// Check nếu user đã authenticated
  /// 
  /// Return: true nếu accessToken exists và not empty
  /// Usage:
  /// ```dart
  /// if (authProvider.isAuthenticated) {
  ///   // Show main screens
  /// } else {
  ///   // Show login screen
  /// }
  /// ```
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  /// Normalize token - remove whitespace, validate not empty
  /// 
  /// Logic:
  /// 1. null token → return null
  /// 2. Trim leading/trailing whitespace
  /// 3. Empty after trim → return null
  /// 4. Valid token → return trimmed
  /// 
  /// Purpose: Reject invalid tokens from API or localStorage
  String? _normalizeToken(String? token) {
    if (token == null) return null;
    final trimmed = token.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Normalize email - trim, lowercase, validate not empty
  /// 
  /// Logic:
  /// 1. null email → return null
  /// 2. Trim + lowercase
  /// 3. Empty after trim → return null
  /// 4. Valid email → return normalized
  /// 
  /// Purpose: Consistent email comparison (case-insensitive)
  String? _normalizeEmail(String? email) {
    if (email == null) return null;
    final normalized = email.trim().toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }

  /// Persist session data đến persistent storage
  /// 
  /// Strategy:
  /// 1. Access token → SharedPreferences (public, fast access)
  ///    - Keys: 'access_token' (preferred) & 'accessToken' (legacy compat)
  /// 2. Refresh token → SecureStorage (encrypted per-user)
  ///    - Key: 'refresh_token_{email}' (tied to email)
  /// 3. Last email → SharedPreferences (remember for login form)
  /// 4. User data → SharedPreferences JSON (cache user info)
  /// 
  /// Timing:
  /// - Called after login (setSession)
  /// - Called after profile update
  /// - Async save (unawaited) to prevent blocking
  /// 
  /// Dual keys:
  /// - New code uses snake_case (access_token)
  /// - Old code uses camelCase (accessToken) for backward compat
  Future<void> _persistSessionToLocal() async {
    final prefs = await SharedPreferences.getInstance();

    /// Save access token
    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('accessToken', _accessToken!);  /// Legacy compat
    } else {
      await prefs.remove('access_token');
      await prefs.remove('accessToken');
    }

    /// Save refresh token
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
      await prefs.setString('refreshToken', _refreshToken!);  /// Legacy compat
    } else {
      await prefs.remove('refresh_token');
      await prefs.remove('refreshToken');
    }

    /// Save last login email (for login form remember)
    if (_userEmail != null) {
      await prefs.setString('last_login_email', _userEmail!);
      /// Also save refresh token in SecureStorage (per-user, encrypted)
      if (_refreshToken != null) {
        await _secureStorage.write(
          key: 'refresh_token_${_userEmail!}',  /// Key tied to email
          value: _refreshToken!,
        );
      }
    } else {
      await prefs.remove('last_login_email');
    }

    /// Save user profile data as JSON
    if (_userData != null) {
      await prefs.setString('user_data_json', jsonEncode(_userData));
    } else {
      await prefs.remove('user_data_json');
    }
  }

  /// Xóa session data khỏi persistent storage
  /// 
  /// Timing:
  /// - Gọi khi logout() → clear all traces
  /// - Xóa tokens cả SharedPreferences và SecureStorage
  /// 
  /// Flow:
  /// 1. Get email trước khi clear (cần để delete SecureStorage key)
  /// 2. Xóa access token (both keys)
  /// 3. Xóa refresh token (both keys)
  /// 4. Xóa user data JSON
  /// 5. Xóa last login email
  /// 6. Xóa per-user refresh token từ SecureStorage
  Future<void> _clearSessionFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    /// Get email trước clear (cần để locate SecureStorage key)
    final email = _normalizeEmail(_userEmail ?? prefs.getString('last_login_email'));

    /// Remove all SharedPreferences keys
    await prefs.remove('access_token');
    await prefs.remove('accessToken');
    await prefs.remove('refresh_token');
    await prefs.remove('refreshToken');
    await prefs.remove('user_data_json');
    await prefs.remove('last_login_email');

    /// Remove per-user refresh token từ SecureStorage
    if (email != null) {
      await _secureStorage.delete(key: 'refresh_token_$email');
    }
  }

  /// Load session từ persistent storage khi app start
  /// 
  /// Quy trình (Session Hydration):
  /// 1. Query SharedPreferences:
  ///    - accessToken (check both snake_case & camelCase keys)
  ///    - refreshToken (check both keys)
  ///    - lastLoginEmail
  ///    - userDataJson (JSON string)
  /// 2. Parse user data JSON trở về Map
  /// 3. Normalize tokens & email
  /// 4. Update ApiClient với access token
  /// 5. Set _isSessionHydrated = true (even if data empty)
  /// 6. notifyListeners() để notify listeners
  /// 
  /// Error Handling:
  /// - Catch & log any exception
  /// - Still set isSessionHydrated = true (allow app to continue)
  /// - Fall back to empty session if error
  /// 
  /// Timing: Called in constructor
  Future<void> _loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      /// Load access token (check both key formats)
      _accessToken = _normalizeToken(
        prefs.getString('access_token') ?? prefs.getString('accessToken'),
      );
      /// Load refresh token (check both key formats)
      _refreshToken = _normalizeToken(
        prefs.getString('refresh_token') ?? prefs.getString('refreshToken'),
      );
      /// Load last login email
      _userEmail = _normalizeEmail(prefs.getString('last_login_email'));

      /// Load user data JSON
      final rawUser = prefs.getString('user_data_json');
      if (rawUser != null && rawUser.isNotEmpty) {
        final parsed = jsonDecode(rawUser);
        if (parsed is Map<String, dynamic>) {
          _userData = parsed;
        }
      }

      /// Extract email từ user data (fallback)
      _userEmail = _userEmail ?? _normalizeEmail(_userData?['email']?.toString());
      /// Update API client với loaded token
      _apiClient.updateToken(_accessToken);
    } catch (e) {
      /// Log error nhưng không crash
      debugPrint('Error loading local session: $e');
    } finally {
      /// Always mark hydrated (even if error)
      _isSessionHydrated = true;
      /// Notify listeners để rebuild UI (show login or home screen)
      notifyListeners();
    }
  }

  /// Set session sau khi login thành công
  /// 
  /// Tham số:
  /// - accessToken: JWT token từ backend login response
  /// - refreshToken: Refresh token để renew access token sau khi expire
  /// - email: User email (from login)
  /// - userData: Optional user profile data (from login response)
  /// 
  /// Quy trình:
  /// 1. Normalize tokens & email
  /// 2. Use userData email nếu available (fallback to parameter)
  /// 3. Update ApiClient với accessToken
  /// 4. Persist tớ SharedPreferences & SecureStorage
  /// 5. notifyListeners() để notify listeners (rebuild UI)
  /// 
  /// Usage:
  /// ```dart
  /// authProvider.setSession(
  ///   accessToken: response.accessToken,
  ///   refreshToken: response.refreshToken,
  ///   email: 'user@example.com',
  ///   userData: response.user
  /// );
  /// ```
  void setSession({
    required String accessToken,
    required String refreshToken,
    required String email,
    Map<String, dynamic>? userData,
  }) {
    _accessToken = _normalizeToken(accessToken);
    _refreshToken = _normalizeToken(refreshToken);
    _userData = userData ?? _userData;  /// Keep existing if not provided
    _userEmail = _normalizeEmail(_userData?['email']?.toString()) ?? _normalizeEmail(email);

    _apiClient.updateToken(_accessToken);
    unawaited(_persistSessionToLocal());
    notifyListeners();
  }

  /// Update user privacy setting (searchable/public profile)
  /// 
  /// Tham số:
  /// - isSearchable: true = public profile (others can find), false = private
  /// 
  /// API Call: PUT /api/users/me/privacy {isSearchable: bool}
  /// 
  /// Quy trình:
  /// 1. Call API update privacy
  /// 2. If success (200):
  ///    - Update local _userData['is_searchable']
  ///    - Persist to local storage
  ///    - notifyListeners()
  /// 3. If error: Log & silently fail (non-critical)
  /// 
  /// Error Handling: Graceful (log only, no exception thrown)
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

  /// Update FCM token (device token cho push notifications)
  /// 
  /// Tham số:
  /// - fcmToken: Device token từ Firebase Cloud Messaging
  /// 
  /// API Call: PUT /api/users/me/fcm-token {fcmToken: string}
  /// 
  /// Purpose:
  /// - Backend lưu device token
  /// - Backend dùng token để gửi push notifications
  /// - Cần update khi token thay đổi
  /// 
  /// Error Handling: Graceful (log only)
  /// 
  /// Timing:
  /// - Gọi sau khi login thành công
  /// - Gọi khi FCM token refreshed (định kỳ yearly)
  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _apiClient.put('/api/users/me/fcm-token', {'fcmToken': fcmToken});
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Fetch latest user profile data từ backend
  /// 
  /// API Call: GET /api/users/me
  /// 
  /// Purpose:
  /// - Refresh user info sau khi login hoặc periodic updates
  /// - Update avatar, name, settings, etc.
  /// - Ensure data consistent với server
  /// 
  /// Quy trình:
  /// 1. Call GET /api/users/me
  /// 2. Parse response.user object
  /// 3. Update _userData
  /// 4. Extract email từ user data
  /// 5. Persist to local storage
  /// 6. notifyListeners() để rebuild UI
  /// 
  /// Error Handling: Graceful (log only)
  /// 
  /// Typical Usage:
  /// ```dart
  /// // After login
  /// await authProvider.fetchProfile();
  /// // Now authProvider.userData has fresh data
  /// ```
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

  /// Logout - clear all auth data
  /// 
  /// Quy trình:
  /// 1. Clear all memory state:
  ///    - _accessToken = null
  ///    - _refreshToken = null
  ///    - _userEmail = null
  ///    - _userData = null
  /// 2. Update ApiClient token = null (no more auto auth header)
  /// 3. Clear persistent storage (SharedPreferences & SecureStorage)
  /// 4. notifyListeners() để notify listeners
  /// 
  /// Timing:
  /// - User bấm logout
  /// - Token expired & no refresh available
  /// - App lifecycle (optional, on destroy)
  /// 
  /// Side Effects:
  /// - All API calls after this sẽ fail (no token)
  /// - UI should navigate to login screen
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
