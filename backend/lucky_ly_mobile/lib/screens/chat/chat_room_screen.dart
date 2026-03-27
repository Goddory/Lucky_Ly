import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/services/socket_service.dart';
import '../../app_theme.dart';
import 'package:intl/intl.dart';
import '../gifts/themed_gift_builder_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomId;
  final dynamic otherUser;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    required this.otherUser,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _otherIsTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.fetchMessages(widget.roomId);
      chatProvider.markAsRead(widget.roomId);
      
      final socket = context.read<SocketService>();
      socket.joinRoom(widget.roomId);
      
      socket.onTyping((data) {
        if (data['roomId'] == widget.roomId && mounted) {
          setState(() => _otherIsTyping = true);
        }
      });
      
      socket.onStopTyping((data) {
        if (data['roomId'] == widget.roomId && mounted) {
          setState(() => _otherIsTyping = false);
        }
      });
    });
  }

  @override
  void dispose() {
    context.read<SocketService>().leaveRoom(widget.roomId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final socket = context.read<SocketService>();
    socket.sendMessage({
      'roomId': widget.roomId,
      'receiverId': widget.otherUser['user_id'],
      'content': text,
      'messageType': 'text',
    }, (ack) {
      if (ack != null && ack['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ack['error'])));
      }
    });

    _messageController.clear();
    socket.stopTyping(widget.roomId);
  }

  void _onTypingChanged(String val) {
    final socket = context.read<SocketService>();
    if (val.isNotEmpty && !_isTyping) {
      _isTyping = true;
      socket.sendTyping(widget.roomId);
    } else if (val.isEmpty && _isTyping) {
      _isTyping = false;
      socket.stopTyping(widget.roomId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userData?['user_id'];
    
    return Scaffold(
      backgroundColor: AppTheme.of(context).bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUser['full_name'] ?? widget.otherUser['username'], 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_otherIsTyping)
              const Text('đang nhập...', style: TextStyle(fontSize: 12, color: Colors.green)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.of(context).textDark,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.getMessages(widget.roomId);
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['sender_id'] == currentUserId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isMe) {
    final bool isGift = msg['message_type'] == 'gift';
    final DateTime time = DateTime.parse(msg['created_at']);
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.of(context).primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
          ]
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (isGift) 
              _buildGiftBubbleContent(msg)
            else
              Text(msg['content'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 15)),
            const SizedBox(height: 4),
            Text(DateFormat('HH:mm').format(time), style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftBubbleContent(dynamic msg) {
    return Column(
      children: [
        const Icon(Icons.card_giftcard, color: Colors.orange, size: 40),
        const SizedBox(height: 8),
        const Text('🎁 Bạn nhận được một món quà!', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
             // Logic to open gift
          },
          child: const Text('Mở quà ngay'),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.card_giftcard, color: Colors.orange),
              onPressed: () => _openGiftBuilder(),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                onChanged: _onTypingChanged,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _openGiftBuilder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThemedGiftBuilderScreen(
          theme: 'defaultTheme',
        ),
      ),
    );
  }
}
