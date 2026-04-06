import 'dart:io' as io;
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_client.dart';
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
  static final String _apiBaseUrl = ApiClient.getBaseUrl();

  late Map<String, dynamic> _gift;

  // State machine
  _OpenPhase _phase = _OpenPhase.initial;
  bool _hasCamera = false;
  bool _showConfetti = false;
  bool _showParticles = false;
  bool _showMessage = false;
  bool _isReceivingCash = false;
  bool _isGiftOpenedOnServer = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _revealController;
  late Animation<double> _revealScale;
  late Animation<double> _revealOpacity;
  late AnimationController _messageSlideController;
  late Animation<Offset> _messageSlide;

  final GlobalKey _captureKey = GlobalKey();

  String get _theme => _gift['theme'] as String? ?? 'tet';

  String get _themeIconAsset {
    if (_theme == 'tet') return 'assets/ảnh icon Luckyly/Lucky_Ly/Chào mừng lễ hội/tết nguyên đán.png';
    if (_theme == 'valentine') return 'assets/ảnh icon Luckyly/Lucky_Ly/Chào mừng lễ hội/valentine.png';
    return 'assets/ảnh icon Luckyly/Lucky_Ly/trang_chu/hộp quà.png'; // default fallback
  }
  String get _modelId => _gift['model_id'] as String? ?? '';
  String get _message => _gift['message'] as String? ?? '';
  String get _senderName =>
      _gift['sender_name'] ?? _gift['sender_full_name'] ?? 'Người gửi';
  bool get _isPending => _gift['status'] == 'pending';
  double get _cashAmount => double.tryParse(_gift['cash_amount']?.toString() ?? '0') ?? 0;
  bool get _isCashClaimed => _gift['claimed_at'] != null;
  bool get _isCashRefunded => _gift['refunded_at'] != null;

  DateTime? get _openedAt {
    final raw = _gift['opened_at']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  bool get _isClaimWindowExpired {
    final openedAt = _openedAt;
    if (openedAt == null) return false;
    return DateTime.now().isAfter(openedAt.add(const Duration(hours: 24)));
  }

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
    _gift = Map<String, dynamic>.from(widget.gift);

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
      _isGiftOpenedOnServer = true;
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

  Future<void> _markAsOpened({int retryCount = 0}) async {
    const maxRetries = 2;
    try {
      final token = (await SharedPreferences.getInstance()).getString('access_token');
      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/api/gifts/${_gift['id']}/open'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if ((response.statusCode == 200 || response.statusCode == 409) && mounted) {
        final decoded = jsonDecode(response.body);
        final gift = decoded is Map<String, dynamic>
            ? decoded['gift'] as Map<String, dynamic>?
            : null;
        if (gift != null) {
          setState(() {
            _gift = {..._gift, ...gift};
            _isGiftOpenedOnServer = true;
          });
        } else {
          // API returned success but no gift object (e.g. 409 already opened)
          setState(() => _isGiftOpenedOnServer = true);
        }
      } else if (retryCount < maxRetries && mounted) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _markAsOpened(retryCount: retryCount + 1);
      } else if (mounted) {
        // Exhausted retries, still allow user to try receive (server will validate)
        setState(() => _isGiftOpenedOnServer = true);
      }
    } catch (_) {
      if (retryCount < maxRetries && mounted) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _markAsOpened(retryCount: retryCount + 1);
      } else if (mounted) {
        // Network failed after retries — let user attempt anyway, server validates
        setState(() => _isGiftOpenedOnServer = true);
      }
    }
  }

  Future<void> _receiveGiftCash() async {
    if (_isReceivingCash || _isCashClaimed || _isCashRefunded || _cashAmount <= 0) {
      return;
    }

    setState(() => _isReceivingCash = true);
    try {
      final token = (await SharedPreferences.getInstance()).getString('access_token');
      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/api/gifts/${_gift['id']}/receive'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 12));

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final gift = decoded['gift'];
        if (gift is Map<String, dynamic>) {
          setState(() {
            _gift = {..._gift, ...gift};
          });
        }

        final message = decoded['message']?.toString();
        if (mounted && message != null && message.isNotEmpty) {
          final isSuccess = response.statusCode == 200;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: isSuccess ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('=== RECEIVE_CASH_ERROR ===');
      debugPrint('Gift ID: ${_gift['id']}');
      debugPrint('URL: $_apiBaseUrl/api/gifts/${_gift['id']}/receive');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      if (mounted) {
        String errorMsg = 'Không thể nhận tiền lúc này. Vui lòng thử lại.';
        if (e is http.ClientException) {
          errorMsg = 'Lỗi kết nối mạng. Vui lòng kiểm tra mạng và thử lại.';
        } else if (e is FormatException) {
          errorMsg = 'Lỗi phản hồi từ máy chủ. Vui lòng thử lại.';
        } else if (e.toString().contains('TimeoutException')) {
          errorMsg = 'Hết thời gian chờ. Máy chủ có thể đang khởi động, vui lòng thử lại.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReceivingCash = false);
      }
    }
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
          child: Center(
            child: Image.asset(_themeIconAsset, width: 80, height: 80, fit: BoxFit.contain),
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
                    : Image.asset(_themeIconAsset, width: 100, height: 100, fit: BoxFit.contain),
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
    final cashAmount = _cashAmount;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _messageSlide,
        child: Container(
          margin: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF45274b).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cashAmount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9333ea), Color(0xFFf472b6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFa855f7).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.5)),
                              ),
                              child: Center(
                                child: Image.asset(_themeIconAsset, width: 22, height: 22, fit: BoxFit.contain),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Quà tặng tiền mặt! ✨',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+ ${cashAmount.toInt()}đ',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                      shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Nhận về ví trong 24h sau khi mở quà',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCashActionButton(),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF952cb1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.mail_outline, color: Color(0xFF952cb1), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Lời nhắn từ $_senderName',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Color(0xFF581c87),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFE6FE), width: 1.5),
                      ),
                      child: Text(
                        _message,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: Color(0xFF45274b),
                          fontSize: 16,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashActionButton() {
    if (_cashAmount <= 0) {
      return const SizedBox.shrink();
    }

    if (_isCashClaimed) {
      return _statusPill(
        label: 'Đã nhận vào ví',
        icon: Icons.check_circle,
        color: Colors.green,
      );
    }

    if (_isCashRefunded || _isClaimWindowExpired) {
      return _statusPill(
        label: 'Đã hoàn về người gửi',
        icon: Icons.undo,
        color: Colors.orange,
      );
    }

    final bool canReceive = _isGiftOpenedOnServer && !_isReceivingCash;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF9333ea), Color(0xFFf472b6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFa855f7).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: canReceive ? _receiveGiftCash : null,
        icon: _isReceivingCash
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
        label: Text(
          _isReceivingCash
              ? 'Đang xử lý...'
              : !_isGiftOpenedOnServer
                  ? 'Đang mở quà...'
                  : 'Nhận vào ví cá nhân',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        ),
      ),
    );
  }

  Widget _statusPill({required String label, required IconData icon, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
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
