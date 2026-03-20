import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'profile_screen.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'gift_center_screen.dart';
import 'design_selection_screen.dart';
import 'celebrate_screen.dart';
import 'offers_screen.dart';
import 'history_screen.dart';
import 'app_theme.dart';
import 'deposit_screen.dart';

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
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (widget.accessToken.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/users/me'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (mounted) {
          setState(() => _userProfile = body['user']);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile in home: $e');
    }
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${buffer.toString()}đ';
  }


  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: _currentTab == 1
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
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            const Icon(Icons.search, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tìm kiếm dịch vụ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(16),
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
                      icon: Icons.notifications_none_outlined, 
                      badge: 1,
                      onTap: () => _showNotificationOverlay(context),
                    ),
                    const SizedBox(width: 10),
                    _HeaderIconBtn(icon: Icons.chat_bubble_outline, badge: 0),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── QUICK ACTIONS ROW ────────────────────────────────────
  Widget _buildQuickActions() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
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
            label: 'Nạp/Rút',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DepositScreen(
                  apiBaseUrl: widget.apiBaseUrl,
                  accessToken: widget.accessToken,
                ),
              ),
            ).then((_) => _fetchUserProfile()),
          ),

          _QuickAction(
            icon: Icons.call_received, 
            label: 'Nhận tiền'
          ),
          _QuickAction(
            icon: Icons.card_giftcard, 
            label: 'Tặng Quà',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GiftCenterScreen())),
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
            color: AppTheme.card,
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
                  amount: _userProfile != null 
                    ? _formatCurrency((double.tryParse(_userProfile!['balance'].toString()) ?? 0).toInt())
                    : '...',
                  icon: Icons.account_balance_wallet,
                  iconColor: AppTheme.primary,
                ),

                _WalletDivider(),
                _WalletItem(
                  label: 'Ví Trả Sau',
                  amount: '20.000.000đ',
                  icon: Icons.credit_card,
                  iconColor: AppTheme.accent,
                ),
                _WalletDivider(),
                _WalletItem(
                  label: 'Túi Thần Tài',
                  amount: '0đ',
                  icon: Icons.savings,
                  iconColor: const Color(0xFFE8A317),
                ),
                _WalletDivider(),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CelebrateScreen())),
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
      _ServiceItem('Chuyển tiền', Icons.send, AppTheme.primary),
      _ServiceItem('Ngân hàng', Icons.account_balance, const Color(0xFF0C8DB8)),
      _ServiceItem('Hóa đơn', Icons.receipt_long, AppTheme.accent),
      _ServiceItem('Nạp ĐT', Icons.phone_android, const Color(0xFF0D96C8)),
      _ServiceItem('Data 4G/5G', Icons.signal_cellular_alt, AppTheme.primary),
      _ServiceItem('Lắc Xì', Icons.casino, const Color(0xFFE85D3A)),
      _ServiceItem('Vay Nhanh', Icons.flash_on, const Color(0xFF14B8A6)),
      _ServiceItem('Ví Trả Sau', Icons.credit_score, AppTheme.accent),
      _ServiceItem('Thanh toán', Icons.money_off, AppTheme.primary),
      _ServiceItem('Vé phim', Icons.movie_outlined, const Color(0xFFE85D3A)),
      _ServiceItem('Du lịch', Icons.flight_takeoff, AppTheme.primary),
      _ServiceItem('Thêm', Icons.grid_view, AppTheme.textMuted),
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
        decoration: const BoxDecoration(
          color: AppTheme.card,
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
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign, color: AppTheme.accent, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chào mừng bạn đến với Lucky Ly!',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tận hưởng các dịch vụ tài chính thông minh và ưu đãi hấp dẫn dành riêng cho bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
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
                  backgroundColor: AppTheme.primary,
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
                color: AppTheme.textDark,
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
                  AppTheme.primary,
                  AppTheme.accent,
                  AppTheme.primary.withValues(alpha: 0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
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
                            color: AppTheme.primary,
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
        color: AppTheme.card,
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
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppTheme.glowShadow(AppTheme.primary),
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
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
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
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
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
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 11, 
              fontWeight: FontWeight.w600, 
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
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
                  style: const TextStyle(
                    color: AppTheme.textMuted,
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
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.textLight),
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

  const _ServiceItem(this.label, this.icon, this.color);
}

class _ServiceGridTile extends StatelessWidget {
  const _ServiceGridTile({required this.service});

  final _ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return AnimatedInteractiveScale(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5), width: 0.5),
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
              style: const TextStyle(
                color: AppTheme.textDark, 
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
              color: isActive ? AppTheme.primary : AppTheme.textLight,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textLight,
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
