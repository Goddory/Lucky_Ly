import 'package:flutter/material.dart';
import 'mobile_studio_screen.dart';
import 'app_theme.dart';
import 'screens/store/store_dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DesignSelectionScreen extends StatelessWidget {
  const DesignSelectionScreen({super.key, required this.type});

  final String type; // 'item' or 'both'

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Chọn thiết kế', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              type == 'both' ? 'Gửi vật phẩm kèm tiền' : 'Gửi vật phẩm',
              style: TextStyle(color: theme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildOption(
              context,
              icon: Icons.add_circle_outline,
              title: 'Tạo thiết kế mới',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileStudioScreen())),
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.auto_awesome_mosaic_outlined,
              title: 'Sử dụng mẫu có sẵn',
              onTap: () {},
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.bookmark_outline,
              title: 'Mẫu đã lưu',
              onTap: () {},
              theme: theme,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.edit_note,
              title: 'Mẫu đang chỉnh sửa',
              onTap: () {},
              theme: theme,
            ),
            const SizedBox(height: 24),
            // Phân quyền: Chỉ creator/admin mới thấy dashboard
            Builder(
              builder: (ctx) {
                final userRole = ctx.read<AuthProvider>().userData?['role']?.toString().toLowerCase();
                if (userRole == 'store_creator' || userRole == 'admin' || userRole == 'marketing_admin') {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dành cho Nhà sáng tạo',
                        style: TextStyle(color: theme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildOption(
                        context,
                        icon: Icons.storefront_outlined,
                        title: 'Quản lý Cửa hàng (Dashboard)',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreDashboardScreen())),
                        theme: theme,
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required AppTheme theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: theme.textDark, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.keyboard_arrow_right, color: theme.textMuted),
          ],
        ),
      ),
    );
  }
}
