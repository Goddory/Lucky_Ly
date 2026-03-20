import 'package:flutter/material.dart';

class _C {
  static const primary = Color(0xFF0EA5D8);
  static const bg = Color(0xFFF2F6FA);
  static const textMuted = Color(0xFF64748B);
}

class MobileStudioScreen extends StatelessWidget {
  const MobileStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text(
          'Xưởng Studio 3D',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _C.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // 3D Placeholder Area
          Center(
            child: Container(
              width: 250,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.view_in_ar, color: Colors.white, size: 80),
                    SizedBox(height: 20),
                    Text(
                      'Môi trường 3D\n(Sắp ra mắt)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Toolbars
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _C.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StudioTool(icon: Icons.color_lens, label: 'Màu sắc'),
                  _StudioTool(icon: Icons.wallpaper, label: 'Họa tiết'),
                  _StudioTool(icon: Icons.auto_awesome, label: 'Nhãn dán'),
                  _StudioTool(icon: Icons.title, label: 'Văn bản'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioTool extends StatelessWidget {
  const _StudioTool({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _C.primary),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: _C.textMuted)),
      ],
    );
  }
}
