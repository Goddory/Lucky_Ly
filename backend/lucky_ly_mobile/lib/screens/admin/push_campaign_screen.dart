import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PushCampaignScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;

  const PushCampaignScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<PushCampaignScreen> createState() => _PushCampaignScreenState();
}

class _PushCampaignScreenState extends State<PushCampaignScreen> {
  final titleCtrl = TextEditingController(text: 'Sale Giữa Tháng!');
  final bodyCtrl = TextEditingController(text: 'Giảm 50% toàn bộ phụ kiện!');
  String targetGroup = 'Tất cả';

  static const Color primary = Color(0xFF952CB1);
  static const Color primaryContainer = Color(0xFFF1A6FF);
  static const Color background = Color(0xFFFFF7FB);
  static const Color surfaceContainerLow = Color(0xFFFFEFFC);
  static const Color onSurface = Color(0xFF45274B);
  static const Color outlineVariant = Color(0xFFCCA5D0);

  bool _isSending = false;

  Future<void> _sendPush() async {
    if (_isSending) return;
    if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung.', style: TextStyle(fontFamily: 'PlusJakartaSans'))),
      );
      return;
    }

    setState(() => _isSending = true);
    
    try {
      final res = await http.post(
        Uri.parse('\${widget.apiBaseUrl}/api/promotions/push'),
        headers: {
          'Authorization': 'Bearer \${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': titleCtrl.text,
          'body': bodyCtrl.text,
          'target_group': targetGroup,
        }),
      );
      
      if (!mounted) return;
      setState(() => _isSending = false);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final count = data['sent_count'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chiến dịch đã gửi tới $count người dùng!', style: const TextStyle(fontFamily: 'PlusJakartaSans')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi khi gửi thông báo.', style: TextStyle(fontFamily: 'PlusJakartaSans')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e', style: const TextStyle(fontFamily: 'PlusJakartaSans')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background Muted Purple Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [background, surfaceContainerLow, primaryContainer.withValues(alpha: 0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryContainer.withValues(alpha: 0.3)),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withValues(alpha: 0.2)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thông báo xem trước', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, color: primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildPhonePreview(),
                        const SizedBox(height: 32),
                        const Text('Cài đặt nội dung', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, color: primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildSettingsCard(),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: primary.withValues(alpha: 0.5),
                            ),
                            onPressed: _isSending ? null : _sendPush,
                            child: _isSending 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('GỬI THÔNG BÁO NGAY', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: primary)),
              const SizedBox(width: 8),
              const Text(
                'PUSH CAMPAIGNS',
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 20, fontWeight: FontWeight.bold, color: primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhonePreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [BoxShadow(color: onSurface.withValues(alpha: 0.05), blurRadius: 15, spreadRadius: 2)],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
                border: Border.all(color: outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [primary, primaryContainer]), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Lucky Ly', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ValueListenableBuilder(
                          valueListenable: titleCtrl,
                          builder: (context, value, _) => Text(value.text.isEmpty ? 'Tiêu đề' : value.text, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        const SizedBox(height: 4),
                        ValueListenableBuilder(
                          valueListenable: bodyCtrl,
                          builder: (context, value, _) => Text(value.text.isEmpty ? 'Nội dung thông báo' : value.text, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Colors.black54)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [BoxShadow(color: onSurface.withValues(alpha: 0.05), blurRadius: 15)],
          ),
          child: Column(
            children: [
              _buildTextField('Tiêu đề Notification', titleCtrl),
              const SizedBox(height: 16),
              _buildTextField('Nội dung chi tiết', bodyCtrl, maxLines: 3),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: targetGroup,
                items: ['Tất cả', 'Sinh viên', 'Khách VIP', 'Chưa mua hàng 30 ngày']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontFamily: 'PlusJakartaSans', color: onSurface, fontWeight: FontWeight.bold)))).toList(),
                onChanged: (v) => setState(() => targetGroup = v!),
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Tệp khách hàng nhận',
                  labelStyle: const TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.black54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontFamily: 'PlusJakartaSans', color: onSurface, fontWeight: FontWeight.w500),
      onChanged: (v) => setState((){}), // trigger rebuild for preview
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.black54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
