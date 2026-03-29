import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'core/services/api_client.dart';

class PaymentScreen extends StatelessWidget {
  PaymentScreen({Key? key, String? apiBaseUrl}) 
    : apiBaseUrl = apiBaseUrl ?? ApiClient.getBaseUrl(), 
      super(key: key);
  
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        backgroundColor: theme.primary,
        title: const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textDark),
            ),
            const SizedBox(height: 16),
            _PaymentOptionCard(
              icon: Icons.account_balance_wallet,
              color: const Color(0xFFA50064), // MoMo pink color
              title: 'Thanh toán bằng MoMo',
              subtitle: 'An toàn, tiện lợi và nhanh chóng',
              onTap: () {
                _showMoMoPaymentBottomSheet(context, apiBaseUrl);
              },
            ),
            const SizedBox(height: 12),
            _PaymentOptionCard(
              icon: Icons.credit_card,
              color: theme.primary,
              title: 'Thẻ tín dụng / Ghi nợ',
              subtitle: 'Visa, Mastercard, JCB',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _PaymentOptionCard(
              icon: Icons.account_balance,
              color: const Color(0xFF0C8DB8),
              title: 'Chuyển khoản ngân hàng',
              subtitle: 'Vietcombank, Techcombank, ...',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _PaymentOptionCard(
              icon: Icons.payment,
              color: const Color(0xFF005BAA), // Darker blue for VNPay
              title: 'Thanh toán qua VNPay',
              subtitle: 'Thẻ ATM, Visa, Mastercard, QR Code',
              onTap: () {
                _showVNPayBottomSheet(context, apiBaseUrl);
              },
            ),
            const SizedBox(height: 12),
            _PaymentOptionCard(
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF0068FF), // ZaloPay blue color
              title: 'Thanh toán qua ZaloPay',
              subtitle: 'Nhanh chóng, tiện lợi, an toàn',
              onTap: () {
                _showZaloPayBottomSheet(context, apiBaseUrl);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  const _PaymentOptionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardTheme = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardTheme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cardTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: cardTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cardTheme.textLight),
          ],
        ),
      ),
    );
  }
}

void _showMoMoPaymentBottomSheet(BuildContext context, String apiBaseUrl) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MoMoPaymentFlow(apiBaseUrl: apiBaseUrl),
  );
}

class _MoMoPaymentFlow extends StatefulWidget {
  final String apiBaseUrl;
  const _MoMoPaymentFlow({Key? key, required this.apiBaseUrl}) : super(key: key);

  @override
  State<_MoMoPaymentFlow> createState() => _MoMoPaymentFlowState();
}

class _MoMoPaymentFlowState extends State<_MoMoPaymentFlow> {
  final TextEditingController _amountController = TextEditingController(text: '50000');
  bool _isLoading = false;
  late AppTheme momoTheme;

  Future<void> _createAndOpenMoMo() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if(amountText.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? prefs.getString('access_token');
      
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/payment/momo/create'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': int.parse(amountText),
          'orderInfo': 'Nap tien vao vi Lucky Ly qua MoMo'
        }),
      );
      
      if(response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payUrl = data['payUrl'];
        if(payUrl != null) {
          final uri = Uri.parse(payUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (mounted) Navigator.pop(context); // Close bottom sheet after launching
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở trình duyệt')));
            }
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${errorData['message'] ?? 'Thất bại'}')));
        }
      }
    } catch(e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: momoTheme.card,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: momoTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFA50064).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet, color: Color(0xFFA50064), size: 40),
            ),
            const SizedBox(height: 20),
            Text('Nạp Tiền Qua MoMo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: momoTheme.textDark)),
            const SizedBox(height: 8),
            Text('Nhập số tiền bạn muốn nạp qua MoMo', style: TextStyle(color: momoTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: 'VNĐ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: momoTheme.bg,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA50064),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _createAndOpenMoMo,
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Thanh toán qua MoMo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

void _showVNPayBottomSheet(BuildContext context, String apiBaseUrl) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _VNPayPaymentFlow(apiBaseUrl: apiBaseUrl),
  );
}

class _VNPayPaymentFlow extends StatefulWidget {
  final String apiBaseUrl;
  const _VNPayPaymentFlow({Key? key, required this.apiBaseUrl}) : super(key: key);

  @override
  State<_VNPayPaymentFlow> createState() => _VNPayPaymentFlowState();
}

class _VNPayPaymentFlowState extends State<_VNPayPaymentFlow> {
  final TextEditingController _amountController = TextEditingController(text: '50000');
  bool _isLoading = false;
  late AppTheme vnpayTheme;

  Future<void> _createAndOpenVNPay() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if(amountText.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? prefs.getString('access_token');
      
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/payment/vnpay/create'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': int.parse(amountText),
          'orderInfo': 'Nap tien Lucky Ly'
        }),
      );
      
      if(response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payUrl = data['payUrl'];
        if(payUrl != null) {
          final uri = Uri.parse(payUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            Navigator.pop(context); // Close bottom sheet after launching
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở trình duyệt')));
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi kết nối Server')));
      }
    } catch(e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: vnpayTheme.card,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: vnpayTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0C8DB8).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance, color: Color(0xFF0C8DB8), size: 40),
            ),
            const SizedBox(height: 20),
            Text('Nạp Tiền Qua VNPay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: vnpayTheme.textDark)),
            const SizedBox(height: 8),
            Text('Nhập số tiền bạn muốn nạp', style: TextStyle(color: vnpayTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: 'VNĐ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: vnpayTheme.bg,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C8DB8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _createAndOpenVNPay,
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Tiếp tục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

void _showZaloPayBottomSheet(BuildContext context, String apiBaseUrl) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ZaloPayPaymentFlow(apiBaseUrl: apiBaseUrl),
  );
}

class _ZaloPayPaymentFlow extends StatefulWidget {
  final String apiBaseUrl;
  const _ZaloPayPaymentFlow({Key? key, required this.apiBaseUrl}) : super(key: key);

  @override
  State<_ZaloPayPaymentFlow> createState() => _ZaloPayPaymentFlowState();
}

class _ZaloPayPaymentFlowState extends State<_ZaloPayPaymentFlow> {
  final TextEditingController _amountController = TextEditingController(text: '50000');
  bool _isLoading = false;
  late AppTheme zaloTheme;

  Future<void> _createAndOpenZaloPay() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if(amountText.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? prefs.getString('access_token');
      
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/payment/zalopay/create'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': int.parse(amountText),
          'orderInfo': 'Nap tien Lucky Ly qua ZaloPay',
          'returnUrl': Uri.base.toString()
        }),
      );
      
      if(response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final payUrl = data['payUrl'];
        if(payUrl != null) {
          final uri = Uri.parse(payUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (mounted) Navigator.pop(context); 
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở trình duyệt')));
            }
          }
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${errorData['message'] ?? 'Thất bại'}')));
        }
      }
    } catch(e) {
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: zaloTheme.card,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: zaloTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0068FF).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet, color: Color(0xFF0068FF), size: 40),
            ),
            const SizedBox(height: 20),
            Text('Nạp Tiền Qua ZaloPay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: zaloTheme.textDark)),
            const SizedBox(height: 8),
            Text('Nhập số tiền bạn muốn nạp qua ZaloPay', style: TextStyle(color: zaloTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: 'VNĐ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: zaloTheme.bg,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0068FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _createAndOpenZaloPay,
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Thanh toán qua ZaloPay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
