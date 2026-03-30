import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';
import 'package:lucky_ly_mobile/widgets/bounce_button.dart';
import 'providers/auth_provider.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  // Khai báo bảng màu từ Tailwind Config do user cung cấp
  static const Color primary = Color(0xFF952CB1);
  static const Color primaryContainer = Color(0xFFF1A6FF);
  static const Color secondary = Color(0xFFBE004C);
  static const Color secondaryContainer = Color(0xFFFFD9DE);
  static const Color onSurface = Color(0xFF45274B);
  static const Color onSurfaceVariant = Color(0xFF75547A);
  static const Color surfaceContainerLow = Color(0xFFFFEFFC);
  static const Color surfaceContainerHighest = Color(0xFFFDD6FF);

  bool _isLoading = true;
  bool _isStudentVerified = false;
  String? _errorMessage;
  List<dynamic> _offers = [];
  String _activeFilter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.fetchProfile();

      final response = await auth.apiClient.get('/api/promotions/available');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final promotions = data['promotions'];
        setState(() {
          _offers = promotions is List ? promotions : [];
          _isStudentVerified = data['is_student_verified'] == true;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _offers = [];
        _isLoading = false;
        _errorMessage = 'Không thể tải ưu đãi. Mã lỗi: ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _offers = [];
        _isLoading = false;
        _errorMessage = 'Có lỗi khi tải ưu đãi: $e';
      });
    }
  }

  List<dynamic> get _filteredOffers {
    if (_activeFilter == 'Tất cả') return _offers;
    if (_activeFilter == 'Người dùng thường') {
      return _offers.where((o) => (o['target_audience'] ?? '').toString() == 'All').toList();
    }
    if (_activeFilter == 'Sinh Viên') {
      return _offers.where((o) => (o['target_audience'] ?? '').toString() == 'Student').toList();
    }
    if (_activeFilter == 'Vip') {
      return _offers.where((o) => (o['target_audience'] ?? '').toString() == 'VIP').toList();
    }
    return _offers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      body: Stack(
        children: [
          // 1. Background Decorative Icons
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            right: -20,
            child: Icon(Icons.card_giftcard, size: 120, color: onSurface.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.15,
            left: -20,
            child: Icon(Icons.celebration, size: 100, color: onSurface.withValues(alpha: 0.03)),
          ),

          // 2. Main Scrollable Content
          _isLoading 
            ? Center(child: const CustomLoading(size: 80))
            : _errorMessage != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _fetchOffers,
                    child: ListView(
                      padding: const EdgeInsets.only(top: 100, bottom: 120, left: 24, right: 24),
                      children: [
                        _buildHeroSection(),
                        const SizedBox(height: 24),
                        _buildFilterChips(),
                        const SizedBox(height: 24),
                        if (_offers.isEmpty)
                          _buildEmptyState()
                        else
                          ..._filteredOffers.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: _buildDynamicCard(entry.value, entry.key),
                            );
                          }),
                        if (_offers.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _buildLoadMore(),
                        ],
                      ],
                    ),
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
                  height: MediaQuery.of(context).padding.top + 60,
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    boxShadow: [
                      BoxShadow(color: onSurface.withValues(alpha: 0.06), blurRadius: 32, offset: const Offset(0, 12))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.stars_rounded, color: primary),
                            onPressed: () {},
                          ),
                          const Text(
                            'Ưu đãi',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, color: primary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bỏ mock Bottom Nav vì HomeScreen bên ngoài đã lo phần đó
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ĐẶC QUYỀN CỦA BẠN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lễ Hội Quà Tặng\nLucky Ly',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                'Khám phá những ưu đãi độc quyền dành riêng cho thành viên.',
                style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
          ),
          Positioned(
            right: -40,
            bottom: -50,
            child: Transform.rotate(
              angle: 0.2, // ~12 degrees
              child: Icon(Icons.redeem, size: 140, color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          Positioned(
            top: -10,
            right: 0,
            child: Icon(Icons.favorite, size: 40, color: Colors.white.withValues(alpha: 0.15)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildChip('Tất cả'),
          const SizedBox(width: 12),
          _buildChip('Người dùng thường'),
          const SizedBox(width: 12),
          _buildChip('Sinh Viên'),
          const SizedBox(width: 12),
          _buildChip('Vip'),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final isActive = _activeFilter == label;
    return BounceButton(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? secondary : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive ? [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))] : [],
          border: isActive ? null : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicCard(dynamic o, int index) {
    final promo = o is Map<String, dynamic> ? o : <String, dynamic>{};
    final discountType = (promo['discount_type'] ?? '').toString().toLowerCase();
    final discountValueRaw = promo['discount_value'];
    final discountValue = num.tryParse(discountValueRaw?.toString() ?? '0') ?? 0;
    final isPercent = discountType == 'percent';
    final targetAudience = (promo['target_audience'] ?? 'All').toString();
    final voucherCode = (promo['sample_voucher_code'] ?? 'LUCKY-WELCOME').toString();

    String title;
    if (isPercent) {
      title = 'Giảm ${discountValue.toStringAsFixed(discountValue % 1 == 0 ? 0 : 2)}%';
    } else {
      title = 'Giảm ${(discountValue / 1000).toStringAsFixed(discountValue % 1000 == 0 ? 0 : 1)}K';
    }

    final expiresAt = promo['expires_at']?.toString() ?? '';
    final subtitle = (promo['name'] ?? 'Ưu đãi Lễ Hội').toString();

    // Alternate styles based on targetAudience or index
    Color bgColor = surfaceContainerLow;
    Color badgeColor = Colors.white;
    Color badgeTextColor = primary;
    IconData badgeIcon = Icons.person;
    String badgeText = 'Người dùng thường';
    double imageRotate = 0.05;
    String imageUrl = 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=200';
    Color codeColor = primary;
    Color buttonColor = primaryContainer;
    Color buttonIconColor = onSurface;

    if (targetAudience == 'Student') {
      bgColor = surfaceContainerHighest;
      badgeColor = secondaryContainer;
      badgeTextColor = secondary;
      badgeIcon = Icons.school;
      badgeText = 'Sinh viên';
      imageRotate = -0.05;
      imageUrl = 'https://images.unsplash.com/photo-1607344645866-009c320b63e0?w=200';
      codeColor = secondary;
      buttonColor = secondaryContainer;
      buttonIconColor = secondary;
    } else if (targetAudience == 'VIP') {
      bgColor = const Color(0xFFFFF7ED); 
      badgeColor = const Color(0xFFFFEDD5);
      badgeTextColor = const Color(0xFFC2410C);
      badgeIcon = Icons.star;
      badgeText = 'Thành viên VIP';
      imageRotate = 0.08;
      imageUrl = 'https://images.unsplash.com/photo-1511556820780-d912e42b4980?w=200';
      codeColor = const Color(0xFFC2410C);
      buttonColor = const Color(0xFFFFEDD5);
      buttonIconColor = const Color(0xFFC2410C);
    } else if (index % 2 != 0) {
      bgColor = surfaceContainerHighest;
      badgeColor = secondaryContainer;
      badgeTextColor = secondary;
      imageUrl = 'https://images.unsplash.com/photo-1607344645866-009c320b63e0?w=200';
      codeColor = secondary;
      buttonColor = secondaryContainer;
      buttonIconColor = secondary;
      imageRotate = -0.05;
    }

    String formattedFooter = 'Không thời hạn';
    if (expiresAt.isNotEmpty) {
      var parts = expiresAt.split('T');
      formattedFooter = 'Hết hạn: ${parts[0]}';
    }

    return _buildBaseCard(
      bgColor: bgColor,
      badgeColor: badgeColor,
      badgeTextColor: badgeTextColor,
      badgeIcon: badgeIcon,
      badgeText: badgeText,
      title: title,
      subtitle: subtitle,
      imageRotate: imageRotate,
      imageUrl: imageUrl,
      code: voucherCode,
      codeColor: codeColor,
      buttonColor: buttonColor,
      buttonIconColor: buttonIconColor,
      footerIcon: Icons.calendar_today,
      footerText: formattedFooter,
      actionText: 'Dùng ngay',
    );
  }

  Widget _buildBaseCard({
    required Color bgColor, required Color badgeColor, required Color badgeTextColor,
    required IconData badgeIcon, required String badgeText,
    required String title, required String subtitle, required double imageRotate,
    required String imageUrl, required String code, required Color codeColor,
    required Color buttonColor, required Color buttonIconColor,
    required IconData footerIcon, required String footerText, required String actionText,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))]),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 14, color: badgeTextColor),
                          const SizedBox(width: 6),
                          Text(badgeText.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: badgeTextColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: onSurface)),
                    Text(subtitle, style: const TextStyle(fontSize: 14, color: onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Transform.rotate(
                angle: imageRotate,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 80, height: 80, color: Colors.grey.shade200)),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCCA5D0).withValues(alpha: 0.2))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MÃ ƯU ĐÃI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(code.isNotEmpty ? code : 'Không cần mã', style: TextStyle(fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.w900, color: codeColor)),
                    ],
                  ),
                ),
                if (code.isNotEmpty)
                  BounceButton(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã copy mã: $code')));
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: buttonColor, shape: BoxShape.circle),
                      child: Icon(Icons.content_copy, color: buttonIconColor, size: 20),
                    ),
                  )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(footerIcon, size: 14, color: onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(footerText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant)),
                ],
              ),
              BounceButton(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đang dùng: $code')));
                },
                child: Text(actionText.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: codeColor)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: onSurfaceVariant, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Không tải được dữ liệu ưu đãi',
              style: TextStyle(color: onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOffers, 
              style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
              child: const Text('Thử lại'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, color: onSurface.withValues(alpha: 0.2), size: 64),
          const SizedBox(height: 24),
          Text('Hiện chưa có ưu đãi nào', style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
          if (!_isStudentVerified) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tài khoản chưa xác minh sinh viên nên chỉ hiển thị ưu đãi dành cho người dùng thường.',
                style: TextStyle(color: onSurfaceVariant, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return BounceButton(
      onTap: _fetchOffers,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: surfaceContainerHighest, shape: BoxShape.circle),
            child: const Icon(Icons.refresh, color: onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          const Text('LÀM MỚI ƯU ĐÃI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: onSurfaceVariant)),
        ],
      ),
    );
  }
}
