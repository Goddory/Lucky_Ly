import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoyaltyMembershipScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;

  const LoyaltyMembershipScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<LoyaltyMembershipScreen> createState() => _LoyaltyMembershipScreenState();
}

class _LoyaltyMembershipScreenState extends State<LoyaltyMembershipScreen> {
  final List<Map<String, dynamic>> _tiers = [
    {'name': 'Thành viên mới', 'spend': '0đ', 'color': Colors.grey.shade400, 'users': 1520, 'benefit': 'Tích điểm 1%'},
    {'name': 'Bạc', 'spend': '1.000.000đ', 'color': Colors.blueGrey, 'users': 450, 'benefit': 'Giảm 5% mọi đơn'},
    {'name': 'Vàng', 'spend': '5.000.000đ', 'color': Colors.orangeAccent, 'users': 120, 'benefit': 'Freeship trọn đời'},
    {'name': 'Kim Cương', 'spend': '20.000.000đ', 'color': Colors.cyanAccent, 'users': 15, 'benefit': 'Giảm 15% & Quà Sinh nhật'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
          ),
          Positioned(
            bottom: -50, left: -50,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    itemCount: _tiers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (ctx, i) => _buildTierCard(_tiers[i]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
              const SizedBox(width: 8),
              Text(
                'LOYALTY & TIERS',
                style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
    final color = tier['color'] as Color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars_rounded, color: color, size: 28),
                      const SizedBox(width: 8),
                      Text(tier['name'], style: GoogleFonts.chakraPetch(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text('${tier['users']} Users', style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.savings_outlined, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text('Yêu cầu chi tiêu: ', style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.white70)),
                    Text(tier['spend'], style: GoogleFonts.chakraPetch(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text('Đặc quyền: ${tier['benefit']}', style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
