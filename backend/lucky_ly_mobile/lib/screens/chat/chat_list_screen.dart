import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../app_theme.dart';
import 'chat_room_screen.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).bg,
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.of(context).textDark,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.rooms.isEmpty) return const Center(child: Text('Chưa có cuộc hội thoại nào'));

          return ListView.builder(
            itemCount: provider.rooms.length,
            itemBuilder: (context, index) {
              final room = provider.rooms[index];
              final otherUser = room['other_participant'];
              final lastMsg = room['last_message'] ?? 'Bắt đầu trò chuyện';
              final timeStr = room['last_message_at'];
              final time = timeStr != null ? DateTime.parse(timeStr) : null;
              final unread = int.tryParse(room['unread_count']?.toString() ?? '0') ?? 0;

              if (otherUser == null) {
                return const SizedBox.shrink(); // Skip rooms with no other participant
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: (otherUser['avatar_url'] != null && otherUser['avatar_url'].isNotEmpty) 
                      ? NetworkImage(otherUser['avatar_url']) 
                      : null,
                  child: (otherUser['avatar_url'] == null || otherUser['avatar_url'].isEmpty) 
                      ? const Icon(Icons.person) 
                      : null,
                ),
                title: Text(
                  otherUser['full_name'] ?? otherUser['username'] ?? 'Người dùng',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(lastMsg.toString(), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (time != null) Text(DateFormat('HH:mm').format(time), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    if (unread > 0) 
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomScreen(
                        roomId: room['room_id'],
                        otherUser: otherUser,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
