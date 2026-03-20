import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeParticles extends StatefulWidget {
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
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _controller.addListener(() {
      if (!mounted) return;
      setState(() {
        for (var p in _particles) {
          p.y += p.speed;
          p.x += sin(p.y * 0.01) * 0.5;
          p.phase += 0.05; // For dynamic animation
          if (p.y > MediaQuery.of(context).size.height) {
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
    if (_particles.isEmpty) {
      final width = MediaQuery.of(context).size.width;
      // Increased particle count slightly for more variety
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
    final themeType = Provider.of<ThemeProvider>(context).currentTheme;
    if (themeType == AppThemeType.defaultTheme) {
      return const SizedBox.shrink(); // No particles for default
    }

    final isValentine = themeType == AppThemeType.valentine;

    return IgnorePointer(
      child: Stack(
        children: _particles.map((p) {
          Widget childWidget;
          
          if (isValentine) {
            if (p.type <= 1) {
              // Keep the current falling heart
              childWidget = Icon(Icons.favorite, color: Colors.pinkAccent.withValues(alpha: 0.3), size: p.size);
            } else if (p.type == 2) {
              // Animated pulsing heart
              final scale = 1.0 + sin(p.phase) * 0.2;
              childWidget = Transform.scale(
                scale: scale,
                child: Text('💖', style: TextStyle(fontSize: p.size)),
              );
            } else {
              // Rotating stacked hearts
              final rotation = sin(p.phase) * 0.2;
              childWidget = Transform.rotate(
                angle: rotation,
                child: Text('💕', style: TextStyle(fontSize: p.size)),
              );
            }
          } else {
            // Tet & Other holidays
            if (p.type == 0) {
              // Current apricot blossom (hoa mai)
              childWidget = Icon(Icons.local_florist, color: Colors.amber.withValues(alpha: 0.4), size: p.size);
            } else if (p.type == 1) {
              // Peach blossom (hoa đào)
              childWidget = Icon(Icons.local_florist, color: Colors.pinkAccent.withValues(alpha: 0.4), size: p.size);
            } else if (p.type == 2) {
              // Rồng (Dragon)
              childWidget = Text('🐉', style: TextStyle(fontSize: p.size * 1.2));
            } else {
              // Ngựa (Horse) - for year of the horse or general tet
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
