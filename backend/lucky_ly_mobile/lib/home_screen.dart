import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

// Màu sắc chủ đạo teal/cyan giống giao diện auth
class _C {
  static const primary = Color(0xFF0EA5D8);
  static const accent = Color(0xFF19C6C4);
  static const bg = Color(0xFFF2F6FA);
  static const card = Colors.white;
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const textLight = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5D8), Color(0xFF19C6C4)],
  );
}

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
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: _currentTab == 4
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
                  SliverToBoxAdapter(child: _buildFinancialCenter()),
                  SliverToBoxAdapter(child: _buildNotificationCard()),
                  SliverToBoxAdapter(child: _buildServiceGrid()),
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
      expandedHeight: 110,
      floating: true,
      snap: true,
      pinned: false,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: _C.gradient),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                    _HeaderIconBtn(icon: Icons.notifications_outlined, badge: 3),
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
      decoration: const BoxDecoration(gradient: _C.gradient),
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _QuickAction(icon: Icons.swap_horiz, label: 'Nạp/Rút'),
          _QuickAction(icon: Icons.call_received, label: 'Nhận tiền'),
          _QuickAction(icon: Icons.camera_alt_outlined, label: 'Máy ảnh'),
          _QuickAction(icon: Icons.widgets_outlined, label: 'Tiện ích'),
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
            color: _C.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _C.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Ví số dư
              Row(
                children: [
                  _WalletItem(
                    label: 'Ví Lucky Ly',
                    amount: '4.901đ',
                    icon: Icons.account_balance_wallet,
                    iconColor: _C.primary,
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 30, color: _C.divider),
                  const SizedBox(width: 12),
                  _WalletItem(
                    label: 'Ví Trả Sau',
                    amount: '18.951.000đ',
                    icon: Icons.credit_card,
                    iconColor: _C.accent,
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 30, color: _C.divider),
                  const SizedBox(width: 12),
                  _WalletItem(
                    label: 'Túi Thần Tài',
                    amount: '0đ',
                    icon: Icons.savings,
                    iconColor: const Color(0xFFE8A317),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FINANCIAL CENTER ─────────────────────────────────────
  Widget _buildFinancialCenter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _C.primary.withValues(alpha: 0.06),
              _C.accent.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.primary.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: _C.gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Trung Tâm Tài Chính của bạn',
                style: TextStyle(
                  color: _C.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: _C.primary),
          ],
        ),
      ),
    );
  }

  // ─── NOTIFICATION CARD ────────────────────────────────────
  Widget _buildNotificationCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _C.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Thông báo mới',
                      style: TextStyle(color: _C.accent, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chào mừng bạn đến với Lucky Ly!',
                    style: TextStyle(color: _C.textDark, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tận hưởng các dịch vụ tài chính thông minh.',
                    style: TextStyle(color: _C.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: _C.gradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.campaign, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: _C.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Xem ngay',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SERVICE GRID ─────────────────────────────────────────
  Widget _buildServiceGrid() {
    final services = [
      _ServiceItem('Chuyển tiền', Icons.send, _C.primary),
      _ServiceItem('Chuyển tiền\nNgân hàng', Icons.account_balance, const Color(0xFF0C8DB8)),
      _ServiceItem('Thanh toán\nhóa đơn', Icons.receipt_long, _C.accent),
      _ServiceItem('Nạp tiền\nđiện thoại', Icons.phone_android, const Color(0xFF0D96C8)),
      _ServiceItem('Data 4G/5G', Icons.signal_cellular_alt, _C.primary),
      _ServiceItem('Lắc Xì', Icons.casino, const Color(0xFFE85D3A)),
      _ServiceItem('Vay Nhanh', Icons.flash_on, const Color(0xFF14B8A6)),
      _ServiceItem('Ví Trả Sau', Icons.credit_score, _C.accent),
      _ServiceItem('Thanh toán\nkhoản vay', Icons.money_off, const Color(0xFF0EA5D8)),
      _ServiceItem('Mua vé xem\nphim', Icons.movie_outlined, const Color(0xFFE85D3A)),
      _ServiceItem('Du lịch -\nĐi lại', Icons.flight_takeoff, _C.primary),
      _ServiceItem('Xem thêm\ndịch vụ', Icons.grid_view, _C.textMuted),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 4,
          childAspectRatio: 0.85,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final s = services[index];
          return _ServiceGridTile(service: s);
        },
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
          const Text(
            'Sự kiện đang diễn ra',
            style: TextStyle(
              color: _C.textDark,
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
                  _C.primary,
                  _C.accent,
                  _C.primary.withValues(alpha: 0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withValues(alpha: 0.3),
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
                        child: const Text(
                          'Nhận ngay',
                          style: TextStyle(
                            color: _C.primary,
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
        color: _C.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
        gradient: _C.gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _C.primary.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
  const _HeaderIconBtn({required this.icon, this.badge = 0});

  final IconData icon;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
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
    return Expanded(
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
                  style: TextStyle(color: _C.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
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
                  style: const TextStyle(color: _C.textDark, fontSize: 14, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 16, color: _C.textLight),
            ],
          ),
        ],
      ),
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
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: service.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(service.icon, color: service.color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            service.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _C.textDark, fontSize: 11, fontWeight: FontWeight.w600, height: 1.25),
          ),
        ],
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
              color: isActive ? _C.primary : _C.textLight,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? _C.primary : _C.textLight,
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
