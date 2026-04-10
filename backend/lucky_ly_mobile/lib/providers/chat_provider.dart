import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/services/api_client.dart';
import '../core/services/socket_service.dart';
import './auth_provider.dart';

/// ChatProvider - State management cho chat/room/message trong ứng dụng
/// 
/// Chức năng chính:
/// - Load danh sách phòng chat từ backend
/// - Load messages theo từng room
/// - Tạo room chat mới hoặc lấy room đã tồn tại
/// - Lắng nghe socket events để cập nhật realtime message
/// - Đánh dấu tin nhắn đã đọc và cập nhật unread count
/// 
/// Dependencies:
/// - AuthProvider: Cung cấp auth state và apiClient
/// - SocketService: Nhận/gửi realtime events
/// 
/// Lưu trữ nội bộ:
/// - _rooms: Danh sách phòng chat của user hiện tại
/// - _messages: Map roomId -> danh sách message của room đó
/// - _isLoading: Cờ loading khi fetch dữ liệu từ server
class ChatProvider extends ChangeNotifier {
  /// Auth provider để lấy token, userData và apiClient
  final AuthProvider authProvider;

  /// Socket service để nhận realtime message/read event
  final SocketService socketService;

  /// Danh sách phòng chat đã tải từ backend
  List<dynamic> _rooms = [];

  /// Cache message theo từng roomId để tránh fetch lại nhiều lần
  /// 
  /// Key: roomId
  /// Value: List message của room đó
  Map<String, List<dynamic>> _messages = {}; // roomId -> messages

  /// Cờ loading cho UI khi đang fetch rooms/messages
  bool _isLoading = false;

  /// Constructor của ChatProvider
  /// 
  /// Khi khởi tạo sẽ tự động đăng ký socket listeners để nhận realtime updates
  ChatProvider(this.authProvider, this.socketService) {
    _initSocketListeners();
  }

  /// Public getters để UI đọc state
  List<dynamic> get rooms => _rooms;
  bool get isLoading => _isLoading;

  /// Shortcut lấy ApiClient từ AuthProvider
  ApiClient get _api => authProvider.apiClient;

  /// Đăng ký các socket listeners cho chat realtime
  /// 
  /// Hiện tại lắng nghe:
  /// - new_message: Khi có tin nhắn mới
  /// - messages_read: Khi tin nhắn được đánh dấu đã đọc
  /// 
  /// Luồng xử lý message mới:
  /// 1. Xác định roomId của message
  /// 2. Nếu room đang có trong cache messages thì insert message mới vào đầu list
  /// 3. Cập nhật preview của room trong danh sách rooms
  /// 4. Tăng unread_count nếu message không phải của user hiện tại
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
      // Có thể dùng để cập nhật UI read receipt nếu cần thêm sau này
    });
  }

  /// Lấy danh sách room chat của user hiện tại từ backend
  /// 
  /// API: GET /api/chat/rooms
  /// 
  /// Quy trình:
  /// 1. Bật loading state
  /// 2. Gọi API lấy rooms
  /// 3. Parse JSON response vào _rooms
  /// 4. Tắt loading state và notify listeners
  /// 
  /// Error handling:
  /// - Nếu request thất bại chỉ log lỗi, không throw
  /// - UI vẫn được cập nhật loading=false ở finally
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

  /// Trả về danh sách message đã cache của một room
  /// 
  /// Nếu room chưa có cache thì trả về list rỗng
  List<dynamic> getMessages(String roomId) => _messages[roomId] ?? [];

  /// Lấy danh sách messages của một room từ backend
  /// 
  /// API: GET /api/chat/rooms/{roomId}/messages
  /// 
  /// Quy trình:
  /// 1. Gọi API theo roomId
  /// 2. Nếu thành công, lưu messages vào _messages[roomId]
  /// 3. notifyListeners() để UI render lại
  /// 
  /// Ghi chú:
  /// - Messages được cache theo room để tránh fetch lại liên tục
  /// - UI có thể gọi getMessages(roomId) để đọc cache này
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

  /// Lấy room chat hiện có hoặc tạo room mới với user khác
  /// 
  /// API: POST /api/chat/rooms
  /// Body: {'otherUserId': otherUserId}
  /// 
  /// Returns:
  /// - room_id nếu tạo/lấy room thành công
  /// - null nếu thất bại
  /// 
  /// Thường dùng khi user bấm vào profile của người khác để bắt đầu chat
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

  /// Đánh dấu toàn bộ messages trong room là đã đọc
  /// 
  /// Quy trình:
  /// 1. Gửi signal qua socketService.markRead(roomId)
  /// 2. Tìm room trong _rooms
  /// 3. Set unread_count = 0
  /// 4. notifyListeners() để UI cập nhật badge
  /// 
  /// Lưu ý:
  /// - Phần realtime read receipt có thể được backend broadcast thêm qua socket
  /// - Hàm này chủ yếu cập nhật local UI ngay lập tức
  void markAsRead(String roomId) {
    socketService.markRead(roomId);
    final roomIndex = _rooms.indexWhere((r) => r['room_id'] == roomId);
    if (roomIndex != -1) {
      _rooms[roomIndex]['unread_count'] = 0;
      notifyListeners();
    }
  }
}
