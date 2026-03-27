import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'screens/gifts/themed_gift_builder_screen.dart';

class CelebrateScreen extends StatelessWidget {
  const CelebrateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final holidays = [
      {'name': 'Tết Nguyên Đán', 'image': Icons.home, 'color': Colors.red},
      {'name': 'Valentine', 'image': Icons.favorite, 'color': Colors.pink},
      {'name': 'Quốc tế Phụ nữ 8/3', 'image': Icons.woman, 'color': Colors.purple},
      {'name': 'Giỗ tổ Hùng Vương', 'image': Icons.account_balance, 'color': Colors.orange},
      {'name': 'Giải phóng miền Nam 30/4', 'image': Icons.flag, 'color': Colors.redAccent},
      {'name': 'Quốc tế Lao động 1/5', 'image': Icons.work, 'color': Colors.blue},
    ];

    return Scaffold(
      backgroundColor: AppTheme.of(context).bg,
      appBar: AppBar(
        title: const Text('Chào mừng lễ hội', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppTheme.of(context).primaryGradient)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'Chọn chủ đề lễ hội',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.of(context).textDark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: holidays.length,
              itemBuilder: (context, index) {
                final h = holidays[index];
                return _buildHolidayCard(
                  h['name'] as String,
                  h['image'] as IconData,
                  h['color'] as Color,
                  context,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayCard(String name, IconData icon, Color color, BuildContext context) {
    return AnimatedInteractiveScale(
      onTap: () {
        String? giftTheme;
        if (name.contains('Tết')) giftTheme = 'tet';
        if (name.contains('Valentine')) giftTheme = 'valentine';
        if (giftTheme != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ThemedGiftBuilderScreen(theme: giftTheme!),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.of(context).card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: TextStyle(
                  color: AppTheme.of(context).textDark, 
                  fontWeight: FontWeight.w700, 
                  fontSize: 11,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
