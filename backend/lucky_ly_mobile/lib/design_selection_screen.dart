import 'package:flutter/material.dart';
import 'mobile_studio_screen.dart';

class _C {
  static const primary = Color(0xFF0EA5D8);
  static const accent = Color(0xFF19C6C4);
  static const bg = Color(0xFFF2F6FA);
  static const card = Colors.white;
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
}

class DesignSelectionScreen extends StatelessWidget {
  const DesignSelectionScreen({super.key, required this.type});

  final String type; // 'item' or 'both'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Chọn thiết kế', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _C.primary,
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
              style: const TextStyle(color: _C.textDark, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildOption(
              context,
              icon: Icons.add_circle_outline,
              title: 'Tạo thiết kế mới',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileStudioScreen())),
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.auto_awesome_mosaic_outlined,
              title: 'Sử dụng mẫu có sẵn',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.bookmark_outline,
              title: 'Mẫu đã lưu',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              icon: Icons.edit_note,
              title: 'Mẫu đang chỉnh sửa',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _C.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: _C.textDark, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.keyboard_arrow_right, color: _C.textMuted),
          ],
        ),
      ),
    );
  }
}
