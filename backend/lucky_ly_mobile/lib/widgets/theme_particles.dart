import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeParticles extends StatefulWidget {
  // Lớp phủ hiệu ứng hạt theo theme, dùng để làm nền động cho màn hình chính.
  const ThemeParticles({super.key});

  @override
  State<ThemeParticles> createState() => _ThemeParticlesState();
}

class _ThemeParticlesState extends State<ThemeParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    // Animation chạy liên tục để các hạt di chuyển như một lớp nền trang trí.
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _controller.addListener(() {
      if (!mounted) return;
      // Cập nhật vị trí từng hạt theo thời gian để tạo cảm giác trôi nhẹ.
      setState(() {
        for (var p in _particles) {
          p.y += p.speed;
          p.x += sin(p.y * 0.01) * 0.5;
          // Pha dao động giúp icon/emoji thay đổi nhịp lắc theo frame.
          p.phase += 0.05;
          if (p.y > MediaQuery.of(context).size.height) {
            // Khi hạt ra khỏi màn hình, đưa nó lên lại từ phía trên để loop vô hạn.
            p.y = -50 - _rnd.nextDouble() * 50;
            p.x = _rnd.nextDouble() * MediaQuery.of(context).size.width;
          }
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Khởi tạo danh sách hạt một lần dựa trên kích thước màn hình hiện tại.
    if (_particles.isEmpty) {
      final width = MediaQuery.of(context).size.width;
      // Tăng số lượng hạt để nền trông dày và sinh động hơn.
      for (int i = 0; i < 20; i++) {
        _particles.add(_Particle(
          x: _rnd.nextDouble() * width,
          y: _rnd.nextDouble() * MediaQuery.of(context).size.height,
          size: 15 + _rnd.nextDouble() * 20,
          speed: 1 + _rnd.nextDouble() * 2,
          type: _rnd.nextInt(4),
          phase: _rnd.nextDouble() * pi * 2,
        ));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lấy theme hiện tại để quyết định có hiển thị hạt hay không và hiển thị kiểu nào.
    final themeType = Provider.of<ThemeProvider>(context).currentTheme;
    if (themeType == AppThemeType.defaultTheme) {
      // Theme mặc định thì tắt hiệu ứng nền để giao diện sạch và ít nhiễu.
      return const SizedBox.shrink();
    }

    final isValentine = themeType == AppThemeType.valentine;

    // IgnorePointer để lớp hiệu ứng không chặn thao tác chạm lên UI bên dưới.
    return IgnorePointer(
      child: Stack(
        children: _particles.map((p) {
          Widget childWidget;
          
          if (isValentine) {
            // Theme Valentine dùng asset riêng thay vì icon đơn giản.
            String assetPath;
            if (p.type == 0) {
              assetPath = 'assets/images/ValentineTheme/Lich1402.png';
            } else if (p.type == 1) {
              assetPath = 'assets/images/ValentineTheme/Cungtentinhyeu.png';
            } else {
              assetPath = 'assets/images/ValentineTheme/Chocobar.png';
            }
            Widget imgWidget = Image.asset(assetPath, width: p.size * 2, height: p.size * 2, fit: BoxFit.contain);
            
            if (p.type == 1) {
              // Một số loại hạt được scale nhịp nhàng để tạo cảm giác sống động.
              final scale = 1.0 + sin(p.phase) * 0.2;
              childWidget = Transform.scale(scale: scale, child: imgWidget);
            } else if (p.type == 2) {
              // Một số loại hạt xoay nhẹ theo nhịp pha.
              final rotation = sin(p.phase) * 0.2;
              childWidget = Transform.rotate(angle: rotation, child: imgWidget);
            } else {
              childWidget = imgWidget;
            }
          } else {
            // Theme Tết và các dịp lễ khác dùng emoji/icon nhẹ để tiết kiệm tài nguyên.
            if (p.type == 0) {
              childWidget = Icon(Icons.local_florist, color: Colors.amber.withValues(alpha: 0.4), size: p.size);
            } else if (p.type == 1) {
              childWidget = Icon(Icons.local_florist, color: Colors.pinkAccent.withValues(alpha: 0.4), size: p.size);
            } else if (p.type == 2) {
              childWidget = Text('🐉', style: TextStyle(fontSize: p.size * 1.2));
            } else {
              childWidget = Text('🐎', style: TextStyle(fontSize: p.size * 1.2));
            }
          }

          return Positioned(
            left: p.x,
            top: p.y,
            child: childWidget,
          );
        }).toList(),
      ),
    );
  }
}

class _Particle {
  // Mô tả một hạt hiệu ứng: vị trí, kích thước, tốc độ và loại render.
  double x;
  double y;
  double size;
  double speed;
  int type;
  double phase;
  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.type,
    required this.phase,
  });
}
