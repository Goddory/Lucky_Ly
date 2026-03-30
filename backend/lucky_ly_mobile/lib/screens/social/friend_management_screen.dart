import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_provider.dart';
import '../chat/chat_room_screen.dart';
import '../../providers/chat_provider.dart';
import '../../core/services/socket_service.dart';

class FriendManagementScreen extends StatefulWidget {
  const FriendManagementScreen({super.key});

  @override
  State<FriendManagementScreen> createState() => _FriendManagementScreenState();
}

class _FriendManagementScreenState extends State<FriendManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTabIndex = 0;

  // Khai báo bảng màu từ Tailwind Config do user cung cấp
  static const Color primary = Color(0xFF952CB1);
  static const Color primaryContainer = Color(0xFFF1A6FF);
  static const Color secondary = Color(0xFFBE004C);
  static const Color background = Color(0xFFFFF7FB);
  static const Color surfaceContainerLow = Color(0xFFFFEFFC);
  static const Color onSurface = Color(0xFF45274B);
  static const Color onSurfaceVariant = Color(0xFF75547A);
  static const Color outlineVariant = Color(0xFFCCA5D0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FriendProvider>();
      provider.fetchFriends();
      provider.fetchReceivedRequests();
      provider.fetchSentRequests();
      
      _initNotificationListener();
    });
  }

  void _initNotificationListener() {
    final socketService = context.read<SocketService>();
    socketService.onNotification((data) {
      if (!mounted) return;
      
      final type = data['type'];
      if (type == 'friend_request' || type == 'friend_accepted') {
        debugPrint('🔔 Friend notification received: $type. Refreshing lists...');
        final provider = context.read<FriendProvider>();
        provider.fetchFriends();
        provider.fetchReceivedRequests();
        provider.fetchSentRequests();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    try {
      context.read<SocketService>().offNotification();
    } catch (e) {
      debugPrint('Error cleaning up socket listener: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // 1. Background Decorative Icons
          Positioned(
            bottom: 128,
            left: 32,
            child: Transform.rotate(
              angle: 0.2, // ~12 degrees
              child: Icon(Icons.favorite, size: 60, color: primary.withValues(alpha: 0.1)),
            ),
          ),
          Positioned(
            top: 192,
            right: 40,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(Icons.redeem, size: 70, color: secondary.withValues(alpha: 0.1)),
            ),
          ),

          // 2. Main Scrollable Content
          Consumer<FriendProvider>(
            builder: (context, provider, child) {
              return ListView(
                padding: const EdgeInsets.only(top: 120, bottom: 40, left: 24, right: 24),
                children: [
                  _buildSearchBar(provider),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  const SizedBox(height: 24),
                  _buildCurrentTabContent(provider),
                ],
              );
            },
          ),

          // 3. Top App Bar (Glassmorphism)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  height: MediaQuery.of(context).padding.top + 60, // Bao gồm cả SafeArea (Status Bar)
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [const Color(0xFFFAF5FF).withValues(alpha: 0.9), Colors.transparent],
                    ),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF4C1D95).withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF7E22CE)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Bạn bè',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF581C87)),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.person_add, color: Color(0xFF7E22CE)),
                        onPressed: () {
                          // Focus textfield via some logic or just tap it
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Không dùng Bottom Navbar ở đây do màn hình có thể là push route hoặc embedded.
        ],
      ),
    );
  }

  // --- Search Bar ---
  Widget _buildSearchBar(FriendProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          provider.searchUsers(val);
          // Auto switch to Tab 0 if typing
          if (_currentTabIndex != 0) setState(() => _currentTabIndex = 0);
        },
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Color(0xFF926F97)),
          hintText: 'Tìm kiếm bạn bè, người mới...',
          hintStyle: TextStyle(color: Color(0xFF926F97), fontWeight: FontWeight.w500),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: onSurface, fontWeight: FontWeight.w500),
      ),
    );
  }

  // --- Tabs ---
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEDEFF).withValues(alpha: 0.5), // surface-container-high/50
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabItem('Danh sách', index: 0)),
          Expanded(child: _buildTabItem('Lời mời', index: 1)),
          Expanded(child: _buildTabItem('Đã gửi', index: 2)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, {required int index}) {
    final isActive = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primary, primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(color: onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  // --- Content Router ---
  Widget _buildCurrentTabContent(FriendProvider provider) {
    if (_currentTabIndex == 0) {
      if (_searchController.text.isNotEmpty) {
        return _buildSearchResults(provider);
      }
      return _buildActualFriends(provider);
    } else if (_currentTabIndex == 1) {
      return _buildReceivedRequestsTab(provider);
    } else {
      return _buildSentRequestsTab(provider);
    }
  }

  // --- Tab 0: Danh sách & Kết quả tìm kiếm ---
  Widget _buildSearchResults(FriendProvider provider) {
    if (provider.searchResults.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text('Không tìm thấy người dùng nào', style: TextStyle(color: onSurfaceVariant)),
        ),
      );
    }
    return Column(
      children: provider.searchResults.map((user) {
        final bool isFriend = provider.friends.any((f) => f['user_id'] == user['user_id']);
        final bool isSent = provider.sentRequests.any((r) => r['receiver_id'] == user['user_id']);
        final String type = isFriend ? 'search_friend' : (isSent ? 'search_sent' : 'search_add');
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFriendCard(
            userObj: user,
            name: user['full_name'] ?? user['username'],
            imageUrl: user['avatar_url'] ?? '',
            isOnline: false, // Don't know online status during search usually
            type: type,
            provider: provider,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActualFriends(FriendProvider provider) {
    if (provider.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
    }
    if (provider.friends.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text('Bạn chưa có người bạn nào. Hãy tìm kiếm thêm nhé!', style: TextStyle(color: onSurfaceVariant)),
        ),
      );
    }
    return Column(
      children: provider.friends.map((friend) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFriendCard(
            userObj: friend,
            name: friend['full_name'] ?? friend['username'],
            imageUrl: friend['avatar_url'] ?? '',
            isOnline: friend['is_online'] == true,
            type: 'friend',
            provider: provider,
          ),
        );
      }).toList(),
    );
  }

  // --- Tab 1: Lời mời được nhận ---
  Widget _buildReceivedRequestsTab(FriendProvider provider) {
    if (provider.receivedRequests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text('Bạn không có lời mời kết bạn nào mới.', style: TextStyle(color: onSurfaceVariant)),
        ),
      );
    }
    return Column(
      children: provider.receivedRequests.map((req) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFriendCard(
            userObj: req,
            name: req['full_name'] ?? req['username'],
            imageUrl: req['avatar_url'] ?? '',
            isOnline: false,
            type: 'received',
            provider: provider,
          ),
        );
      }).toList(),
    );
  }

  // --- Tab 2: Lời mời đã gửi ---
  Widget _buildSentRequestsTab(FriendProvider provider) {
    if (provider.sentRequests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text('Bạn chưa gửi lời mời kết bạn nào.', style: TextStyle(color: onSurfaceVariant)),
        ),
      );
    }
    return Column(
      children: provider.sentRequests.map((req) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFriendCard(
            userObj: req,
            name: req['full_name'] ?? req['username'],
            imageUrl: req['avatar_url'] ?? '',
            isOnline: false,
            type: 'sent',
            provider: provider,
          ),
        );
      }).toList(),
    );
  }

  // --- Widget Component: Friend Card Tái sử dụng ---
  Widget _buildFriendCard({
    required dynamic userObj,
    required String name, 
    required String imageUrl, 
    required bool isOnline,
    required String type,
    required FriendProvider provider,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryContainer, width: 2),
                        color: Colors.grey.shade200,
                      ),
                      child: ClipOval(
                        child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.person, color: Colors.grey))
                          : const Icon(Icons.person, color: Colors.grey),
                      )
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (userObj['username'] != null)
                        Text('@${userObj['username']}', style: const TextStyle(fontSize: 12, color: onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildCardTrailingElements(type, userObj, provider),
          )
        ],
      ),
    );
  }

  List<Widget> _buildCardTrailingElements(String type, dynamic userObj, FriendProvider provider) {
    switch (type) {
      case 'friend':
      case 'search_friend':
        return [
          _buildActionButton(
            icon: Icons.chat, 
            color: primary, 
            onTap: () => _openChat(userObj),
            shapeBg: const Color(0xFFFEDEFF)
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Tặng quà / Chuyển tiền action
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng tặng quà đang được phát triển')));
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, primaryContainer]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: const Text('TẶNG QUÀ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.more_vert, 
            color: onSurfaceVariant,
            onTap: () => _showFriendOptions(userObj),
            shapeBg: Colors.transparent,
          ),
        ];

      case 'search_add':
        return [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleSendFriendRequest(userObj, provider),
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFE879F9)]),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: const Text('KẾT BẠN', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ];

      case 'search_sent':
      case 'sent':
        return [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: onSurfaceVariant.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text('ĐÃ GỬI', style: TextStyle(color: onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ];

      case 'received':
        return [
          _buildActionButton(
            icon: Icons.check, 
            color: Colors.green, 
            onTap: () => _handleAcceptRequest(userObj, userObj, provider),
            shapeBg: Colors.green.withValues(alpha: 0.1)
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.close, 
            color: Colors.red, 
            onTap: () => _handleDeclineRequest(userObj, userObj, provider),
            shapeBg: Colors.red.withValues(alpha: 0.1)
          ),
        ];

      default:
        return const [];
    }
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap, required Color shapeBg}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: shapeBg, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // --- API Handlers (Giữ nguyên logic cũ) ---

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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.person_remove, color: Colors.red),
              ),
              title: const Text('Hủy kết bạn', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<FriendProvider>().unfriend(friend['user_id']);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendFriendRequest(dynamic user, FriendProvider provider) async {
    if (!mounted) return;
    _showMiniLoading('Đang gửi lời mời...');
    try {
      final success = await provider.sendRequest(user['user_id']);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showToast(success ? 'Đã gửi lời mời cho ${user['full_name'] ?? user['username']}' : 'Không thể gửi lời mời.', success);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showToast('Lỗi: $e', false);
      }
    }
  }

  Future<void> _handleAcceptRequest(dynamic req, dynamic sender, FriendProvider provider) async {
    if (!mounted) return;
    _showMiniLoading('Đang chấp nhận...');
    try {
      final success = await provider.acceptRequest(req['request_id'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showToast(success ? 'Đã kết bạn với ${sender['full_name'] ?? sender['username']}' : 'Không thể chấp nhận lời mời.', success);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showToast('Lỗi: $e', false);
      }
    }
  }

  Future<void> _handleDeclineRequest(dynamic req, dynamic sender, FriendProvider provider) async {
    if (!mounted) return;
    _showMiniLoading('Đang từ chối...');
    try {
      final success = await provider.declineRequest(req['request_id'].toString());
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showToast(success ? 'Đã từ chối lời mời từ ${sender['full_name'] ?? sender['username']}' : 'Không thể từ chối.', success);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showToast('Lỗi: $e', false);
      }
    }
  }

  void _showMiniLoading(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1),
      ),
    );
  }

  void _showToast(String msg, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
