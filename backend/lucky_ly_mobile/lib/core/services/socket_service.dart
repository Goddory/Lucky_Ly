import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import './api_client.dart';

/// SocketService - Real-time WebSocket communication service
/// 
/// Mục đích chính:
/// - Kết nối WebSocket tới backend cho real-time features
/// - Quản lý real-time messaging, notifications, typing indicators
/// - Join/leave rooms để chat trong groups
/// - Emit events và listen cho changes
/// 
/// Extends ChangeNotifier để:
/// - Thông báo UI khi connection status thay đổi
/// - Integration với Flutter State Management
/// - Rebuild UI khi socket connect/disconnect
/// 
/// Features:
/// 1. Connection Management - Connect/disconnect với token auth
/// 2. Room Management - Join/leave chat rooms
/// 3. Real-time Messaging - Send/receive messages instantly
/// 4. Typing Indicators - Show khi user đang gõ
/// 5. Read Receipts - Mark messages as read
/// 6. Notifications - Receive real-time notifications
/// 7. Event Listeners - Listen/unlisten socket events
/// 
/// Transport: WebSocket only (không dùng polling cho performance)
/// Auth: Token-based (Bearer token từ login)
class SocketService extends ChangeNotifier {
  /// Socket.IO client instance - kết nối tới backend WebSocket server
  /// 
  /// Lifecycle:
  /// - null: Chưa khởi tạo
  /// - Initialized: Sau khi gọi connect() và socket.connect()
  /// - Connected: Khi backend accept connection
  /// - null: Sau khi disconnect()
  io.Socket? _socket;
  
  /// Connection status flag - dùng để Track liệu socket hiện đang connected hay không
  /// 
  /// Thay đổi:
  /// - true: Khi socket.onConnect event fire
  /// - false: Khi socket.onDisconnect event fire hoặc disconnect() gọi
  /// 
  /// Getter: isConnected - public access để check connection status
  bool _isConnected = false;

  /// Public getter để check nếu socket connection active
  /// 
  /// Usage:
  /// ```dart
  /// if (socketService.isConnected) {
  ///   socketService.sendMessage(...);
  /// } else {
  ///   showSnackBar('Not connected to server');
  /// }
  /// ```
  bool get isConnected => _isConnected;

  /// Khởi tạo WebSocket connection tới backend
  /// 
  /// Tham số:
  /// - token (String): JWT authentication token (lấy từ login)
  /// 
  /// Quy trình:
  /// 1. Kiểm tra nếu socket đã connected → skip
  /// 2. Lấy API base URL (desktop/web/mobile)
  /// 3. Tạo Socket.IO client với các options:
  ///    - Transport: WebSocket only (không polling)
  ///    - Auth: {'token': token} gửi kèm connection
  ///    - DisableAutoConnect: True → connect() gọi manually
  /// 4. Xử lý connection events:
  ///    - onConnect: _isConnected = true, notify listeners
  ///    - onDisconnect: _isConnected = false, notify listeners
  ///    - onConnectError: Log error
  ///    - onError: Log general errors
  /// 5. Gọi socket.connect() để initiate handshake
  /// 
  /// Auth Flow:
  /// - Client gửi token via auth payload
  /// - Backend validate token
  /// - Nếu valid → connection accept, client receives connected event
  /// - Nếu invalid → connection fail, client receives error event
  /// 
  /// Best Practice: Gọi disconnect() trước khi connect() lại (tránh duplicate connections)
  void connect(String token) {
    /// Early exit: Nếu socket đã connected, skip
    if (_socket != null && _socket!.connected) return;

    final baseUrl = ApiClient.getBaseUrl();
    
    /// Tạo Socket.IO client với cấu hình
    _socket = io.io(baseUrl, io.OptionBuilder()
      .setTransports(['websocket'])  /// WebSocket only transport
      .setAuth({'token': token})      /// Auth payload
      .disableAutoConnect()           /// Manual connect()
      .build());

    /// Explicit connect - trigger handshake
    _socket!.connect();

    /// Handle connection success
    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('🔌 Socket connected');
      /// notifyListeners() → rebuild UI di AppModel atau Provider listener
      notifyListeners();
    });

    /// Handle disconnection
    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('🔌 Socket disconnected');
      notifyListeners();
    });

    /// Handle connection errors (auth failed, timeout, etc.)
    _socket!.onConnectError((err) => debugPrint('🔌 Socket Connect Error: $err'));
    
    /// Handle general socket errors
    _socket!.onError((err) => debugPrint('🔌 Socket Error: $err'));
  }

  /// Putus kết nối WebSocket
  /// 
  /// Quy trình:
  /// 1. Gọi socket?.disconnect() → đóng connection gracefully
  /// 2. Set _socket = null → giải phóng reference
  /// 3. Set _isConnected = false
  /// 4. notifyListeners() → update UI
  /// 
  /// Best Practice: Gọi disconnect() trước khi:
  /// - Logout (cleanup resources)
  /// - Đổi tài khoản
  /// - App lifecycle (onPause, onDetach)
  /// - Rời khỏi chat screen
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  // ========== Room Management ==========

  /// Join socket room để receive room-specific events
  /// 
  /// Tham số:
  /// - roomId (String): ID của room/group/conversation (ví dụ: groupChat_123)
  /// 
  /// Mục đích:
  /// - Backend sẽ route messages chỉ tới users trong room này
  /// - User phải join room trước khi nhận messages từ room
  /// - Thường gọi khi mở chat screen hoặc join group
  /// 
  /// Behind scenes:
  /// - Emit 'join_room' event tới backend
  /// - Backend thêm user vào room
  /// - Backend broadcast 'user_joined' event tới room members
  /// 
  /// Typical Flow:
  /// ```dart
  /// socketService.joinRoom('chat_room_456');
  /// socketService.onMessage((data) {
  ///   // Nhận messages từ room_456
  /// });
  /// ```
  void joinRoom(String roomId) {
    _socket?.emit('join_room', roomId);
  }

  /// Leave socket room - stop receiving room events
  /// 
  /// Tham số:
  /// - roomId (String): ID của room cần leave
  /// 
  /// Mục đích:
  /// - Dừng nhận messages từ room này
  /// - Thường gọi khi đóng/minimize chat, hoặc rời khỏi group
  /// - Tiết kiệm bandwidth/CPU
  /// 
  /// Behind scenes:
  /// - Emit 'leave_room' event tới backend
  /// - Backend xóa user khỏi room
  /// - Backend broadcast 'user_left' event tới room members
  void leaveRoom(String roomId) {
    _socket?.emit('leave_room', roomId);
  }

  // ========== Messaging Operations ==========

  /// Gửi message tới room (guaranteed delivery với ACK)
  /// 
  /// Tham số:
  /// - data (Map): Message payload chứa:
  ///   - roomId: Room nhận message
  ///   - content: Nội dung message
  ///   - type: Loại message (text, image, file, etc.)
  ///   - attachments: Tệp/media kèm theo (optional)
  /// - callback (Function): Gọi khi backend acknowledge (message saved)
  /// 
  /// Mục đích:
  /// - Emit 'send_message' event với ACK
  /// - Backend lưu message
  /// - Backend broadcast tới room members
  /// - Callback xác nhận delivery
  /// 
  /// Example:
  /// ```dart
  /// socketService.sendMessage(
  ///   {
  ///     'roomId': '123',
  ///     'content': 'Hello',
  ///     'type': 'text'
  ///   },
  ///   (ack) {
  ///     print('Message sent: $ack');
  ///   }
  /// );
  /// ```
  void sendMessage(Map<String, dynamic> data, Function(dynamic) callback) {
    _socket?.emitWithAck('send_message', data, ack: callback);
  }

  /// Đánh dấu tất cả messages trong room là đã đọc (read receipts)
  /// 
  /// Tham số:
  /// - roomId (String): Room ID
  /// 
  /// Mục đích:
  /// - Thông báo backend: "Tôi đã đọc messages"
  /// - Backend cập nhật message.readBy array
  /// - Backend emit 'messages_read' event tới room → others thấy "đã đọc" status
  /// 
  /// Timing: Thường gọi khi:
  /// - Mở chat room
  /// - Scroll tới cuối conversation
  /// - Định kỳ khi focus vào screen chat
  void markRead(String roomId) {
    _socket?.emit('mark_read', roomId);
  }

  /// Gửi signal "user đang gõ" (typing indicator)
  /// 
  /// Tham số:
  /// - roomId (String): Room ID
  /// 
  /// Mục đích:
  /// - Show others: "Tên User đang gõ..."
  /// - Backend emit 'user_typing' event tới room members
  /// 
  /// Best Practice: Gọi khi:
  /// - TextField.onChanged → mỗi keystroke
  /// - Throttle/debounce: Gọi tối đa 1 lần/giây để tránh spam
  /// 
  /// Ví dụ:
  /// ```dart
  /// _textController.addListener(() {
  ///   if (_textController.text.isNotEmpty) {
  ///     _typingTimer?.cancel();
  ///     socketService.sendTyping(roomId);
  ///     _typingTimer = Timer(Duration(milliseconds: 500), () {
  ///       socketService.stopTyping(roomId);
  ///     });
  ///   }
  /// });
  /// ```
  void sendTyping(String roomId) {
    _socket?.emit('typing', {'roomId': roomId});
  }

  /// Gửi signal "user ngừng gõ" - xóa typing indicator
  /// 
  /// Tham số:
  /// - roomId (String): Room ID
  /// 
  /// Mục đích:
  /// - Gửi signal user ngừng gõ
  /// - Backend emit 'user_stop_typing' event
  /// - Others ẩn "user đang gõ" label
  /// 
  /// Timing: Gọi khi:
  /// - User mất focus khỏi TextField
  /// - User kết thúc typing session (delay ~500ms sau keystroke cuối cùng)
  /// - User cancel message composition
  void stopTyping(String roomId) {
    _socket?.emit('stop_typing', {'roomId': roomId});
  }

  // ========== Event Listeners ==========

  /// Listen cho incoming real-time messages từ room
  /// 
  /// Tham số:
  /// - handler: Function(data) callback cho mỗi message mới
  /// 
  /// Format dữ liệu dự kiến:
  /// ```dart
  /// {
  ///   '_id': 'msgId123',
  ///   'roomId': 'room456',
  ///   'sender': {...thông tin user...},
  ///   'content': 'Nội dung message',
  ///   'type': 'text',
  ///   'createdAt': '2024-04-08T10:30:00Z',
  ///   'readBy': ['userId1', 'userId2']
  /// }
  /// ```
  /// 
  /// Mục đích:
  /// - Subscribe cho instant message updates
  /// - Update UI với messages mới
  /// - Trigger notifications
  /// 
  /// Ví dụ:
  /// ```dart
  /// socketService.onMessage((data) {
  ///   setState(() {
  ///     messages.add(Message.fromJson(data));
  ///   });
  /// });
  /// ```
  /// 
  /// Cleanup: Gọi offMessage() trước khi dispose/rời screen
  void onMessage(Function(dynamic) handler) {
    _socket?.on('new_message', handler);
  }

  /// Dừng listen message events
  /// 
  /// Mục đích:
  /// - Cleanup listeners trước khi dispose
  /// - Tránh memory leaks
  /// - Tránh double-listening
  /// 
  /// Best Practice: Gọi trong dispose() hoặc trước khi rời screen:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   socketService.offMessage();
  ///   socketService.leaveRoom(roomId);
  ///   super.dispose();
  /// }
  /// ```
  void offMessage() {
    _socket?.off('new_message');
  }

  /// Listen cho push notifications real-time
  /// 
  /// Tham số:
  /// - handler: Function(data) callback cho mỗi notification
  /// 
  /// Dữ liệu dự kiến:
  /// ```dart
  /// {
  ///   'type': 'new_message' | 'friend_request' | 'group_invite' | etc,
  ///   'title': 'Tiêu đề notification',
  ///   'body': 'Nội dung notification',
  ///   'data': {...dữ liệu thêm...}
  /// }
  /// ```
  /// 
  /// Mục đích:
  /// - Nhận real-time notifications
  /// - Show toast, badge, sound alert
  /// - Navigate tới screen liên quan
  /// 
  /// Lưu ý: Notifications vẫn được nhận via FCM khi app offline
  void onNotification(Function(dynamic) handler) {
    _socket?.on('notification', handler);
  }

  /// Stop listening notifications
  void offNotification() {
    _socket?.off('notification');
  }

  /// Listen cho "user đang gõ" events
  /// 
  /// Tham số:
  /// - handler: Function(data) callback
  /// 
  /// Dữ liệu dự kiến:
  /// ```dart
  /// {
  ///   'userId': 'user123',
  ///   'userName': 'John',
  ///   'roomId': 'room456'
  /// }
  /// ```
  /// 
  /// Mục đích:
  /// - Show "John đang gõ..." ở message input area
  /// - Update typing indicator UI
  void onTyping(Function(dynamic) handler) {
    _socket?.on('user_typing', handler);
  }

  /// Listen cho "user ngừng gõ" events
  /// 
  /// Mục đích:
  /// - Ẩn typing indicator khi user ngừng gõ
  void onStopTyping(Function(dynamic) handler) {
    _socket?.on('user_stop_typing', handler);
  }

  /// Listen cho read receipt events (khi others đọc messages)
  /// 
  /// Tham số:
  /// - handler: Function(data) callback
  /// 
  /// Dữ liệu dự kiến:
  /// ```dart
  /// {
  ///   'roomId': 'room123',
  ///   'userId': 'user456',
  ///   'readAt': '2024-04-08T10:35:00Z'
  /// }
  /// ```
  /// 
  /// Mục đích:
  /// - Update message UI: show "đã đọc" checkmark
  /// - Show "user has seen" timestamp
  void onRead(Function(dynamic) handler) {
    _socket?.on('messages_read', handler);
  }
}
