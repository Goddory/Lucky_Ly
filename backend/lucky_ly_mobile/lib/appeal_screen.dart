import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucky_ly_mobile/app_theme.dart';

class AppealScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // Chứa token và thông tin user sơ bộ
  final String apiBaseUrl;

  const AppealScreen({
    super.key,
    required this.userData,
    required this.apiBaseUrl,
  });

  @override
  _AppealScreenState createState() => _AppealScreenState();
}

class _AppealScreenState extends State<AppealScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _latestAppeal;
  bool _isLoadingLatest = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestAppeal();
  }

  Future<void> _fetchLatestAppeal() async {
    setState(() => _isLoadingLatest = true);
    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/appeals/my-latest'),
        headers: {
          'Authorization': 'Bearer ${widget.userData['accessToken']}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _latestAppeal = data;
          _isLoadingLatest = false;
        });
      } else {
        setState(() => _isLoadingLatest = false);
      }
    } catch (e) {
      setState(() => _isLoadingLatest = false);
    }
  }

  Future<void> _submitAppeal() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung kháng cáo')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/appeals'),
        headers: {
          'Authorization': 'Bearer ${widget.userData['accessToken']}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'reason': reason}),
      );

      final body = json.decode(response.body);
      if (response.statusCode == 201) {
        _reasonController.clear();
        _fetchLatestAppeal();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đơn kháng cáo của bạn đã được gửi thành công')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message'] ?? 'Gửi kháng cáo thất bại')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Kháng cáo tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 24),
            if (_latestAppeal == null || _latestAppeal!['status'] != 'PENDING') ...[
              const Text(
                'Gửi đơn kháng cáo mới',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nếu bạn cho rằng tài khoản bị khóa nhầm lẫn, hãy trình bày lý do tại đây.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung giải trình...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAppeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Gửi kháng cáo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ] else 
              _buildPendingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Tài khoản đang bị khóa',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userData['message'] ?? 'Vui lòng liên hệ quản trị viên để biết thêm chi tiết.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.amber, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Đang chờ xem xét',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          const Text(
            'Bạn đã gửi một đơn kháng cáo. Vui lòng chờ phản hồi từ phía quản trị viên hệ thống.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange),
          ),
          const SizedBox(height: 16),
          if (_latestAppeal != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nội dung đã gửi:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 4),
            Text(_latestAppeal!['reason'], style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
