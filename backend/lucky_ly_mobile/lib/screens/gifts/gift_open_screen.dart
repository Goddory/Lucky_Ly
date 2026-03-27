import 'dart:io' as io;
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/gift_catalog.dart';
import '../../app_theme.dart';
import '../../widgets/confetti_painter.dart';
import '../../widgets/particle_overlay.dart';
import '../../widgets/glb_model_viewer.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';


class GiftOpenScreen extends StatefulWidget {
  const GiftOpenScreen({super.key, required this.gift});
  final Map<String, dynamic> gift;

  @override
  State<GiftOpenScreen> createState() => _GiftOpenScreenState();
}

class _GiftOpenScreenState extends State<GiftOpenScreen>
    with TickerProviderStateMixin {
  static final String _apiBaseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE_URL')
          : (kIsWeb ? 'http://localhost:4000' : 'http://10.0.2.2:4000');

  // State machine
  _OpenPhase _phase = _OpenPhase.initial;
  bool _hasCamera = false;
  bool _showConfetti = false;
  bool _showParticles = false;
  bool _showMessage = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _revealController;
  late Animation<double> _revealScale;
  late Animation<double> _revealOpacity;
  late AnimationController _messageSlideController;
  late Animation<Offset> _messageSlide;

  final GlobalKey _captureKey = GlobalKey();

  String get _theme => widget.gift['theme'] as String? ?? 'tet';
  String get _modelId => widget.gift['model_id'] as String? ?? '';
  String get _message => widget.gift['message'] as String? ?? '';
  String get _senderName =>
      widget.gift['sender_name'] ?? widget.gift['sender_full_name'] ?? 'Người gửi';
  bool get _isPending => widget.gift['status'] == 'pending';

  GiftModel? get _selectedModel {
    final models = GiftCatalog.getModels(_theme);
    for (final model in models) {
      if (model.id == _modelId) {
        return model;
      }
    }
    return null;
  }

  Color get _themeColor =>
      _theme == 'tet' ? const Color(0xFFc0392b) : const Color(0xFFe84393);
  Color get _themeAccent =>
      _theme == 'tet' ? const Color(0xFFf39c12) : const Color(0xFF9b59b6);

  LinearGradient get _themeGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _theme == 'tet'
            ? [const Color(0xFFFFE0D0), const Color(0xFFFFF5F5), const Color(0xFFFEF3E2)]
            : [const Color(0xFFFCE4EC), const Color(0xFFFFF0F6), const Color(0xFFF3E5F5)],
      );

  @override
  void initState() {
    super.initState();

    // Shake animation for unboxing
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 15, end: -15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -15, end: 12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));

    // Reveal animation
    _revealController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _revealScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.elasticOut),
    );
    _revealOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _revealController, curve: const Interval(0, 0.4, curve: Curves.easeIn)),
    );

    // Message slide animation
    _messageSlideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _messageSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _messageSlideController, curve: Curves.easeOutCubic),
    );

    if (_isPending) {
      _requestCameraAndStart();
    } else {
      _phase = _OpenPhase.revealed;
      _showParticles = true;
      _showMessage = _message.isNotEmpty;
      _revealController.value = 1.0;
      if (_showMessage) _messageSlideController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _revealController.dispose();
    _messageSlideController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraAndStart() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasCamera = status.isGranted;
      _phase = _OpenPhase.unboxing;
    });
    _markAsOpened();
    _startUnboxingAnimation();
  }

  Future<void> _markAsOpened() async {
    try {
      final token = (await SharedPreferences.getInstance()).getString('access_token');
      await http.patch(
        Uri.parse('$_apiBaseUrl/api/gifts/${widget.gift['id']}/open'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> _startUnboxingAnimation() async {
    // Phase 1: Shake
    await _shakeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));

    // Phase 2: Confetti burst
    setState(() => _showConfetti = true);
    await Future.delayed(const Duration(milliseconds: 500));

    // Phase 3: Reveal model
    setState(() => _phase = _OpenPhase.revealed);
    _revealController.forward();

    // Phase 4: Particles
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _showParticles = true);

    // Phase 5: Message card
    if (_message.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _showMessage = true);
      _messageSlideController.forward();
    }
  }

  Future<void> _captureScreenshot() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/gift_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = io.File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📸 Đã lưu ảnh!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _themeColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể chụp ảnh'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _phase == _OpenPhase.initial ? _themeColor : Colors.white),
        actions: [
          if (_phase == _OpenPhase.revealed)
            IconButton(
              onPressed: _captureScreenshot,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
      body: RepaintBoundary(
        key: _captureKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background layer
            _buildBackground(),

            // Gift content
            _buildGiftContent(),

            // Confetti overlay
            ConfettiOverlay(isPlaying: _showConfetti, theme: _theme),

            // Particle overlay
            ParticleOverlay(isPlaying: _showParticles, theme: _theme),

            // Message card
            if (_showMessage) _buildMessageCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    // Themed gradient background (fallback or AR backdrop)
    return Container(
      decoration: BoxDecoration(gradient: _themeGradient),
      child: _hasCamera && _phase != _OpenPhase.initial
          ? null
          : _buildThemeDecorations(),
    );
  }

  Widget _buildThemeDecorations() {
    return Stack(
      children: [
        // Gradient already applied
        // Add theme-specific decorative elements
        if (_theme == 'tet') ...[
          Positioned(top: -30, right: -30, child: _decorCircle(100, const Color(0xFFFFD700).withValues(alpha: 0.15))),
          Positioned(bottom: -50, left: -40, child: _decorCircle(140, const Color(0xFFFF0000).withValues(alpha: 0.1))),
          Positioned(top: 120, left: 20, child: _decorCircle(60, const Color(0xFFF39C12).withValues(alpha: 0.12))),
        ] else ...[
          Positioned(top: -40, left: -30, child: _decorCircle(120, const Color(0xFFFF69B4).withValues(alpha: 0.12))),
          Positioned(bottom: -40, right: -30, child: _decorCircle(130, const Color(0xFFE84393).withValues(alpha: 0.1))),
          Positioned(top: 100, right: 30, child: _decorCircle(50, const Color(0xFFFD79A8).withValues(alpha: 0.15))),
        ],
      ],
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildGiftContent() {
    switch (_phase) {
      case _OpenPhase.initial:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CustomLoading(size: 80),
              const SizedBox(height: 16),
              Text('Đang chuẩn bị...', style: TextStyle(color: _themeColor, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      case _OpenPhase.unboxing:
        return _buildUnboxingView();
      case _OpenPhase.revealed:
        return _buildRevealedView();
    }
  }

  Widget _buildUnboxingView() {
    return Center(
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _shakeAnimation.value * pi / 180,
            child: child,
          );
        },
        child: Container(
          width: 160, height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_themeColor, _themeAccent],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: _themeColor.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5),
            ],
          ),
          child: const Center(
            child: Icon(Icons.card_giftcard, color: Colors.white, size: 80),
          ),
        ),
      ),
    );
  }

  Widget _buildRevealedView() {
    return Center(
      child: AnimatedBuilder(
        animation: _revealScale,
        builder: (context, child) {
          return Opacity(
            opacity: _revealOpacity.value,
            child: Transform.scale(
              scale: _revealScale.value,
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Model display
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _themeColor.withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: _selectedModel != null
                    ? ClipOval(
                        child: SizedBox(
                          width: 196,
                          height: 196,
                          child: GlbModelViewer(
                            key: ValueKey(_selectedModel!.id),
                            assetPath: _selectedModel!.assetPath,
                            alt: _selectedModel!.name,
                            autoRotate: true,
                            cameraControls: true,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.card_giftcard,
                        color: _themeColor,
                        size: 80,
                      ),
                ),
            ),
            const SizedBox(height: 24),
            Text(
              _selectedModel?.name ?? _getModelName(),
              style: TextStyle(
                color: _themeColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Từ $_senderName',
                style: TextStyle(
                  color: _themeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _messageSlide,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.mail_outline, color: _themeColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Lời nhắn từ $_senderName',
                    style: TextStyle(
                      color: _themeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _message,
                style: TextStyle(
                  color: AppTheme.of(context).textDark,
                  fontSize: 16,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              // Theme emoji footer
              Center(
                child: Text(
                  _theme == 'tet' ? '🧧✨🎆' : '💕🌹✨',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModelName() {
    final models = {
      'tet_lixi_red': 'Bao Lì Xì Đỏ',
      'tet_lixi_gold': 'Bao Lì Xì Vàng',
      'tet_lixi_hoamai': 'Bao Lì Xì Hoa Mai',
      'tet_lixi_dragon': 'Bao Lì Xì Rồng',
      'tet_lixi_phucloc': 'Bao Lì Xì Phúc Lộc',
      'val_heart_box': 'Hộp Quà Trái Tim',
      'val_ribbon_box': 'Hộp Quà Nơ',
      'val_teddy': 'Gấu Bông',
      'val_bouquet': 'Bó Hoa',
      'val_chocolate': 'Socola',
    };
    return models[_modelId] ?? 'Quà tặng';
  }
}

enum _OpenPhase { initial, unboxing, revealed }
