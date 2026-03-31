import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'design_selection_screen.dart';
import 'celebrate_screen.dart';
import 'offers_screen.dart';
import 'history_screen.dart';
import 'payment_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'app_theme.dart';
import 'widgets/calendar_popup.dart';
import 'widgets/theme_particles.dart';
import 'screens/avaturn_screen.dart';
import 'screens/gifts/gift_notification_screen.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';
import 'widgets/wallet_actions_sheet.dart';

import 'screens/chat/chat_list_screen.dart';
import 'screens/social/friend_management_screen.dart';
import 'providers/auth_provider.dart';
import 'core/services/socket_service.dart';
import 'screens/admin/marketing_dashboard_screen.dart';
import 'screens/admin/users_management_screen.dart';
import 'screens/admin/statistics_screen.dart';
import 'screens/admin/theme_management_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────
// HOME SCREEN (Stateful Shell)
// ─────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userEmail,
    this.userData = const {},
    this.accessToken = '',
    this.refreshToken = '',
    this.apiBaseUrl = '',
  });

  final String userEmail;
  final Map<String, dynamic> userData;
  final String accessToken;
  final String refreshToken;
  final String apiBaseUrl;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _entryController;
  late Animation<double> _fadeIn;
  double? _walletBalance;
  bool _isBalanceLoading = true;
  List<dynamic> _notifications = [];
  int _unreadNotifsCount = 0;

  @override
  void initState() {
    super.initState();
    _saveTokenToPrefs();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final auth = context.read<AuthProvider>();
      final socket = context.read<SocketService>();

      context.read<ThemeProvider>().syncThemeFromServer(
            apiBaseUrl: widget.apiBaseUrl,
            accessToken: widget.accessToken,
          );

      auth.fetchProfile();
      _fetchWalletBalance();
      _fetchNotifications();

      if (!socket.isConnected && widget.accessToken.isNotEmpty) {
        socket.connect(widget.accessToken);
      }

      socket.onNotification((data) {
        if (mounted) _showNotificationSnackbar(data);
      });
    });
  }

  void _showNotificationSnackbar(dynamic data) {
    final String type = data['type'] ?? '';
    final String message = data['message'] ?? 'Bạn có thông báo mới';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getNotificationIcon(type), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.of(context).primary,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: () => _handleNotificationTap(data),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'GIFT_RECEIVED':
        return Icons.card_giftcard;
      case 'FRIEND_REQUEST':
        return Icons.group_add;
      case 'FRIEND_ACCEPTED':
        return Icons.person_add;
      case 'NEW_MESSAGE':
        return Icons.chat_bubble;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(dynamic data) {
    final String type = data['type'] ?? '';
    if (type == 'FRIEND_REQUEST' || type == 'FRIEND_ACCEPTED') {
      // Navigate to Friends
    } else if (type == 'NEW_MESSAGE') {
      // Navigate to Chat
    } else if (type.startsWith('GIFT')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GiftNotificationScreen()),
      );
    }
  }

  Future<void> _saveTokenToPrefs() async {
    if (widget.accessToken.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', widget.accessToken);
      await prefs.setString('access_token', widget.accessToken);
      if (widget.refreshToken.isNotEmpty) {
        await prefs.setString('refreshToken', widget.refreshToken);
      }

      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.accessToken == null || auth.accessToken!.isEmpty) {
          auth.setSession(
            accessToken: widget.accessToken,
            refreshToken: widget.refreshToken,
            email: widget.userEmail,
          );
        }
      }
      debugPrint('DEBUG: Token saved to SharedPreferences (both keys)');
    }
  }

  bool _isMarketingAdmin() {
    final role = widget.userData['role']?.toString().toLowerCase();
    return role == 'marketing_admin';
  }

  bool _isAdmin() {
    final role = widget.userData['role']?.toString().toLowerCase();
    return role == 'admin' || role == 'marketing_admin';
  }

  Future<void> _fetchWalletBalance() async {
    if (!mounted) return;
    setState(() => _isBalanceLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? prefs.getString('access_token');
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/payment/wallet/balance'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _walletBalance = (data['balance'] as num).toDouble();
            _isBalanceLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching balance: $e');
      if (mounted) setState(() => _isBalanceLoading = false);
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? prefs.getString('access_token');
      if (token == null) return;
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/users/me/notifications'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _unreadNotifsCount = data['unread_count'] ?? 0;
            _notifications = data['notifications'] ?? [];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _markNotificationsRead() async {
    if (_unreadNotifsCount == 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? prefs.getString('access_token');
      if (token == null) return;
      await http.put(
        Uri.parse('${widget.apiBaseUrl}/api/users/me/notifications/read'),
        headers: { 'Authorization': 'Bearer $token' },
      );
      if (mounted) {
        setState(() {
          _unreadNotifsCount = 0;
        });
      }
    } catch (_) {}
  }

  // ── HOME SCREEN TABS ──────────────────────────────────────────
  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      body: Stack(
        children: [
          // Theme particles layer
          const ThemeParticles(),

          // Content by tab
          if (_currentTab == 1)
            const OffersScreen()
          else if (_currentTab == 3)
            const HistoryScreen()
          else if (_currentTab == 4)
            ProfileScreen(
              userData: widget.userData,
              accessToken: widget.accessToken,
              refreshToken: widget.refreshToken,
              apiBaseUrl: widget.apiBaseUrl,
            )
          else
            FadeTransition(
              opacity: _fadeIn,
              child: SafeArea(
                bottom: false,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    _LuckyHeader(
                      userData: widget.userData,
                      unreadNotifsCount: _unreadNotifsCount,
                      onGiftTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GiftNotificationScreen()),
                      ),
                      onNotifTap: () => _showNotificationOverlay(context),
                      onChatTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChatListScreen()),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _WelcomeBanner(userData: widget.userData),
                          const SizedBox(height: 28),
                          _QuickActionsRow(
                            onCameraTap: () =>
                                _handleCameraAccess(context),
                            onTransactionTap: _isAdmin() ? () async {
                              await showAdminAddMoneySheet(context);
                              _fetchWalletBalance();
                            } : null,
                            onCalendarTap: () =>
                                CalendarPopup.show(context),
                            onFriendsTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const FriendManagementScreen()),
                            ),
                            onStudioTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DesignSelectionScreen(
                                          type: 'item')),
                            ),
                          ),
                          const SizedBox(height: 28),
                          _WalletAndCelebrateSection(
                            balance: _walletBalance,
                            isLoading: _isBalanceLoading,
                            onRefresh: _fetchWalletBalance,
                            onCelebrateTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CelebrateScreen()),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_isAdmin()) ...[
                            _AdminGrid(
                              apiBaseUrl: widget.apiBaseUrl,
                              accessToken: widget.accessToken,
                            ),
                          ] else ...[
                            _FeatureGrid(
                              isMarketing: _isMarketingAdmin(),
                              onAvatarTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AvaturnScreen()),
                              ),
                              onMarketingTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MarketingDashboardScreen(
                                    apiBaseUrl: widget.apiBaseUrl,
                                    accessToken: widget.accessToken,
                                  ),
                                ),
                              ),
                              onPaymentTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => PaymentScreen()),
                              ),
                            ),
                            const SizedBox(height: 28),
                            _OngoingEventsSection(),
                            const SizedBox(height: 28),
                            const _PromotionBanner(),
                          ],
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Navigation overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _LuckyBottomNav(
              currentTab: _currentTab,
              onTabChanged: (i) => setState(() => _currentTab = i),
              onCameraFab: () => _handleCameraAccess(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── NOTIFICATION OVERLAY ───────────────────────────────────
  void _showNotificationOverlay(BuildContext context) {
    _markNotificationsRead();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Thông báo hệ thống', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF45274B))),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _notifications.isEmpty
                  ? const Center(child: Text('Không có thông báo nào.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (ctx, i) {
                        final notif = _notifications[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: notif['is_read'] ? Colors.white : const Color(0xFFFFF7FB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: notif['is_read'] ? Colors.black12 : const Color(0xFFF1A6FF)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFF952CB1).withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.campaign, color: Color(0xFF952CB1), size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(notif['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF45274B))),
                                    const SizedBox(height: 4),
                                    Text(notif['content'] ?? '', style: const TextStyle(color: Color(0xFF75547A), fontSize: 13, height: 1.4)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CAMERA ACCESS ──────────────────────────────────────────
  Future<void> _handleCameraAccess(BuildContext context) async {
    var status = await Permission.camera.request();

    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không tìm thấy camera trên thiết bị.')),
        );
        return;
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CameraScreen(cameras: cameras)),
      );
    } else if (status.isPermanentlyDenied) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Quyền truy cập Camera'),
          content: const Text(
              'Ứng dụng cần quyền Camera để chụp ảnh. Vui lòng cấp quyền trong Cài đặt.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy')),
            TextButton(
                onPressed: () => openAppSettings(),
                child: const Text('Cài đặt')),
          ],
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════
class _LuckyHeader extends StatelessWidget {
  const _LuckyHeader({
    required this.userData,
    required this.unreadNotifsCount,
    required this.onGiftTap,
    required this.onNotifTap,
    required this.onChatTap,
  });

  final Map<String, dynamic> userData;
  final int unreadNotifsCount;
  final VoidCallback onGiftTap;
  final VoidCallback onNotifTap;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = userData['avatarUrl'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF952CB1).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Avatar + Logo
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFF1A6FF), width: 2.5),
                  image: avatarUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: avatarUrl.isEmpty
                      ? const LinearGradient(
                          colors: [Color(0xFF9333EA), Color(0xFFF472B6)])
                      : null,
                ),
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 22)
                    : null,
              ),
              const SizedBox(width: 12),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF9333EA), Color(0xFFF472B6)],
                ).createShader(bounds),
                child: const Text(
                  'LuckyLy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Action buttons
          Row(
            children: [
              _HeaderIconBtn(
                icon: Icons.card_giftcard_outlined,
                onTap: onGiftTap,
              ),
              const SizedBox(width: 8),
              _HeaderIconBtn(
                icon: Icons.notifications_outlined,
                badge: unreadNotifsCount,
                onTap: onNotifTap,
              ),
              const SizedBox(width: 8),
              _HeaderIconBtn(
                icon: Icons.chat_bubble_outline,
                onTap: onChatTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({required this.icon, this.badge = 0, this.onTap});

  final IconData icon;
  final int badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF952CB1).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF952CB1), size: 22),
          ),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), shape: BoxShape.circle),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WELCOME BANNER
// ═══════════════════════════════════════════════════════════════
class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.userData});

  final Map<String, dynamic> userData;

  @override
  Widget build(BuildContext context) {
    final isMarketing = (userData['role']?.toString().toLowerCase() ==
        'marketing_admin');
    final rawName =
      userData['full_name'] ?? userData['fullName'] ?? userData['username'] ?? 'Bạn';
    final name = rawName.toString().trim().isEmpty ? 'Bạn' : rawName.toString().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMarketing ? 'Xin chào Marketing Admin!' : 'Xin chào $name!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF45274B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isMarketing
              ? 'Hôm nay chúng ta sẽ bùng nổ chiến dịch gì?'
              : 'Wish u a niceee dayyy! 🌸',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF75547A),
          ),
        ),
        const SizedBox(height: 16),
        // Search bar
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEFFC),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: const Color(0xFFCCA5D0).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search, color: Color(0xFF926F97), size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Tìm kiếm sự kiện hoặc quà tặng...',
                  style: TextStyle(
                      color: Color(0xFFCCA5D0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF952CB1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Tìm',
                  style: TextStyle(
                      color: Color(0xFF952CB1),
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// QUICK ACTIONS ROW
// ═══════════════════════════════════════════════════════════════
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onCameraTap,
    this.onTransactionTap,
    required this.onCalendarTap,
    required this.onFriendsTap,
    required this.onStudioTap,
  });

  final VoidCallback onCameraTap;
  final VoidCallback? onTransactionTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onFriendsTap;
  final VoidCallback onStudioTap;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionDef(Icons.photo_camera_outlined, 'CAMERA', onCameraTap),
      if (onTransactionTap != null)
        _ActionDef(Icons.swap_horiz_rounded, 'GIAO DỊCH', onTransactionTap),
      _ActionDef(Icons.calendar_today_outlined, 'LỊCH', onCalendarTap),
      _ActionDef(Icons.group_outlined, 'BẠN BÈ', onFriendsTap),
      _ActionDef(Icons.auto_awesome_mosaic_outlined, 'STUDIO', onStudioTap),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions
          .map((a) => AnimatedInteractiveScale(
                onTap: a.onTap,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF5D0FF), Color(0xFFE4AAFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF952CB1).withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(a.icon,
                          color: const Color(0xFF952CB1), size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a.label,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF75547A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ActionDef {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _ActionDef(this.icon, this.label, this.onTap);
}

// ═══════════════════════════════════════════════════════════════
// WALLET + CELEBRATE SECTION
// ═══════════════════════════════════════════════════════════════
class _WalletAndCelebrateSection extends StatelessWidget {
  const _WalletAndCelebrateSection({
    required this.onCelebrateTap,
    this.balance,
    required this.isLoading,
    required this.onRefresh,
  });

  final VoidCallback onCelebrateTap;
  final double? balance;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Wallet Card ──────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF952CB1), Color(0xFFD472F9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF952CB1).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Ví Lucky Ly',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onRefresh,
                        child: Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.visibility_outlined, color: Colors.white70),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const SizedBox(
                  height: 42,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                )
              else
                Text(
                  balance != null
                      ? '${balance!.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}đ'
                      : '--- đ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '▲ 0.0% so với hôm qua',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _WalletActionBtn('Nạp tiền', Icons.add_circle_outline, onTap: () async {
                      await showTopUpSheet(context);
                      onRefresh();
                    }),
                    const SizedBox(width: 12),
                    _WalletActionBtn('Rút tiền', Icons.remove_circle_outline, onTap: () async {
                      await showWithdrawSheet(context);
                      onRefresh();
                    }),
                    const SizedBox(width: 12),
                    _WalletActionBtn('Chuyển', Icons.swap_horiz_rounded, onTap: () async {
                      await showTransferSheet(context);
                      onRefresh();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Celebrate Card ───────────────────────────────────
        GestureDetector(
          onTap: onCelebrateTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: const Color(0xFFCCA5D0).withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF952CB1).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFBD0055).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.celebration,
                                size: 12, color: Color(0xFFBD0055)),
                            SizedBox(width: 4),
                            Text(
                              'ACTIVE',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFBD0055)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Celebrate Now',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF45274B)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Gửi quà cho bạn bè ngay hôm nay!',
                        style: TextStyle(
                            fontSize: 13, color: Color(0xFF75547A)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5D0FF), Color(0xFFE4AAFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.card_giftcard,
                      size: 32, color: Color(0xFF952CB1)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletActionBtn extends StatelessWidget {
  const _WalletActionBtn(this.label, this.icon, {this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FEATURE GRID
// ═══════════════════════════════════════════════════════════════
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({
    required this.isMarketing,
    required this.onAvatarTap,
    required this.onMarketingTap,
    required this.onPaymentTap,
  });

  final bool isMarketing;
  final VoidCallback onAvatarTap;
  final VoidCallback onMarketingTap;
  final VoidCallback onPaymentTap;

  @override
  Widget build(BuildContext context) {
    final features = <_FeatureDef>[
      _FeatureDef(
        Icons.person_add_alt_1,
        'Tạo Avatar',
        const Color(0xFF952CB1),
        onAvatarTap,
      ),
      if (isMarketing)
        _FeatureDef(
          Icons.campaign_outlined,
          'Marketing\nHub',
          const Color(0xFFBE004C),
          onMarketingTap,
        ),
      _FeatureDef(
        Icons.payments_outlined,
        'Thanh toán',
        const Color(0xFFBD0055),
        onPaymentTap,
      ),
      _FeatureDef(
        Icons.receipt_long_outlined,
        'Hóa đơn',
        const Color(0xFF7C3AED),
        null,
      ),
      if (!isMarketing)
        _FeatureDef(
          Icons.grid_view_rounded,
          'Thêm',
          const Color(0xFF94A3B8),
          null,
        ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.25,
      children: features.map((f) => _FeatureTile(feature: f)).toList(),
    );
  }
}

class _FeatureDef {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;
  const _FeatureDef(this.icon, this.title, this.color, this.onTap);
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _FeatureDef feature;

  @override
  Widget build(BuildContext context) {
    return AnimatedInteractiveScale(
      onTap: feature.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: feature.color.withValues(alpha: 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: feature.color.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(feature.icon, color: feature.color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              feature.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF45274B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGOING EVENTS
// ═══════════════════════════════════════════════════════════════
class _OngoingEventsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sự kiện đang diễn ra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF45274B),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Tất cả',
                style: TextStyle(
                    color: Color(0xFF952CB1), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF952CB1), Color(0xFFD472F9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: -15,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ĐANG DIỄN RA',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sale mô hình Tết 2025',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hơn 500 phần quà đang chờ đón bạn',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    // Nhận ngay 10K
                    Row(
                      children: [
                        const Text(
                          'Nhận ngay 10K',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Nhận ngay',
                            style: TextStyle(
                              color: Color(0xFF952CB1),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROMOTION BANNER
// ═══════════════════════════════════════════════════════════════
class _PromotionBanner extends StatelessWidget {
  const _PromotionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFBE004C), Color(0xFFFF5E8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBE004C).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NHẬN NGAY 10K',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Khi mời bạn bè tham gia LuckyLy lần đầu nhé!',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    foregroundColor: const Color(0xFFBE004C),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    elevation: 0,
                  ),
                  child: const Text('Nhận ngay',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                const Icon(Icons.card_membership, color: Colors.white, size: 42),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM NAV
// ═══════════════════════════════════════════════════════════════
class _LuckyBottomNav extends StatelessWidget {
  const _LuckyBottomNav({
    required this.currentTab,
    required this.onTabChanged,
    required this.onCameraFab,
  });

  final int currentTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onCameraFab;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF45274B).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
                icon: Icons.home_filled,
                label: 'Trang chủ',
                isActive: currentTab == 0,
                onTap: () => onTabChanged(0)),
            _NavItem(
                icon: Icons.local_offer_outlined,
                label: 'Ưu đãi',
                isActive: currentTab == 1,
                onTap: () => onTabChanged(1)),

            // Camera FAB (center)
            GestureDetector(
              onTap: onCameraFab,
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF9333EA), Color(0xFFF472B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x55952CB1),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 24),
                    Text(
                      'Camera',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),

            _NavItem(
                icon: Icons.history_rounded,
                label: 'Lịch sử',
                isActive: currentTab == 3,
                onTap: () => onTabChanged(3)),
            _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Tôi',
                isActive: currentTab == 4,
                onTap: () => onTabChanged(4)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF952CB1).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? const Color(0xFF952CB1)
                  : const Color(0xFFC084FC),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF952CB1)
                    : const Color(0xFFC084FC),
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CAMERA SCREEN
// ═══════════════════════════════════════════════════════════════
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera(widget.cameras[_cameraIndex]);
  }

  Future<void> _initCamera(CameraDescription description) async {
    _controller = CameraController(description, ResolutionPreset.high);
    try {
      await _controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera Error: $e');
    }
  }

  void _toggleCamera() {
    if (widget.cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % widget.cameras.length;
    _initCamera(widget.cameras[_cameraIndex]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CustomLoading(size: 80)));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller)),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios,
                      color: Colors.white, size: 32),
                  onPressed: _toggleCamera,
                ),
                GestureDetector(
                  onTap: () async {
                    try {
                      await _controller.takePicture();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chụp ảnh!')),
                      );
                    } catch (e) {
                      debugPrint('Lỗi chụp ảnh: $e');
                    }
                  },
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 4)),
                    child: const Center(
                        child: Icon(Icons.camera,
                            color: Colors.white, size: 40)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ADMIN GRID
// ═══════════════════════════════════════════════════════════════
class _AdminGrid extends StatelessWidget {
  const _AdminGrid({
    required this.apiBaseUrl,
    required this.accessToken,
  });

  final String apiBaseUrl;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.18,
      children: [
        _AdminCard(
          title: 'Quản lý\nNgười dùng',
          icon: Icons.face_retouching_natural,
          color: const Color(0xFF9D3ACE),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UsersManagementScreen(
                apiBaseUrl: apiBaseUrl,
                accessToken: accessToken,
              ),
            ),
          ),
        ),
        _AdminCard(
          title: 'Báo cáo và\nThống kê',
          icon: Icons.hub_outlined,
          color: const Color(0xFFC0065B),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StatisticsScreen(
                apiBaseUrl: apiBaseUrl,
                accessToken: accessToken,
              ),
            ),
          ),
        ),
        _AdminCard(
          title: 'Quản lý\nGiao diện',
          icon: Icons.payments_outlined,
          color: const Color(0xFFC0065B),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ThemeManagementScreen(
                apiBaseUrl: apiBaseUrl,
                accessToken: accessToken,
              ),
            ),
          ),
        ),
        _AdminCard(
          title: 'Marketing &\nKhuyến mãi',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarketingDashboardScreen(
                apiBaseUrl: apiBaseUrl,
                accessToken: accessToken,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return AnimatedInteractiveScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: theme.textDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
