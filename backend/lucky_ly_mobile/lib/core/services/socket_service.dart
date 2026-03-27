import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import './api_client.dart';

class SocketService extends ChangeNotifier {
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    final baseUrl = ApiClient.getBaseUrl();
    
    _socket = io.io(baseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('🔌 Socket connected');
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('🔌 Socket disconnected');
      notifyListeners();
    });

    _socket!.onConnectError((err) => debugPrint('🔌 Socket Connect Error: $err'));
    _socket!.onError((err) => debugPrint('🔌 Socket Error: $err'));
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
    notifyListeners();
  }

  // Join/Leave Rooms
  void joinRoom(String roomId) {
    _socket?.emit('join_room', roomId);
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave_room', roomId);
  }

  // Messaging
  void sendMessage(Map<String, dynamic> data, Function(dynamic) callback) {
    _socket?.emitWithAck('send_message', data, ack: callback);
  }

  void markRead(String roomId) {
    _socket?.emit('mark_read', roomId);
  }

  void sendTyping(String roomId) {
    _socket?.emit('typing', {'roomId': roomId});
  }

  void stopTyping(String roomId) {
    _socket?.emit('stop_typing', {'roomId': roomId});
  }

  // Listeners
  void onMessage(Function(dynamic) handler) {
    _socket?.on('new_message', handler);
  }

  void offMessage() {
    _socket?.off('new_message');
  }

  void onNotification(Function(dynamic) handler) {
    _socket?.on('notification', handler);
  }

  void offNotification() {
    _socket?.off('notification');
  }

  void onTyping(Function(dynamic) handler) {
    _socket?.on('user_typing', handler);
  }

  void onStopTyping(Function(dynamic) handler) {
    _socket?.on('user_stop_typing', handler);
  }

  void onRead(Function(dynamic) handler) {
    _socket?.on('messages_read', handler);
  }
}
