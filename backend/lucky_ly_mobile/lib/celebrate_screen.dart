import 'package:flutter/material.dart';

class _C {
  static const primary = Color(0xFF0EA5D8);
  static const accent = Color(0xFF19C6C4);
  static const bg = Color(0xFFF2F6FA);
  static const card = Colors.white;
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
}

class CelebrateScreen extends StatelessWidget {
  const CelebrateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final holidays = [
      {'name': 'Tết Nguyên Đán', 'image': Icons.home, 'color': Colors.red}, // Using home icon for now
      {'name': 'Valentine', 'image': Icons.favorite, 'color': Colors.pink},
      {'name': 'Quốc tế Phụ nữ 8/3', 'image': Icons.woman, 'color': Colors.purple},
      {'name': 'Giỗ tổ Hùng Vương', 'image': Icons.account_balance, 'color': Colors.orange},
    ];

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Celebrate - Mẫu Lễ Hội', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _C.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn chủ đề lễ hội',
              style: TextStyle(color: _C.textDark, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: holidays.length,
                itemBuilder: (context, index) {
                  final h = holidays[index];
                  return _buildHolidayCard(
                    h['name'] as String,
                    h['image'] as IconData,
                    h['color'] as Color,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHolidayCard(String name, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              style: const TextStyle(color: _C.textDark, fontWeight: FontWeight.bold, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
