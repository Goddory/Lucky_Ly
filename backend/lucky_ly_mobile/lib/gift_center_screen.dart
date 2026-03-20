import 'package:flutter/material.dart';
import 'design_selection_screen.dart';
import 'money_transfer_screen.dart';
import 'app_theme.dart';

class GiftCenterScreen extends StatelessWidget {
  const GiftCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Tặng Quà', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: theme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn hình thức quà tặng',
              style: TextStyle(color: theme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn muốn gửi tặng người thân món quà gì?',
              style: TextStyle(color: theme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildOption(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'Vật phẩm',
              subtitle: 'Gửi các món quà AR hoặc bao lì xì tự thiết kế',
              color: const Color(0xFFF59E0B),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignSelectionScreen(type: 'item'))),
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              icon: Icons.payments_outlined,
              title: 'Tiền tệ',
              subtitle: 'Chuyển tiền trực tiếp vào tài khoản Lucky Ly',
              color: theme.primary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoneyTransferScreen())),
              theme: theme,
            ),
            const SizedBox(height: 16),
            _buildOption(
              context,
              icon: Icons.card_giftcard,
              title: 'Vật phẩm & Tiền',
              subtitle: 'Kết hợp cả quà tặng và tiền lì xì',
              color: const Color(0xFFE63946),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DesignSelectionScreen(type: 'both'))),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required AppTheme theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
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
                    style: TextStyle(color: theme.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: theme.textMuted, fontSize: 13),
                  ),
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
