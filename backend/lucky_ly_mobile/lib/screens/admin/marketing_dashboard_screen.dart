import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app_theme.dart';
import 'voucher_management_screen.dart';
import 'student_verification_screen.dart';
import 'customer_segments_screen.dart';
import 'push_campaign_screen.dart';
import 'loyalty_membership_screen.dart';
import 'flash_sale_screen.dart';

class MarketingDashboardScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;

  const MarketingDashboardScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<MarketingDashboardScreen> createState() => _MarketingDashboardScreenState();
}

class _MarketingDashboardScreenState extends State<MarketingDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  // Khai báo bảng màu cơ bản từ Tailwind Config
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
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final res = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/promotions/stats'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background Gradient Mới
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  background,
                  surfaceContainerLow,
                  primaryContainer.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Abstract floating glowing orbs (Liquid Glass aesthetics)
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.25)),
            ),
          ),
          Positioned(
            bottom: 50, left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryContainer.withValues(alpha: 0.4)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: primary))
                      : RefreshIndicator(
                          color: primary,
                          backgroundColor: Colors.white,
                          onRefresh: _loadStats,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatsRow(),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Container(
                                      width: 4, height: 24,
                                      decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('TÍNH NĂNG QUẢN LÝ', style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 18, fontWeight: FontWeight.bold, color: primary, letterSpacing: 0.5,
                                    )),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildNavCard(
                                  context: context,
                                  title: 'Voucher & Flash Sale',
                                  subtitle: 'Tạo thẻ cào, mã giảm giá, Giờ vàng',
                                  icon: Icons.confirmation_number_outlined,
                                  screen: VoucherManagementScreen(
                                    apiBaseUrl: widget.apiBaseUrl,
                                    accessToken: widget.accessToken,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildNavCard(
                                  context: context,
                                  title: 'Membership & Sinh viên',
                                  subtitle: 'Hạng thẻ & Duyệt khuyến mãi HSSV',
                                  icon: Icons.school_outlined,
                                  screen: StudentVerificationScreen(
                                    apiBaseUrl: widget.apiBaseUrl,
                                    accessToken: widget.accessToken,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildNavCard(
                                  context: context,
                                  title: 'CRM & Khách hàng',
                                  subtitle: 'Phân tích AI & Gửi siêu thông báo',
                                  icon: Icons.hub_outlined,
                                  screen: CustomerSegmentsScreen(
                                    apiBaseUrl: widget.apiBaseUrl,
                                    accessToken: widget.accessToken,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: primary, size: 20),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.campaign, color: primary, size: 18),
                        SizedBox(width: 8),
                        Text('MARKETING HUB', style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          color: primary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, primaryContainer]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 4)],
                ),
                child: const Icon(Icons.campaign_outlined, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Marketing & Khuyến mãi', style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: primary, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2,
                    )),
                    SizedBox(height: 6),
                    Text('Voucher · Phân cụm AI · Sinh viên', style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final sv = _stats['studentVerifications'] ?? {};
    return Row(
      children: [
        Expanded(child: _buildStatCard(
          '${_stats['totalPromotions'] ?? 0}', 'PROMOTIONS',
          Icons.local_offer,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          '${_stats['totalVouchers'] ?? 0}', 'VOUCHERS',
          Icons.confirmation_number,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          '${sv['pending'] ?? 0}', 'CHỜ DUYỆT',
          Icons.pending_actions,
        )),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: onSurface.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ]
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 24, fontWeight: FontWeight.bold, color: primary,
              )),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10, fontWeight: FontWeight.w700, color: onSurfaceVariant, letterSpacing: 0.5,
              ), textAlign: TextAlign.center, maxLines: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: outlineVariant.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: onSurface.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryContainer.withValues(alpha: 0.5)),
                  ),
                  child: Icon(icon, color: primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 17, fontWeight: FontWeight.bold, color: primary,
                      )),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13, color: onSurfaceVariant,
                      )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right, color: primary, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
