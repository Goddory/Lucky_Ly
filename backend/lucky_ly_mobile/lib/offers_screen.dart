import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';
import 'providers/auth_provider.dart';


class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  bool _isLoading = true;
  bool _isStudentVerified = false;
  String? _errorMessage;
  List<dynamic> _offers = [];

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.fetchProfile();

      final response = await auth.apiClient.get('/api/promotions/available');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final promotions = data['promotions'];
        setState(() {
          _offers = promotions is List ? promotions : [];
          _isStudentVerified = data['is_student_verified'] == true;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _offers = [];
        _isLoading = false;
        _errorMessage = 'Không thể tải ưu đãi. Mã lỗi: ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _offers = [];
        _isLoading = false;
        _errorMessage = 'Có lỗi khi tải ưu đãi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).bg,
      appBar: AppBar(
        title: const Text('Ưu đãi & Khuyến mãi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppTheme.of(context).primaryGradient)),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
          ? Center(child: const CustomLoading(size: 80))
          : _errorMessage != null
              ? _buildErrorState()
          : _offers.isEmpty 
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchOffers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offers.length,
                    itemBuilder: (context, index) {
                      return _buildOfferCard(_offers[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, color: AppTheme.of(context).textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Không tải được dữ liệu ưu đãi',
              style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOffers,
              child: const Text('Thử lại'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, color: AppTheme.of(context).textLight, size: 64),
          const SizedBox(height: 24),
          Text('Hiện chưa có ưu đãi nào', style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 16, fontWeight: FontWeight.w600)),
          if (!_isStudentVerified) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tài khoản chưa xác minh sinh viên nên chỉ hiển thị ưu đãi dành cho người dùng thường.',
                style: TextStyle(color: AppTheme.of(context).textLight, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildOfferCard(dynamic o) {
    final promo = o is Map<String, dynamic> ? o : <String, dynamic>{};
    final discountType = (promo['discount_type'] ?? '').toString().toLowerCase();
    final discountValueRaw = promo['discount_value'];
    final discountValue = num.tryParse(discountValueRaw?.toString() ?? '0') ?? 0;
    final isPercent = discountType == 'percent';
    final targetAudience = (promo['target_audience'] ?? 'All').toString();
    final voucherCode = (promo['sample_voucher_code'] ?? '').toString();

    String discountText;
    if (isPercent) {
      discountText = 'Giảm ${discountValue.toStringAsFixed(discountValue % 1 == 0 ? 0 : 2)}%';
    } else {
      discountText = 'Giảm ${discountValue.toStringAsFixed(discountValue % 1 == 0 ? 0 : 2)}đ';
    }

    final startsAt = promo['starts_at']?.toString();
    final expiresAt = promo['expires_at']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.of(context).divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (promo['name'] ?? 'Ưu đãi').toString(),
                  style: TextStyle(
                    color: AppTheme.of(context).textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.of(context).primaryGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  targetAudience == 'Student' ? 'Sinh viên' : 'Người dùng thường',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            discountText,
            style: TextStyle(
              color: AppTheme.of(context).primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (voucherCode.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.of(context).bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.of(context).divider),
                    ),
                    child: Text(
                      voucherCode,
                      style: TextStyle(
                        color: AppTheme.of(context).textDark,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: voucherCode));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã copy mã $voucherCode')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copy mã',
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          if (startsAt != null)
            Text('Bắt đầu: $startsAt', style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 12)),
          if (expiresAt != null)
            Text('Hết hạn: $expiresAt', style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
