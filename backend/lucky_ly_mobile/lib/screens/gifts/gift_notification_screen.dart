import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../app_theme.dart';
import 'gift_open_screen.dart';

class GiftNotificationScreen extends StatefulWidget {
  const GiftNotificationScreen({super.key});

  @override
  State<GiftNotificationScreen> createState() => _GiftNotificationScreenState();
}

class _GiftNotificationScreenState extends State<GiftNotificationScreen> {
  static final String _apiBaseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE_URL')
          : (kIsWeb ? 'http://localhost:4000' : 'http://10.0.2.2:4000');

  List<Map<String, dynamic>> _gifts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _loadGifts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/gifts/received'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _gifts = data.map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Không thể tải quà'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Lỗi kết nối: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.of(context);
    final pending = _gifts.where((g) => g['status'] == 'pending').length;

    return Scaffold(
      backgroundColor: appTheme.bg,
      appBar: AppBar(
        title: const Text('Quà của tôi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: appTheme.primaryGradient)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (pending > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pending chưa mở',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: appTheme.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadGifts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _gifts.isEmpty
                  ? _buildEmptyState(appTheme)
                  : RefreshIndicator(
                      onRefresh: _loadGifts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _gifts.length,
                        itemBuilder: (context, index) => _buildGiftCard(_gifts[index], appTheme),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(AppTheme appTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: appTheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_giftcard, color: appTheme.primary, size: 56),
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có quà nào',
            style: TextStyle(color: appTheme.textDark, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Quà tặng bạn nhận được sẽ hiển thị ở đây',
            style: TextStyle(color: appTheme.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCard(Map<String, dynamic> gift, AppTheme appTheme) {
    final isPending = gift['status'] == 'pending';
    final theme = gift['theme'] as String? ?? 'tet';
    final senderName = gift['sender_name'] ?? gift['sender_full_name'] ?? 'Người gửi';
    final createdAt = gift['created_at'] ?? '';
    final themeColor = theme == 'tet' ? const Color(0xFFc0392b) : const Color(0xFFe84393);
    final themeIcon = theme == 'tet' ? '🧧' : '💝';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GiftOpenScreen(gift: gift),
          ),
        ).then((_) => _loadGifts());
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isPending
              ? Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isPending
                  ? themeColor.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Theme icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(themeIcon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Từ $senderName',
                          style: TextStyle(
                            color: appTheme.textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPending)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Mới',
                            style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme == 'tet' ? 'Quà Tết' : 'Quà Valentine',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(color: appTheme.textLight, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isPending ? Icons.card_giftcard : Icons.check_circle_outline,
              color: isPending ? themeColor : Colors.green,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
