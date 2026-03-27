import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/services/api_client.dart';
import '../core/services/socket_service.dart';
import './auth_provider.dart';

class ChatProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final SocketService socketService;

  List<dynamic> _rooms = [];
  Map<String, List<dynamic>> _messages = {}; // roomId -> messages
  bool _isLoading = false;

  ChatProvider(this.authProvider, this.socketService) {
    _initSocketListeners();
  }

  List<dynamic> get rooms => _rooms;
  bool get isLoading => _isLoading;
  ApiClient get _api => authProvider.apiClient;

  void _initSocketListeners() {
    socketService.onMessage((data) {
      final String messageRoomId = data['room_id'];
      if (_messages.containsKey(messageRoomId)) {
        _messages[messageRoomId]!.insert(0, data);
        notifyListeners();
      }
      // Update room preview if in room list
      final roomIndex = _rooms.indexWhere((r) => r['room_id'] == messageRoomId);
      if (roomIndex != -1) {
        _rooms[roomIndex]['last_message'] = data['content'];
        _rooms[roomIndex]['last_message_at'] = data['created_at'];
        if (data['sender_id'] != authProvider.userData?['user_id']) {
          final currentCount = int.tryParse(_rooms[roomIndex]['unread_count']?.toString() ?? '0') ?? 0;
          _rooms[roomIndex]['unread_count'] = currentCount + 1;
        }
        notifyListeners();
      }
    });

    socketService.onRead((data) {
      // Handle read receipt UI update if needed
    });
  }

  Future<void> fetchRooms() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.get('/api/chat/rooms');
      if (res.statusCode == 200) _rooms = jsonDecode(res.body);
    } catch (e) {
      debugPrint('Error fetching chat rooms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<dynamic> getMessages(String roomId) => _messages[roomId] ?? [];

  Future<void> fetchMessages(String roomId) async {
    try {
      final res = await _api.get('/api/chat/rooms/$roomId/messages');
      if (res.statusCode == 200) {
        _messages[roomId] = jsonDecode(res.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  Future<String?> getOrCreateRoom(String otherUserId) async {
    try {
      final res = await _api.post('/api/chat/rooms', {'otherUserId': otherUserId});
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return data['room_id'];
      }
    } catch (e) {
      debugPrint('Error getting room: $e');
    }
    return null;
  }

  void markAsRead(String roomId) {
    socketService.markRead(roomId);
    final roomIndex = _rooms.indexWhere((r) => r['room_id'] == roomId);
    if (roomIndex != -1) {
      _rooms[roomIndex]['unread_count'] = 0;
      notifyListeners();
    }
  }
}
