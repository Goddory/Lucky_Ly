import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({Key? key, this.apiBaseUrl = 'http://localhost:4000'}) : super(key: key);
  
  final String apiBaseUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
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
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
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
              color: AppTheme.primary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textLight),
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
    builder: (context) => const _MoMoPaymentFlow(),
  );
}

class _MoMoPaymentFlow extends StatefulWidget {
  const _MoMoPaymentFlow({Key? key}) : super(key: key);

  @override
  State<_MoMoPaymentFlow> createState() => _MoMoPaymentFlowState();
}

class _MoMoPaymentFlowState extends State<_MoMoPaymentFlow> {
  int _step = -1; // -1: Loading, 0: Input Phone, 1: Linking, 2: Confirm Saved, 3: Processing, 4: Success
  final TextEditingController _phoneController = TextEditingController();
  String? _linkedMoMoPhone;

  @override
  void initState() {
    super.initState();
    _loadSavedPhone();
  }

  Future<void> _loadSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _linkedMoMoPhone = prefs.getString('momo_phone');
      _step = (_linkedMoMoPhone == null || _linkedMoMoPhone!.isEmpty) ? 0 : 2;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_step) {
      case 0:
        return _buildInputPhoneStep();
      case 1:
        return _buildQRCodeStep();
      case 2:
        return _buildConfirmSavedStep();
      case 3:
        return _buildQRCodeStep();
      case 4:
        return _buildSuccessStep();
      case -1:
        return _buildLoadingStep('Đang tải...', valueKey: -1);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInputPhoneStep() {
    return Column(
      key: const ValueKey(0),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFA50064).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance_wallet, color: Color(0xFFA50064), size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Thanh toán bằng MoMo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nhập số điện thoại MoMo để liên kết và thanh toán',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: 'Nhập số điện thoại',
            prefixIcon: const Icon(Icons.phone, color: AppTheme.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppTheme.bg,
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
              onPressed: () async {
                FocusScope.of(context).unfocus();
                final phone = _phoneController.text.isNotEmpty ? _phoneController.text : "0369313059";
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('momo_phone', phone);
                setState(() {
                  _linkedMoMoPhone = phone;
                  _step = 1;
                });
              },
              child: const Text('Tiếp tục', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConfirmSavedStep() {
    return Column(
      key: const ValueKey(2),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFA50064).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance_wallet, color: Color(0xFFA50064), size: 40),
        ),
        const SizedBox(height: 20),
        const Text(
          'Thanh toán qua MoMo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        Text(
          'Tài khoản đã liên kết: $_linkedMoMoPhone',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 15, fontWeight: FontWeight.w600),
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
            onPressed: () {
              setState(() => _step = 3);
            },
            child: const Text('Quét QR Thanh Toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('momo_phone');
            setState(() {
              _linkedMoMoPhone = null;
              _step = 0;
            });
          },
          child: const Text('Hủy liên kết tài khoản này', style: TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLoadingStep(String text, {required int valueKey}) {
    return Padding(
      key: ValueKey(valueKey),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFFA50064)),
          const SizedBox(height: 24),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark)),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      key: const ValueKey(4),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: AppTheme.primary, size: 60),
          ),
          const SizedBox(height: 20),
          const Text(
            'Thanh toán thành công!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Giao dịch của bạn đã được xử lý qua MoMo',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context); // Close bottom-sheet
                Navigator.pop(context); // Close payment screen
              },
              child: const Text('Hoàn tất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeStep() {
    return Column(
      key: ValueKey(_step), // 1 or 3 depending on flow
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Quét Mã Để Thanh Toán',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sử dụng App MoMo của bạn để quét mã này',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 16),
        
        // Display the user's uploaded MoMo Personal QR Code
        Flexible(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280, maxHeight: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/momo_qr.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
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
            onPressed: () {
              setState(() => _step = 4);
            },
            child: const Text('Tôi đã thanh toán thành công', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 8),
      ],
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
        decoration: const BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF0C8DB8).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance, color: Color(0xFF0C8DB8), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Nạp Tiền Qua VNPay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            const Text('Nhập số tiền bạn muốn nạp', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
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
                fillColor: AppTheme.bg,
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
