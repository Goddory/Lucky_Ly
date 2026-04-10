import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/services/api_client.dart';
import './auth_provider.dart';

/// FriendProvider - State management cho friends, friend requests và user search
/// 
/// Chức năng chính:
/// - Lấy danh sách bạn bè
/// - Lấy danh sách lời mời đã gửi và đã nhận
/// - Tìm kiếm người dùng
/// - Gửi / chấp nhận / từ chối / hủy kết bạn
/// 
/// Dependencies:
/// - AuthProvider: Cung cấp apiClient đã gắn token
/// 
/// State nội bộ:
/// - _friends: Danh sách bạn bè hiện tại
/// - _sentRequests: Danh sách lời mời kết bạn đã gửi
/// - _receivedRequests: Danh sách lời mời kết bạn đã nhận
/// - _searchResults: Kết quả tìm kiếm user
/// - _isLoading: Cờ loading cho UI
class FriendProvider extends ChangeNotifier {
  /// Auth provider để lấy token và ApiClient
  final AuthProvider authProvider;
  
  /// Danh sách bạn bè của user hiện tại
  List<dynamic> _friends = [];

  /// Danh sách lời mời kết bạn đã gửi
  List<dynamic> _sentRequests = [];

  /// Danh sách lời mời kết bạn đã nhận
  List<dynamic> _receivedRequests = [];

  /// Kết quả tìm kiếm user
  List<dynamic> _searchResults = [];

  /// Cờ loading dùng cho UI
  bool _isLoading = false;

  /// Constructor của FriendProvider
  FriendProvider(this.authProvider);

  /// Public getters để UI đọc state
  List<dynamic> get friends => _friends;
  List<dynamic> get sentRequests => _sentRequests;
  List<dynamic> get receivedRequests => _receivedRequests;
  List<dynamic> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  /// Shortcut lấy ApiClient từ AuthProvider
  ApiClient get _api => authProvider.apiClient;

  /// Lấy danh sách bạn bè từ backend
  /// 
  /// API: GET /api/friends/list
  /// 
  /// Quy trình:
  /// 1. Bật loading
  /// 2. Gọi API
  /// 3. Parse JSON response vào _friends
  /// 4. Tắt loading và notify listeners
  /// 
  /// Error handling: Chỉ log lỗi, không throw
  Future<void> fetchFriends() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/friends/list');
      if (res.statusCode == 200) _friends = jsonDecode(res.body);
    } catch (e) {
      debugPrint('Error fetching friends: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lấy danh sách lời mời kết bạn đã gửi
  /// 
  /// API: GET /api/friends/requests/sent
  /// 
  /// Dùng để hiển thị các request đang chờ người kia phản hồi
  Future<void> fetchSentRequests() async {
    try {
      final res = await _api.get('/api/friends/requests/sent');
      if (res.statusCode == 200) _sentRequests = jsonDecode(res.body);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching sent requests: $e');
    }
  }

  /// Lấy danh sách lời mời kết bạn đã nhận
  /// 
  /// API: GET /api/friends/requests/received
  /// 
  /// Dùng để hiển thị lời mời chờ user chấp nhận/từ chối
  Future<void> fetchReceivedRequests() async {
    try {
      final res = await _api.get('/api/friends/requests/received');
      if (res.statusCode == 200) _receivedRequests = jsonDecode(res.body);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching received requests: $e');
    }
  }

  /// Tìm kiếm người dùng theo từ khóa
  /// 
  /// Quy tắc:
  /// - Nếu query < 2 ký tự → clear kết quả để tránh spam API
  /// - Nếu đủ dài → gọi backend search
  /// 
  /// API: GET /api/friends/search?q={query}
  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    try {
      final res = await _api.get('/api/friends/search?q=$query');
      if (res.statusCode == 200) _searchResults = jsonDecode(res.body);
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
  }

  /// Gửi lời mời kết bạn tới một user
  /// 
  /// API: POST /api/friends/request
  /// Body: {'friendId': friendId}
  /// 
  /// Quy trình:
  /// 1. Ghi log debug để theo dõi request/response
  /// 2. Gửi request lên backend
  /// 3. Nếu thành công (201) → refresh sent requests
  /// 4. Trả về true/false cho UI xử lý
  Future<bool> sendRequest(String friendId) async {
    try {
      debugPrint('=== SENDING FRIEND REQUEST ===');
      debugPrint('Friend ID: $friendId');
      
      final requestBody = {'friendId': friendId};
      debugPrint('Request body: $requestBody');
      
      final res = await _api.post('/api/friends/request', requestBody);
      
      debugPrint('Status Code: ${res.statusCode}');
      debugPrint('Response: ${res.body}');
      
      if (res.statusCode == 201) {
        final responseData = jsonDecode(res.body);
        debugPrint('Success: ${responseData['message']}');
        debugPrint('Request data: ${responseData['request']}');
        
        await fetchSentRequests();
        return true;
      } else {
        debugPrint('Error: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error sending friend request: $e');
    }
    return false;
  }

  /// Chấp nhận lời mời kết bạn
  /// 
  /// API: PATCH /api/friends/request/{requestId}/accept
  /// 
  /// Quy trình:
  /// 1. Gửi request accept
  /// 2. Nếu thành công → refresh received requests và friends list
  /// 3. Trả về true nếu accept thành công
  Future<bool> acceptRequest(String requestId) async {
    try {
      debugPrint('=== ACCEPTING FRIEND REQUEST ===');
      debugPrint('Request ID: $requestId');
      
      final res = await _api.patch('/api/friends/request/$requestId/accept', {});
      
      debugPrint('Status Code: ${res.statusCode}');
      debugPrint('Response: ${res.body}');
      
      if (res.statusCode == 200) {
        final responseData = jsonDecode(res.body);
        debugPrint('Success: ${responseData['message']}');
        
        await fetchReceivedRequests();
        await fetchFriends();
        return true;
      } else {
        debugPrint('Error: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error accepting request: $e');
    }
    return false;
  }

  /// Từ chối lời mời kết bạn
  /// 
  /// API: PATCH /api/friends/request/{requestId}/decline
  /// 
  /// Quy trình:
  /// 1. Gửi request decline
  /// 2. Nếu thành công → refresh received requests
  /// 3. Trả về true nếu từ chối thành công
  Future<bool> declineRequest(String requestId) async {
    try {
      debugPrint('=== DECLINING FRIEND REQUEST ===');
      debugPrint('Request ID: $requestId');
      
      final res = await _api.patch('/api/friends/request/$requestId/decline', {});
      
      debugPrint('Status Code: ${res.statusCode}');
      debugPrint('Response: ${res.body}');
      
      if (res.statusCode == 200) {
        final responseData = jsonDecode(res.body);
        debugPrint('Success: ${responseData['message']}');
        
        await fetchReceivedRequests();
        return true;
      } else {
        debugPrint('Error: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error declining request: $e');
    }
    return false;
  }

  /// Hủy kết bạn với một user
  /// 
  /// API: DELETE /api/friends/{friendId}
  /// 
  /// Quy trình:
  /// 1. Gửi request delete friendship
  /// 2. Nếu thành công → refresh friends list
  /// 3. Trả về true nếu unfriend thành công
  Future<bool> unfriend(String friendId) async {
    try {
      final res = await _api.delete('/api/friends/$friendId');
      if (res.statusCode == 200) {
        await fetchFriends();
        return true;
      }
    } catch (e) {
      debugPrint('Error unfriending: $e');
    }
    return false;
  }
}
