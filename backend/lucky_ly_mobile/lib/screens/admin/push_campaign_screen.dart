import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _sendPush() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang gửi chiến dịch Push...', style: GoogleFonts.beVietnamPro()),
        backgroundColor: const Color(0xFF6B48FF),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chiến dịch đã được gửi thành công đến $targetGroup!', style: GoogleFonts.beVietnamPro()),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF6B48FF).withValues(alpha: 0.4)),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF48A4).withValues(alpha: 0.5)),
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
                        Text('Thông báo xem trước', style: GoogleFonts.chakraPetch(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildPhonePreview(),
                        const SizedBox(height: 32),
                        Text('Cài đặt nội dung', style: GoogleFonts.chakraPetch(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildSettingsCard(),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B48FF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: _sendPush,
                            child: Text('GỬI THÔNG BÁO NGAY', style: GoogleFonts.chakraPetch(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
              const SizedBox(width: 8),
              Text(
                'PUSH CAMPAIGNS',
                style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 60, height: 6, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFF6B48FF), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lucky Ly', style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        ValueListenableBuilder(
                          valueListenable: titleCtrl,
                          builder: (context, value, _) => Text(value.text.isEmpty ? 'Tiêu đề' : value.text, style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                        const SizedBox(height: 4),
                        ValueListenableBuilder(
                          valueListenable: bodyCtrl,
                          builder: (context, value, _) => Text(value.text.isEmpty ? 'Nội dung thông báo' : value.text, style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.black54)),
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
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.beVietnamPro(color: Colors.white)))).toList(),
                onChanged: (v) => setState(() => targetGroup = v!),
                dropdownColor: const Color(0xFF2C2C3E),
                decoration: InputDecoration(
                  labelText: 'Tệp khách hàng nhận',
                  labelStyle: GoogleFonts.beVietnamPro(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
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
      style: GoogleFonts.beVietnamPro(color: Colors.white),
      onChanged: (v) => setState((){}), // trigger rebuild for preview
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.beVietnamPro(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}
