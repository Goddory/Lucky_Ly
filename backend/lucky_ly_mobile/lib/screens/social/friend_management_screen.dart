import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../../app_theme.dart';
import '../chat/chat_room_screen.dart';
import '../../providers/chat_provider.dart';

class FriendManagementScreen extends StatefulWidget {
  const FriendManagementScreen({super.key});

  @override
  State<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends State<FriendManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FriendProvider>();
      provider.fetchFriends();
      provider.fetchReceivedRequests();
      provider.fetchSentRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).bg,
      appBar: AppBar(
        title: const Text('Bạn bè', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.of(context).textDark,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.of(context).primary,
          unselectedLabelColor: AppTheme.of(context).textMuted,
          indicatorColor: AppTheme.of(context).primary,
          tabs: const [
            Tab(text: 'Danh sách'),
            Tab(text: 'Lời mời'),
            Tab(text: 'Đã gửi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFriendListTab(),
          _buildReceivedRequestsTab(),
          _buildSentRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildFriendListTab() {
    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bạn bè hoặc người mới...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => provider.searchUsers(val),
              ),
            ),
            Expanded(
              child: _searchController.text.isNotEmpty
                  ? _buildSearchResults(provider)
                  : _buildActualFriends(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(FriendProvider provider) {
    if (provider.searchResults.isEmpty) {
      return const Center(child: Text('Không tìm thấy người dùng nào'));
    }
    return ListView.builder(
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final user = provider.searchResults[index];
        final bool isFriend = provider.friends.any((f) => f['user_id'] == user['user_id']);
        final bool isSent = provider.sentRequests.any((r) => r['receiver_id'] == user['user_id']);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
          ),
          title: Text(user['full_name'] ?? user['username']),
          subtitle: Text('@${user['username']}'),
          trailing: isFriend
              ? const Icon(Icons.check_circle, color: Colors.green)
              : isSent
                  ? const Text('Đã gửi', style: TextStyle(color: Colors.grey))
                  : ElevatedButton(
                      onPressed: () => provider.sendRequest(user['user_id']),
                      child: const Text('Kết bạn'),
                    ),
        );
      },
    );
  }

  Widget _buildActualFriends(FriendProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.friends.isEmpty) {
      return const Center(child: Text('Bạn chưa có người bạn nào. Hãy tìm kiếm thêm nhé!'));
    }
    return ListView.builder(
      itemCount: provider.friends.length,
      itemBuilder: (context, index) {
        final friend = provider.friends[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: friend['avatar_url'] != null ? NetworkImage(friend['avatar_url']) : null,
            child: friend['avatar_url'] == null ? const Icon(Icons.person) : null,
          ),
          title: Text(friend['full_name'] ?? friend['username']),
          subtitle: Text('@${friend['username']}'),
          onTap: () => _openChat(friend),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showFriendOptions(friend),
          ),
        );
      },
    );
  }

  Widget _buildReceivedRequestsTab() {
    return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        if (provider.receivedRequests.isEmpty) {
          return const Center(child: Text('Không có lời mời kết bạn nào.'));
        }
        return ListView.builder(
          itemCount: provider.receivedRequests.length,
          itemBuilder: (context, index) {
            final req = provider.receivedRequests[index];
            final sender = req['sender'];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: sender['avatar_url'] != null ? NetworkImage(sender['avatar_url']) : null,
                child: sender['avatar_url'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(sender['full_name'] ?? sender['username']),
              subtitle: const Text('Muốn kết bạn với bạn'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => provider.acceptRequest(req['id']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => provider.declineRequest(req['id']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequestsTab() {
     return Consumer<FriendProvider>(
      builder: (context, provider, child) {
        if (provider.sentRequests.isEmpty) {
          return const Center(child: Text('Bạn chưa gửi lời mời nào.'));
        }
        return ListView.builder(
          itemCount: provider.sentRequests.length,
          itemBuilder: (context, index) {
            final req = provider.sentRequests[index];
            final receiver = req['receiver'];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: receiver['avatar_url'] != null ? NetworkImage(receiver['avatar_url']) : null,
                child: receiver['avatar_url'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(receiver['full_name'] ?? receiver['username']),
              subtitle: const Text('Đang chờ phản hồi...'),
              trailing: TextButton(
                onPressed: () { /* implementation for cancel request if needed */ },
                child: const Text('Hủy', style: TextStyle(color: Colors.red)),
              ),
            );
          },
        );
      },
    );
  }

  void _openChat(dynamic friend) async {
    final roomId = await context.read<ChatProvider>().getOrCreateRoom(friend['user_id']);
    if (roomId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomScreen(
            roomId: roomId,
            otherUser: friend,
          ),
        ),
      );
    }
  }

  void _showFriendOptions(dynamic friend) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person_remove, color: Colors.red),
            title: const Text('Hủy kết bạn', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              context.read<FriendProvider>().unfriend(friend['user_id']);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Chặn'),
            onTap: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}
