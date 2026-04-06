import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'screens/gifts/themed_gift_builder_screen.dart';

class CelebrateScreen extends StatelessWidget {
  const CelebrateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final holidays = [
      {'name': 'Tết Nguyên Đán', 'asset': 'assets/ảnh icon Luckyly/Lucky_Ly/Chào mừng lễ hội/tết nguyên đán.png', 'color': Colors.red},
      {'name': 'Valentine', 'asset': 'assets/ảnh icon Luckyly/Lucky_Ly/Chào mừng lễ hội/valentine.png', 'color': Colors.pink},
      {'name': 'Quốc tế Phụ nữ 8/3', 'asset': 'assets/ảnh icon Luckyly/Lucky_Ly/Chào mừng lễ hội/quốc tế phụ nữ.png', 'color': Colors.purple},
      {'name': 'Giỗ tổ Hùng Vương', 'image': Icons.account_balance, 'color': Colors.orange},
      {'name': 'Giải phóng miền Nam 30/4', 'asset': 'assets/ảnh icon Luckyly/Lucky_Ly/Chào mừng lễ hội/giải phóng miền nam.png', 'color': Colors.redAccent},
      {'name': 'Quốc tế Lao động 1/5', 'asset': 'assets/ảnh icon Luckyly/Lucky_Ly/Chào mừng lễ hội/quốc tế lao động.png', 'color': Colors.blue},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.8),
              elevation: 0.5,
              shadowColor: const Color(0xFF45274b).withOpacity(0.2),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF7e22ce)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Lễ Hội',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Color(0xFF581c87),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 100, 20, 16),
            child: Text(
              'Chọn chủ đề lễ hội',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF45274b),
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
                  h['image'] as IconData?,
                  h['asset'] as String?,
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

  Widget _buildHolidayCard(String name, IconData? icon, String? assetPath, Color color, BuildContext context) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: assetPath != null 
                  ? Image.asset(assetPath, width: 32, height: 32, fit: BoxFit.contain)
                  : Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Color(0xFF45274b), 
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
