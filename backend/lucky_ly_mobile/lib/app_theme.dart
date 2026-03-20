import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

class AppTheme {
  // Theme Properties
  final Color primary;
  final Color primaryLight;
// ... (Skipping to getTheme and of)

  // Helper method to get the active theme
  static AppTheme getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.tet:
        return tetTheme;
      case AppThemeType.valentine:
        return valentineTheme;
      default:
        return defaultTheme;
    }
  }

  static AppTheme of(BuildContext context) {
    final type = Provider.of<ThemeProvider>(context).currentTheme;
    return getTheme(type);
  }
  final Color accent;
  final Color bg;
  final Color card = Colors.white;
  final Color divider = const Color(0xFFE2E8F0);
  
  final Color textDark = const Color(0xFF0F172A);
  final Color textMuted = const Color(0xFF475569);
  final Color textLight = const Color(0xFF94A3B8);

  final LinearGradient primaryGradient;
  final LinearGradient accentGradient;

  AppTheme({
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.bg,
    required this.primaryGradient,
    required this.accentGradient,
  });

  static AppTheme defaultTheme = AppTheme(
    primary: const Color(0xFF005A64), // Deeper, more elite Teal
    primaryLight: const Color(0xFF008D9A),
    accent: const Color(0xFFB38D1D), // Refined Dark Gold
    bg: const Color(0xFFF4F7F8), // Slightly cooler background
    primaryGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF008D9A), Color(0xFF005A64)],
    ),
    accentGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD4AF37), Color(0xFFB38D1D)],
    ),
  );

  static AppTheme tetTheme = AppTheme(
    primary: const Color(0xFFc0392b),
    primaryLight: const Color(0xFFe74c3c),
    accent: const Color(0xFFf39c12),
    bg: const Color(0xFFFFF7F5),
    primaryGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFe74c3c), Color(0xFFc0392b)],
    ),
    accentGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFf1c40f), Color(0xFFf39c12)],
    ),
  );

  static AppTheme valentineTheme = AppTheme(
    primary: const Color(0xFF8e44ad),
    primaryLight: const Color(0xFF9b59b6),
    accent: const Color(0xFFe84393),
    bg: const Color(0xFFFCF3F9),
    primaryGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF9b59b6), Color(0xFF8e44ad)],
    ),
    accentGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFfd79a8), Color(0xFFe84393)],
    ),
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
