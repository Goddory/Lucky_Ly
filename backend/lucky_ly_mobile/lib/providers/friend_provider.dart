import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/services/api_client.dart';
import './auth_provider.dart';

class FriendProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  
  List<dynamic> _friends = [];
  List<dynamic> _sentRequests = [];
  List<dynamic> _receivedRequests = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  FriendProvider(this.authProvider);

  List<dynamic> get friends => _friends;
  List<dynamic> get sentRequests => _sentRequests;
  List<dynamic> get receivedRequests => _receivedRequests;
  List<dynamic> get searchResults => _searchResults;
  bool get isLoading => _isLoading;

  ApiClient get _api => authProvider.apiClient;

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

  Future<void> fetchSentRequests() async {
    try {
      final res = await _api.get('/api/friends/requests/sent');
      if (res.statusCode == 200) _sentRequests = jsonDecode(res.body);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching sent requests: $e');
    }
  }

  Future<void> fetchReceivedRequests() async {
    try {
      final res = await _api.get('/api/friends/requests/received');
      if (res.statusCode == 200) _receivedRequests = jsonDecode(res.body);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching received requests: $e');
    }
  }

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

  Future<bool> sendRequest(int friendId) async {
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

  Future<bool> acceptRequest(int requestId) async {
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

  Future<bool> declineRequest(int requestId) async {
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

  Future<bool> unfriend(int friendId) async {
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
