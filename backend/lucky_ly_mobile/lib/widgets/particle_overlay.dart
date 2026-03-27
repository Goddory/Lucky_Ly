import 'dart:math';
import 'package:flutter/material.dart';

class ParticleOverlay extends StatefulWidget {
  final bool isPlaying;
  final String theme;

  const ParticleOverlay({
    super.key,
    required this.isPlaying,
    required this.theme,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingParticle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didUpdateWidget(covariant ParticleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _particles = _generateParticles();
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  List<_FloatingParticle> _generateParticles() {
    final rng = Random();
    return List.generate(20, (i) => _FloatingParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 12 + rng.nextDouble() * 16,
      speed: 0.3 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * 2 * pi,
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
        if (!widget.isPlaying) return const SizedBox.shrink();
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _controller.value,
            theme: widget.theme,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;
  final String theme;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.phase / (2 * pi)) % 1.0;
      final x = p.x * size.width + sin(t * 2 * pi + p.phase) * 30;
      final y = (1 - t * p.speed) * size.height * 1.2;
      final alpha = (sin(t * pi) * 0.8).clamp(0.0, 0.8);

      if (theme == 'tet') {
        _drawFireworkSpark(canvas, Offset(x, y), p.size, alpha);
      } else {
        _drawHeart(canvas, Offset(x, y), p.size, alpha);
      }
    }
  }

  void _drawFireworkSpark(Canvas canvas, Offset center, double size, double alpha) {
    final paint = Paint()
      ..color = Color.lerp(
        const Color(0xFFFFD700),
        const Color(0xFFFF4500),
        (center.dx % 100) / 100,
      )!.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    // Star burst
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72) + 36 - 90) * pi / 180;
      final outerR = size * 0.5;
      final innerR = size * 0.2;

      if (i == 0) {
        path.moveTo(center.dx + cos(angle) * outerR, center.dy + sin(angle) * outerR);
      } else {
        path.lineTo(center.dx + cos(angle) * outerR, center.dy + sin(angle) * outerR);
      }
      path.lineTo(center.dx + cos(innerAngle) * innerR, center.dy + sin(innerAngle) * innerR);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, Offset center, double size, double alpha) {
    final paint = Paint()
      ..color = Color.lerp(
        const Color(0xFFFF69B4),
        const Color(0xFFFF1493),
        (center.dx % 100) / 100,
      )!.withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final s = size * 0.35;
    final path = Path();
    path.moveTo(center.dx, center.dy + s * 0.6);
    path.cubicTo(
      center.dx - s, center.dy - s * 0.2,
      center.dx - s * 0.5, center.dy - s,
      center.dx, center.dy - s * 0.4,
    );
    path.cubicTo(
      center.dx + s * 0.5, center.dy - s,
      center.dx + s, center.dy - s * 0.2,
      center.dx, center.dy + s * 0.6,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

class _FloatingParticle {
  final double x, y, size, speed, phase;

  _FloatingParticle({
    required this.x, required this.y,
    required this.size, required this.speed, required this.phase,
  });
}
