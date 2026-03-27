import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()..color = p.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));
      final x = p.x * size.width + sin(progress * p.spin * 2 * pi) * 30;
      final y = p.y * size.height + progress * size.height * p.speed;
      final rotation = progress * p.spin * 2 * pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}

class ConfettiOverlay extends StatefulWidget {
  final bool isPlaying;
  final String theme;

  const ConfettiOverlay({
    super.key,
    required this.isPlaying,
    required this.theme,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _particles = _generateParticles();
      _controller.forward(from: 0);
    }
  }

  List<_Particle> _generateParticles() {
    final rng = Random();
    final colors = widget.theme == 'tet'
        ? [
            const Color(0xFFFF0000), const Color(0xFFFFD700), const Color(0xFFFF6B00),
            const Color(0xFFFF1493), const Color(0xFFFFFF00),
          ]
        : [
            const Color(0xFFFF69B4), const Color(0xFFFF1493), const Color(0xFFFFB6C1),
            const Color(0xFFC71585), const Color(0xFFFF6EB4),
          ];

    return List.generate(60, (i) => _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble() * -0.3 - 0.1,
      speed: 0.5 + rng.nextDouble() * 0.8,
      spin: 1 + rng.nextDouble() * 4,
      color: colors[rng.nextInt(colors.length)],
      w: 4 + rng.nextDouble() * 8,
      h: 3 + rng.nextDouble() * 6,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (!_controller.isAnimating && _controller.value == 0) {
          return const SizedBox.shrink();
        }
        return CustomPaint(
          painter: ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double x, y, speed, spin, w, h;
  final Color color;

  _Particle({
    required this.x, required this.y,
    required this.speed, required this.spin,
    required this.color,
    required this.w, required this.h,
  });
}
