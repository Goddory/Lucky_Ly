import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app_theme.dart';

class StudentVerificationScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;

  const StudentVerificationScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<StudentVerificationScreen> createState() => _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _all = [];

  List<dynamic> get _pending => _all.where((v) => v['status'] == 'pending').toList();
  List<dynamic> get _approved => _all.where((v) => v['status'] == 'approved').toList();
  List<dynamic> get _rejected => _all.where((v) => v['status'] == 'rejected').toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVerifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadVerifications() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/student-verification'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _all = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _review(int id, String status) async {
    try {
      final res = await http.put(
        Uri.parse('${widget.apiBaseUrl}/api/student-verification/$id/review'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );
      if (res.statusCode == 200) {
        _loadVerifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(status == 'approved' ? 'Đã duyệt ✅' : 'Đã từ chối ❌')),
          );
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Xác thực Sinh viên'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Chờ duyệt (${_pending.length})'),
            Tab(text: 'Đã duyệt (${_approved.length})'),
            Tab(text: 'Từ chối (${_rejected.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_pending, 'pending'),
                _buildList(_approved, 'approved'),
                _buildList(_rejected, 'rejected'),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> items, String type) {
    final theme = AppTheme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == 'pending' ? Icons.hourglass_empty : type == 'approved' ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 56, color: theme.textLight,
            ),
            const SizedBox(height: 12),
            Text('Không có bản ghi nào', style: TextStyle(color: theme.textMuted, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVerifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildCard(items[i], type, theme),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, String type, dynamic theme) {
    final statusColor = type == 'pending'
        ? const Color(0xFFF59E0B)
        : type == 'approved'
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 160,
              width: double.infinity,
              color: theme.bg,
              child: item['card_image_url'] != null && item['card_image_url'].toString().isNotEmpty
                  ? Image.network(
                      item['card_image_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.badge_outlined, size: 48, color: theme.textLight),
                      ),
                    )
                  : Center(child: Icon(Icons.badge_outlined, size: 48, color: theme.textLight)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: statusColor.withValues(alpha: 0.1),
                      child: Text(
                        (item['username'] ?? '?')[0].toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['username'] ?? 'Unknown', style: TextStyle(
                            fontWeight: FontWeight.bold, color: theme.textDark,
                          )),
                          Text(item['email'] ?? '', style: TextStyle(
                            fontSize: 12, color: theme.textMuted,
                          )),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(type.toUpperCase(), style: TextStyle(
                        color: statusColor, fontSize: 11, fontWeight: FontWeight.bold,
                      )),
                    ),
                  ],
                ),
                if (item['school_name'] != null && item['school_name'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.school, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(item['school_name'], style: TextStyle(fontSize: 13, color: theme.textMuted)),
                    ],
                  ),
                ],
                if (type == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _review(item['id'], 'rejected'),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Từ chối'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _review(item['id'], 'approved'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Duyệt'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
