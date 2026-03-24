import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'design_selection_screen.dart';
import 'celebrate_screen.dart';
import 'offers_screen.dart';
import 'history_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'app_theme.dart';
import 'widgets/calendar_popup.dart';
import 'widgets/theme_particles.dart';
import 'screens/avaturn_screen.dart';
import 'screens/gifts/gift_notification_screen.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';

import 'screens/chat/chat_list_screen.dart';
import 'screens/social/friend_management_screen.dart';
import 'providers/auth_provider.dart';
import 'core/services/socket_service.dart';

// Constants moved to app_theme.dart

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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _entryController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final auth = context.read<AuthProvider>();
      final socket = context.read<SocketService>();

      // Sync theme
      context.read<ThemeProvider>().syncThemeFromServer(
        apiBaseUrl: widget.apiBaseUrl,
        accessToken: widget.accessToken,
      );

      // Fetch profile
      auth.fetchProfile();

      // Ensure socket connected
      if (!socket.isConnected && widget.accessToken.isNotEmpty) {
        socket.connect(widget.accessToken);
      }

      // Listen for notifications
      socket.onNotification((data) {
        if (mounted) {
          _showNotificationSnackbar(data);
        }
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
            Icon(
              _getNotificationIcon(type),
              color: Colors.white,
            ),
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
      case 'GIFT_RECEIVED': return Icons.card_giftcard;
      case 'FRIEND_REQUEST': return Icons.group_add;
      case 'FRIEND_ACCEPTED': return Icons.person_add;
      case 'NEW_MESSAGE': return Icons.chat_bubble;
      default: return Icons.notifications;
    }
  }

  void _handleNotificationTap(dynamic data) {
    final String type = data['type'] ?? '';
    // Navigate based on type
    if (type == 'FRIEND_REQUEST' || type == 'FRIEND_ACCEPTED') {
       // Navigate to Friends
    } else if (type == 'NEW_MESSAGE') {
       // Navigate to Chat
    } else if (type.startsWith('GIFT')) {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const GiftNotificationScreen()));
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).bg,
      body: Stack(
        children: [
          const ThemeParticles(),
          _currentTab == 1
              ? const OffersScreen()
              : _currentTab == 3
                  ? const HistoryScreen()
                  : _currentTab == 4
                      ? ProfileScreen(
                          userData: widget.userData,
                          accessToken: widget.accessToken,
                          refreshToken: widget.refreshToken,
                          apiBaseUrl: widget.apiBaseUrl,
                        )
                      : FadeTransition(
                          opacity: _fadeIn,
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              _buildSliverHeader(context),
                              SliverToBoxAdapter(child: _buildQuickActions()),
                              SliverToBoxAdapter(child: _buildWalletCard()),
                              const SliverToBoxAdapter(child: SizedBox(height: 8)),
                              _buildPremiumServiceGrid(),
                              SliverToBoxAdapter(child: _buildEventsSection()),
                              const SliverToBoxAdapter(child: SizedBox(height: 100)),
                            ],
                          ),
                        ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildQrFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  // ─── HEADER ───────────────────────────────────────────────
  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 96,
      floating: true,
      snap: true,
      pinned: false,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppTheme.of(context).primaryGradient),
        child: Stack(
          children: [
            _buildThemeDecorations(context),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    // Search bar + actions
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const Icon(Icons.search, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tìm kiếm dịch vụ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.content_paste, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Dán', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    _HeaderIconBtn(
                      icon: Icons.card_giftcard, 
                      badge: 0,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GiftNotificationScreen())),
                    ),
                    const SizedBox(width: 10),
                    _HeaderIconBtn(
                      icon: Icons.notifications_none_outlined, 
                      badge: 1,
                      onTap: () => _showNotificationOverlay(context),
                    ),
                    const SizedBox(width: 10),
                    _HeaderIconBtn(
                      icon: Icons.chat_bubble_outline, 
                      badge: 0,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
            ],
          ),
      ),
    );
  }

  Widget _buildThemeDecorations(BuildContext context) {
    final themeType = Provider.of<ThemeProvider>(context).currentTheme;
    final isTet = themeType == AppThemeType.tet;
    final isVal = themeType == AppThemeType.valentine;
    
    if (!isTet && !isVal) return const SizedBox.shrink();

    return Stack(
      children: [
        // Glow effect
        Positioned(
          top: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 100,
                  spreadRadius: 50,
                ),
              ],
            ),
          ),
        ),
        if (isTet) ...[
          Positioned(top: -20, left: 10, child: _AnimatedFloatingWidget(durationSeconds: 3.0, offsetFactor: 15, child: Transform.rotate(angle: -0.2, child: Opacity(opacity: 0.4, child: Text('🌸', style: TextStyle(fontSize: 80)))))),
          Positioned(top: -10, right: -10, child: _AnimatedFloatingWidget(durationSeconds: 2.5, offsetFactor: 12, child: Transform.rotate(angle: 0.3, child: Opacity(opacity: 0.35, child: Text('🌼', style: TextStyle(fontSize: 90)))))),
          Positioned(top: 40, left: MediaQuery.of(context).size.width / 2 - 30, child: _AnimatedFloatingWidget(durationSeconds: 2.0, offsetFactor: 8, child: Opacity(opacity: 0.4, child: Text('🏮', style: TextStyle(fontSize: 45))))),
        ] else if (isVal) ...[
          Positioned(top: -10, left: 15, child: _AnimatedFloatingWidget(durationSeconds: 2.5, offsetFactor: 10, child: Transform.rotate(angle: -0.15, child: Opacity(opacity: 0.8, child: Image.asset('assets/images/ValentineTheme/Chocobar.png', width: 70, height: 70))))),
          Positioned(top: -20, right: 10, child: _AnimatedFloatingWidget(durationSeconds: 3.2, offsetFactor: 15, child: Transform.rotate(angle: 0.2, child: Opacity(opacity: 0.8, child: Image.asset('assets/images/ValentineTheme/Lich1402.png', width: 80, height: 80))))),
          Positioned(top: 30, left: MediaQuery.of(context).size.width / 2, child: _AnimatedFloatingWidget(durationSeconds: 2.0, offsetFactor: 8, child: Opacity(opacity: 0.8, child: Image.asset('assets/images/ValentineTheme/Cungtentinhyeu.png', width: 45, height: 45)))),
        ],
      ],
    );
  }

  // ─── QUICK ACTIONS ROW ────────────────────────────────────
  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.of(context).primaryGradient),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickAction(
            icon: Icons.camera_alt_outlined, 
            label: 'Máy ảnh',
            onTap: () => _handleCameraAccess(context),
          ),
          _QuickAction(
            icon: Icons.swap_horiz, 
            label: 'Nạp/Rút'
          ),
          _QuickAction(
            icon: Icons.calendar_month_outlined, 
            label: 'Lịch',
            onTap: () => CalendarPopup.show(context),
          ),
          _QuickAction(
            icon: Icons.card_giftcard, 
            label: 'Bạn Bè',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendManagementScreen())),
          ),
          _QuickAction(
            icon: Icons.auto_awesome_mosaic_outlined, 
            label: 'Xưởng Studio',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignSelectionScreen(type: 'item'))),
          ),
        ],
      ),
    );
  }

  // ─── WALLET CARD ──────────────────────────────────────────
  Widget _buildWalletCard() {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.of(context).card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _WalletItem(
                  label: 'Ví Lucky Ly',
                  amount: '4.901đ',
                  icon: Icons.account_balance_wallet,
                  iconColor: AppTheme.of(context).primary,
                ),
                _WalletDivider(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CelebrateScreen()),
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: _WalletItem(
                    label: 'Celebrate',
                    amount: 'Mẫu Lễ Hội',
                    icon: Icons.celebration,
                    iconColor: Colors.pinkAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildPremiumServiceGrid() {
    final services = [
      _ServiceItem(
        'Tạo Avatar',
        Icons.person_add_alt_1,
        Colors.purpleAccent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AvaturnScreen()),
        ),
      ),
      _ServiceItem('Thanh toán', Icons.money_off, AppTheme.of(context).primary),
      _ServiceItem('Hóa đơn', Icons.receipt_long, AppTheme.of(context).accent),
      _ServiceItem('Thêm', Icons.grid_view, AppTheme.of(context).textMuted),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1.15, // Higher ratio = less vertical space
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final s = services[index];
            return _ServiceGridTile(service: s);
          },
          childCount: services.length,
        ),
      ),
    );
  }

  void _showNotificationOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.of(context).card,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.of(context).divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.of(context).accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.campaign, color: AppTheme.of(context).accent, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Chào mừng bạn đến với Lucky Ly!',
              style: TextStyle(
                color: AppTheme.of(context).textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tận hưởng các dịch vụ tài chính thông minh và ưu đãi hấp dẫn dành riêng cho bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.of(context).textMuted,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.of(context).primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Bắt đầu ngay', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── EVENTS SECTION ───────────────────────────────────────
  Widget _buildEventsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'Sự kiện đang diễn ra',
              style: TextStyle(
                color: AppTheme.of(context).textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          const SizedBox(height: 14),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppTheme.of(context).primary,
                  AppTheme.of(context).accent,
                  AppTheme.of(context).primary.withValues(alpha: 0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.of(context).primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Nhận ngay 10K',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'khi tự chuyển 2K\ntừ Lucky Ly!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Nhận ngay',
                          style: TextStyle(
                            color: AppTheme.of(context).primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ───────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.of(context).card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_filled, label: 'Trang chủ', isActive: _currentTab == 0, onTap: () => setState(() => _currentTab = 0)),
              _NavItem(icon: Icons.local_offer_outlined, label: 'Ưu đãi', isActive: _currentTab == 1, onTap: () => setState(() => _currentTab = 1)),
              const SizedBox(width: 56), // space for FAB
              _NavItem(icon: Icons.history, label: 'Lịch sử GD', isActive: _currentTab == 3, onTap: () => setState(() => _currentTab = 3)),
              _NavItem(icon: Icons.person_outline, label: 'Tôi', isActive: _currentTab == 4, onTap: () => setState(() => _currentTab = 4)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── QR FAB ───────────────────────────────────────────────
  Widget _buildQrFab() {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        gradient: AppTheme.of(context).primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppTheme.glowShadow(AppTheme.of(context).primary),
      ),
      child: FloatingActionButton(
        elevation: 0,
        backgroundColor: Colors.transparent,
        onPressed: () => _handleCameraAccess(context),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.white, size: 26),
            Text('Camera', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  // Logic xử lý quyền và mở Camera
  Future<void> _handleCameraAccess(BuildContext context) async {
    // 1. Xin quyền Camera
    var status = await Permission.camera.request();
    
    if (status.isGranted) {
      // 2. Lấy danh sách camera khả dụng
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) _showSimpleMessage('Không tìm thấy camera trên thiết bị.');
        return;
      }
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CameraScreen(cameras: cameras)),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Quyền truy cập Camera'),
            content: const Text('Ứng dụng cần quyền Camera để chụp ảnh. Vui lòng cấp quyền trong Cài đặt.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              TextButton(onPressed: () => openAppSettings(), child: const Text('Cài đặt')),
            ],
          ),
        );
      }
    }
  }

  void _showSimpleMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ─── MÀN HÌNH CAMERA ──────────────────────────────────────────
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  int _cameraIndex = 0; // 0 thường là cam sau, 1 là cam trước

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
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: const CustomLoading(size: 80)));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller)),
          // Nút chụp & Đổi Camera
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 32),
                  onPressed: _toggleCamera,
                ),
                GestureDetector(
                  onTap: () async {
                    try {
                      await _controller.takePicture();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chụp ảnh!')));
                    } catch (e) {
                      debugPrint('Lỗi chụp ảnh: $e');
                    }
                  },
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4)),
                    child: const Center(child: Icon(Icons.camera, color: Colors.white, size: 40)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
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
// SUB-WIDGETS
// ═══════════════════════════════════════════════════════════════

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
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        if (badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badge',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedInteractiveScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 12, 
              fontWeight: FontWeight.w700, 
              height: 1.2,
              letterSpacing: -0.2,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFloatingWidget extends StatefulWidget {
  final Widget child;
  final double durationSeconds;
  final double offsetFactor;
  const _AnimatedFloatingWidget({required this.child, this.durationSeconds = 2.0, this.offsetFactor = 10.0});

  @override
  State<_AnimatedFloatingWidget> createState() => _AnimatedFloatingWidgetState();
}

class _AnimatedFloatingWidgetState extends State<_AnimatedFloatingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (widget.durationSeconds * 1000).toInt()),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_controller.value * widget.offsetFactor),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _WalletItem extends StatelessWidget {
  const _WalletItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.of(context).textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  amount,
                  style: TextStyle(
                    color: AppTheme.of(context).textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 16, color: AppTheme.of(context).textLight),
            ],
          ),
        ],
      ),
    );
  }
}

class _WalletDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFFF1F5F9),
    );
  }
}

class _ServiceItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ServiceItem(this.label, this.icon, this.color, {this.onTap});
}

class _ServiceGridTile extends StatelessWidget {
  const _ServiceGridTile({required this.service});

  final _ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return AnimatedInteractiveScale(
      onTap: service.onTap ?? () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.of(context).card,
          border: Border.all(color: AppTheme.of(context).divider.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 40, // Smaller icon container
              width: 40,
              decoration: BoxDecoration(
                color: service.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(service.icon, color: service.color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              service.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.of(context).textDark, 
                fontSize: 10, 
                fontWeight: FontWeight.w700, 
                letterSpacing: -0.2,
              ),
            ),
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
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.of(context).primary : AppTheme.of(context).textLight,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.of(context).primary : AppTheme.of(context).textLight,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
