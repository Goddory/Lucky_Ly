import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../../providers/store_provider.dart';
import '../../app_theme.dart';
import 'inventory_screen.dart';
import 'revenue_screen.dart';
import 'combo_suggestion_screen.dart';
class StoreDashboardScreen extends StatefulWidget {
  const StoreDashboardScreen({super.key});

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final store = context.watch<StoreProvider>();
    final overview = store.overview;

    // Cute E-com style overrides
    final softPinkBg = const Color(0xFFFFF0F3);
    final accentPink = const Color(0xFFFF758F);

    return Scaffold(
      backgroundColor: softPinkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: softPinkBg,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Quản lý Cửa hàng',
                style: GoogleFonts.comfortaa(
                  color: accentPink,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            iconTheme: IconThemeData(color: accentPink),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Tổng quan',
                    style: GoogleFonts.comfortaa(
                      color: accentPink.withValues(alpha: 0.8),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatGrid(overview, accentPink),
                  const SizedBox(height: 32),
                  Text(
                    'Tính năng',
                    style: GoogleFonts.comfortaa(
                      color: accentPink.withValues(alpha: 0.8),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MenuTile(
                    title: 'Kho vật phẩm',
                    subtitle: 'Inventory Management',
                    icon: Icons.inventory_2_rounded,
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                  ),
                  const SizedBox(height: 12),
                  _MenuTile(
                    title: 'Doanh thu & Biểu đồ',
                    subtitle: 'Revenue Analytics',
                    icon: Icons.bar_chart_rounded,
                    color: Colors.greenAccent.shade700,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueScreen())),
                  ),
                  const SizedBox(height: 12),
                  _MenuTile(
                    title: 'Gợi ý Combo',
                    subtitle: 'AI Smart Suggestions',
                    icon: Icons.auto_awesome_rounded,
                    color: Colors.purpleAccent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComboSuggestionScreen())),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(Map<String, dynamic>? overview, Color accent) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Doanh thu',
                value: overview?['totalRevenue']?.toString() ?? '0',
                icon: Icons.payments_rounded,
                color: Colors.greenAccent.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Sản phẩm',
                value: overview?['totalItems']?.toString() ?? '0',
                icon: Icons.inventory_rounded,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Đơn hàng',
                value: overview?['totalOrders']?.toString() ?? '0',
                icon: Icons.shopping_cart_rounded,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Combo đề xuất',
                value: overview?['totalCombos']?.toString() ?? '0',
                icon: Icons.stars_rounded,
                color: Colors.purpleAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.comfortaa(
              color: const Color(0xFF2B2D42),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.beVietnamPro(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.comfortaa(
                      color: const Color(0xFF2B2D42),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 18),
          ],
        ),
      ),
    );
  }
}
