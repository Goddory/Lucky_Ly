import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Quản lý Cửa hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: theme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => store.fetchOverview(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tổng quan',
                style: TextStyle(color: theme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Tổng doanh thu',
                      value: overview?['totalRevenue']?.toString() ?? '0',
                      icon: Icons.payments_outlined,
                      color: Colors.green,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Sản phẩm',
                      value: overview?['totalItems']?.toString() ?? '0',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.blue,
                      theme: theme,
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
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.orange,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Combo gợi ý',
                      value: overview?['totalCombos']?.toString() ?? '0',
                      icon: Icons.auto_awesome_outlined,
                      color: Colors.purple,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Tính năng',
                style: TextStyle(color: theme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _MenuTile(
                title: 'Kho vật phẩm (Inventory)',
                subtitle: 'Quản lý, thêm/sửa/xóa vật phẩm ảo',
                icon: Icons.inventory,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _MenuTile(
                title: 'Doanh thu & Biểu đồ',
                subtitle: 'Thống kê chi tiết doanh thu bán hàng',
                icon: Icons.bar_chart,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueScreen())),
                theme: theme,
              ),
              const SizedBox(height: 12),
              _MenuTile(
                title: 'Gợi ý Combo (Apriori)',
                subtitle: 'Khám phá các liên kết quà tặng thông minh',
                icon: Icons.psychology_outlined,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComboSuggestionScreen())),
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AppTheme theme;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: theme.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: theme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final AppTheme theme;

  const _MenuTile({required this.title, required this.subtitle, required this.icon, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: theme.textDark, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: theme.textMuted, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.textMuted),
          ],
        ),
      ),
    );
  }
}
