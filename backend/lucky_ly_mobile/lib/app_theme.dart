import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Premium Deep Teal & Refined Gold
  static const primary = Color(0xFF005A64); // Deeper, more elite Teal
  static const primaryLight = Color(0xFF008D9A);
  static const accent = Color(0xFFB38D1D); // Refined Dark Gold
  static const bg = Color(0xFFF4F7F8); // Slightly cooler background
  static const card = Colors.white;
  static const divider = Color(0xFFE2E8F0);
  
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF475569);
  static const textLight = Color(0xFF94A3B8);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF008D9A), Color(0xFF005A64)],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4AF37), Color(0xFFB38D1D)],
  );

  // Shadows
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  // Glassmorphism Decoration
  static BoxDecoration glass({double opacity = 0.1, double blur = 10}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
    );
  }
}

// Widget for interactive scaling effect
class AnimatedInteractiveScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AnimatedInteractiveScale({super.key, required this.child, this.onTap});

  @override
  State<AnimatedInteractiveScale> createState() => _AnimatedInteractiveScaleState();
}

class _AnimatedInteractiveScaleState extends State<AnimatedInteractiveScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
