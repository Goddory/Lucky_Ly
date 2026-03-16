import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucky_ly_mobile/app_theme.dart';

class AdminAppealsScreen extends StatefulWidget {
  final String accessToken;
  final String apiBaseUrl;

  const AdminAppealsScreen({
    super.key,
    required this.accessToken,
    required this.apiBaseUrl,
  });

  @override
  _AdminAppealsScreenState createState() => _AdminAppealsScreenState();
}

class _AdminAppealsScreenState extends State<AdminAppealsScreen> {
  List<dynamic> _appeals = [];
  bool _isLoading = true;
  String _statusFilter = 'PENDING';

  @override
  void initState() {
    super.initState();
    _fetchAppeals();
  }

  Future<void> _fetchAppeals() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/appeals/admin/list?status=$_statusFilter'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _appeals = data['appeals'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load appeals');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _respondToAppeal(String appealId, String status) async {
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'APPROVED' ? 'Chấp nhận kháng cáo?' : 'Từ chối kháng cáo?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nhập ghi chú phản hồi cho người dùng:'),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ghi chú (tùy chọn)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(status == 'APPROVED' ? 'Chấp nhận' : 'Từ chối', style: TextStyle(color: status == 'APPROVED' ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.put(
        Uri.parse('${widget.apiBaseUrl}/api/appeals/admin/$appealId/respond'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status, 'adminNote': noteController.text}),
      );

      if (response.statusCode == 200) {
        _fetchAppeals();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã phản hồi kháng cáo thành công')),
        );
      } else {
        throw Exception('Failed to respond to appeal');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Quản lý kháng cáo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _appeals.isEmpty
                    ? const Center(child: Text('Không có đơn kháng cáo nào'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _appeals.length,
                        itemBuilder: (context, index) => _buildAppealCard(_appeals[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFilterButton('Chờ xử lý', 'PENDING'),
          _buildFilterButton('Chấp nhận', 'APPROVED'),
          _buildFilterButton('Từ chối', 'REJECTED'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final bool isSelected = _statusFilter == value;
    return InkWell(
      onTap: () {
        setState(() => _statusFilter = value);
        _fetchAppeals();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSelected ? AppTheme.primary : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? AppTheme.primary : AppTheme.textMuted, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildAppealCard(dynamic appeal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appeal['username'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                _formatDate(appeal['created_at']),
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(appeal['email'] ?? '', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          const Divider(height: 24),
          const Text('Lý do bị khóa:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
          Text(appeal['block_reason'] ?? 'Không rõ', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          const Text('Nội dung kháng cáo:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
          Text(appeal['reason'], style: const TextStyle(fontSize: 14)),
          if (_statusFilter == 'PENDING') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respondToAppeal(appeal['appeal_id'], 'REJECTED'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondToAppeal(appeal['appeal_id'], 'APPROVED'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Chấp nhận', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Divider(),
            Text('Ghi chú Admin:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(appeal['admin_note'] ?? '(Trống)', style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, "0")}';
    } catch (e) {
      return isoString;
    }
  }
}
