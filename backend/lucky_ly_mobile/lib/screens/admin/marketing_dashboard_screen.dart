import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
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
      body: Stack(
        children: [
          // E-commerce softer vibrant gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFECE8), // Very soft peach
                  Color(0xFFFFDAB9), // Soft peachpuff
                  Color(0xFFFFB2A0), // Mild soft coral
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Abstract floating glowing orbs for Liquid Glass aesthetics
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
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF512F).withValues(alpha: 0.4)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : RefreshIndicator(
                          color: const Color(0xFFFE512E),
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
                                      decoration: BoxDecoration(color: const Color(0xFFFE512E), borderRadius: BorderRadius.circular(2)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('TÍNH NĂNG QUẢN LÝ', style: GoogleFonts.chakraPetch(
                                      fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFFE512E), letterSpacing: 1.0,
                                    )),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildNavCard(
                                  context: context,
                                  title: 'Voucher & Flash Sale',
                                  subtitle: 'Tạo thẻ cào, mã giảm giá, Giờ vàng',
                                  icon: Icons.confirmation_number_outlined,
                                  color: Colors.orangeAccent,
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
                                  color: Colors.lightGreenAccent,
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
                                  color: Colors.cyanAccent,
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFE512E), size: 20),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign, color: Color(0xFFFE512E), size: 18),
                        const SizedBox(width: 8),
                        Text('MARKETING HUB', style: GoogleFonts.chakraPetch(
                          color: const Color(0xFFFE512E), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0,
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
                  gradient: const LinearGradient(colors: [Color(0xFFFE512E), Color(0xFFFFB88C)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: const Color(0xFFFE512E).withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 4)],
                ),
                child: const Icon(Icons.campaign_outlined, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Marketing & Khuyến mãi', style: GoogleFonts.beVietnamPro(
                      color: const Color(0xFFFE512E), fontSize: 22, fontWeight: FontWeight.w800, height: 1.2,
                    )),
                    const SizedBox(height: 6),
                    Text('Voucher · Phân cụm AI · Sinh viên', style: GoogleFonts.beVietnamPro(
                      color: const Color(0xFFFE512E).withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500,
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
          const Color(0xFFF59E0B), Icons.local_offer,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          '${_stats['totalVouchers'] ?? 0}', 'VOUCHERS',
          const Color(0xFF0EA5D8), Icons.confirmation_number,
        )),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(
          '${sv['pending'] ?? 0}', 'CHỜ DUYỆT',
          const Color(0xFF10B981), Icons.pending_actions,
        )),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color accentColor, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                  color: const Color(0xFFFE512E).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFFFE512E), size: 24),
              ),
              const SizedBox(height: 12),
              Text(value, style: GoogleFonts.chakraPetch(
                fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFFFE512E),
              )),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.robotoMono(
                fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFFE512E).withValues(alpha: 0.7), letterSpacing: 0.5,
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
    required Color color,
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0.4), Colors.white.withValues(alpha: 0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFE512E).withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: const Color(0xFFFE512E), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: GoogleFonts.beVietnamPro(
                        fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFFFE512E),
                      )),
                      const SizedBox(height: 4),
                      Text(subtitle, style: GoogleFonts.beVietnamPro(
                        fontSize: 13, color: const Color(0xFFFE512E).withValues(alpha: 0.7),
                      )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE512E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right, color: Color(0xFFFE512E), size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
