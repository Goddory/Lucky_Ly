import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../data/gift_catalog.dart';
import '../../app_theme.dart';

class GiftPreviewScreen extends StatefulWidget {
  const GiftPreviewScreen({
    super.key,
    required this.theme,
    required this.model,
    required this.stickers,
    required this.message,
  });

  final String theme;
  final GiftModel model;
  final List<Map<String, dynamic>> stickers;
  final String message;

  @override
  State<GiftPreviewScreen> createState() => _GiftPreviewScreenState();
}

class _GiftPreviewScreenState extends State<GiftPreviewScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  bool _isSending = false;

  static final String _apiBaseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE_URL')
          : (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux ? 'http://localhost:4000' : 'http://10.0.2.2:4000');

  Color get _themeColor =>
      widget.theme == 'tet' ? const Color(0xFFc0392b) : const Color(0xFFe84393);
  LinearGradient get _themeGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.theme == 'tet'
            ? [const Color(0xFFe74c3c), const Color(0xFFc0392b)]
            : [const Color(0xFFfd79a8), const Color(0xFFe84393)],
      );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _sendGift() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Vui lòng nhập email người nhận');
      return;
    }

    setState(() => _isSending = true);
    try {
      final token = await _getToken();
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/api/gifts'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Cookie': 'accessToken=$token',
            },
            body: jsonEncode({
              'receiverEmail': email,
              'theme': widget.theme,
              'modelId': widget.model.id,
              'stickers': widget.stickers,
              'message': widget.message,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        final body = jsonDecode(response.body);
        _showSnackBar(body['message']?.toString() ?? 'Gửi quà thất bại');
      }
    } catch (e) {
      _showSnackBar('Không thể kết nối server');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 56),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gửi quà thành công! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Quà đã được gửi đến ${_emailController.text.trim()}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Xong'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: appTheme.bg,
      appBar: AppBar(
        title: const Text('Xem trước quà', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: _themeGradient)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gift preview card
            Container(
              height: 320,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.theme == 'tet'
                      ? [const Color(0xFFFFF5F5), const Color(0xFFFEF3E2)]
                      : [const Color(0xFFFFF0F6), const Color(0xFFF8F0FC)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _themeColor.withValues(alpha: 0.1)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: ModelViewer(
                              key: ValueKey(widget.model.id),
                              src: widget.model.assetPath,
                              alt: widget.model.name,
                              autoRotate: true,
                              cameraControls: true,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          ...widget.stickers.map((s) {
                            final stickerData = GiftCatalog.getStickers(widget.theme).firstWhere(
                              (e) => e.id == s['id'],
                              orElse: () => const GiftSticker(id: '', name: '', assetPath: '', theme: ''),
                            );
                            if (stickerData.assetPath.isEmpty) return const SizedBox.shrink();
                            return Positioned(
                              left: (s['x'] as num).toDouble(),
                              top: (s['y'] as num).toDouble(),
                              child: Transform.rotate(
                                angle: ((s['rotation'] ?? 0.0) as num).toDouble(),
                                child: Transform.scale(
                                  scale: ((s['scale'] ?? 1.0) as num).toDouble(),
                                  child: SizedBox(
                                    width: 44, height: 44,
                                    child: Image.asset(stickerData.assetPath, fit: BoxFit.contain),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.model.name,
                      style: TextStyle(
                        color: appTheme.textDark,
                        fontSize: 20, fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.theme == 'tet' ? '🧧 Chủ đề Tết' : '💕 Chủ đề Valentine',
                        style: TextStyle(color: _themeColor, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Sticker count & message
            if (widget.stickers.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _themeColor.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: _themeColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${widget.stickers.length} sticker đã thêm',
                      style: TextStyle(color: appTheme.textDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            if (widget.message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _themeColor.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.format_quote, color: _themeColor, size: 20),
                        const SizedBox(width: 8),
                        Text('Lời nhắn', style: TextStyle(color: appTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.message,
                      style: TextStyle(color: appTheme.textDark, fontSize: 15, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Recipient input
            Text(
              'Gửi đến',
              style: TextStyle(color: appTheme.textDark, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _themeColor.withValues(alpha: 0.12)),
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: appTheme.textDark, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Email người nhận',
                  hintStyle: TextStyle(color: appTheme.textLight),
                  prefixIcon: Icon(Icons.email_outlined, color: _themeColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Send button
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendGift,
              icon: _isSending
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_isSending ? 'Đang gửi...' : 'Gửi quà 🎁'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
