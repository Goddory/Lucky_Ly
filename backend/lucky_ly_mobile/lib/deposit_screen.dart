import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'app_theme.dart';

// Lưu 1 giao dịch nạp tiền ảo vào SharedPreferences
Future<void> saveLocalTransaction({
  required String type,
  required int amount,
  required String status,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('local_transactions') ?? '[]';
  final List<dynamic> list = jsonDecode(raw);
  list.insert(0, {
    'type': type,
    'amount': amount,
    'status': status,
    'createdAt': DateTime.now().toIso8601String(),
  });
  // Giữ tối đa 50 giao dịch gần nhất
  final trimmed = list.take(50).toList();
  await prefs.setString('local_transactions', jsonEncode(trimmed));
}

// Lấy danh sách giao dịch ảo
Future<List<Map<String, dynamic>>> getLocalTransactions() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('local_transactions') ?? '[]';
  final List<dynamic> list = jsonDecode(raw);
  return list.cast<Map<String, dynamic>>();
}

class DepositScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;
  const DepositScreen({
    super.key, 
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  Map<String, dynamic>? _userProfile;

  final List<int> _quickAmounts = [10000, 20000, 50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/users/me'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() => _userProfile = body['user']);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  @override
  void dispose() {

    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${buffer.toString()}đ';
  }

  Future<void> _createPaymentLink() async {
    final raw = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = int.tryParse(raw);

    if (amount == null || amount < 1000) {
      setState(() => _errorMsg = 'Số tiền nạp phải từ 1.000đ trở lên');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final token = widget.accessToken;

      if (token.isEmpty) {
        setState(() => _errorMsg = 'Vui lòng đăng nhập lại');
        return;
      }

      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/payment/create-payment-link'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount}),
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        final checkoutUrl = body['data']['checkoutUrl'] as String;
        final orderCode = body['data']['orderCode'] as int;

        // Lưu giao dịch ảo trạng thái 'pending'
        await saveLocalTransaction(
          type: 'deposit',
          amount: amount,
          status: 'pending',
        );

        if (mounted) {
          final uri = Uri.parse(checkoutUrl);
          
          if (kIsWeb) {
            // Trên Web: Luôn mở tab mới (externalApplication)
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            _showVerifyDialog(orderCode, amount);
            return;
          }

          // Trên Mobile: Thử mở ứng dụng bên ngoài (app ngân hàng) trước
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (launched) {
            // Nếu đã mở app ngân hàng thành công, khi người dùng quay lại app sẽ thấy nút xác nhận
            _showVerifyDialog(orderCode, amount);
          } else if (mounted) {
            // Nếu không mở được bên ngoài, dùng WebView
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PayOSWebViewScreen(
                  url: checkoutUrl,
                  amount: amount,
                  orderCode: orderCode, // Thêm orderCode
                  apiBaseUrl: widget.apiBaseUrl,
                  accessToken: widget.accessToken,
                ),
              ),
            );
          }
        }
      } else {
        setState(() => _errorMsg = body['message']?.toString() ?? 'Không tạo được link thanh toán');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Dialog để người dùng chủ động bấm "Tôi đã thanh toán" sau khi ứng dụng ngân hàng đóng
  void _showVerifyDialog(int orderCode, int amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận thanh toán'),
        content: const Text('Sau khi bạn đã hoàn tất giao dịch trên ứng dụng ngân hàng, vui lòng nhấn nút dưới đây để cập nhập số dư.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Quay lại', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _checkPaymentStatusFinal(orderCode, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tôi đã thanh toán', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Gọi API Backend để kiểm tra trạng thái thực tế của orderCode
  Future<void> _checkPaymentStatusFinal(int orderCode, int amount) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/payment/check-status/$orderCode'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final status = body['data']['status'];
        if (status == 'completed') {
          await _updateLocalStatusAndShowDialog(true, amount);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hệ thống chưa nhận được thanh toán. Bạn vui lòng đợi 1-2 phút rồi thử lại.')),
            );
          }
        }
      } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(body['message'] ?? 'Không tìm thấy thông tin giao dịch.')),
           );
         }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocalStatusAndShowDialog(bool success, int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('local_transactions') ?? '[]';
    final List<dynamic> list = jsonDecode(raw);
    for (int i = 0; i < list.length; i++) {
      if (list[i]['status'] == 'pending' && list[i]['amount'] == amount) {
        list[i]['status'] = success ? 'completed' : 'cancelled';
        break;
      }
    }
    await prefs.setString('local_transactions', jsonEncode(list));
    
    if (success) {
      _fetchUserProfile(); // Cập nhật lại số dư trên UI
    }

    if (mounted) {
      _showResultFeedback(success);
    }
  }

  void _showResultFeedback(bool success) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Thành công!' : 'Thất bại',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              success 
                ? 'Nạp tiền thành công. Số dư của bạn đã được cập nhật.' 
                : 'Đã có lỗi xảy ra hoặc giao dịch bị hủy.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nạp tiền',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.glowShadow(AppTheme.primary),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số dư khả dụng',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userProfile != null 
                            ? _formatCurrency((double.tryParse(_userProfile!['balance'].toString()) ?? 0).toInt())
                            : '...',
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 24, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Ô nhập số tiền
            const Text(
              'Số tiền muốn nạp',
              style: TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.softShadow,
                border: Border.all(
                  color: _errorMsg != null ? const Color(0xFFEF4444) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Text('₫', style: TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: AppTheme.textMuted),
                        border: InputBorder.none,
                      ),
                      onChanged: (_) => setState(() => _errorMsg = null),
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMsg!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],

            const SizedBox(height: 20),

            // Chọn nhanh số tiền
            const Text(
              'Chọn nhanh',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickAmounts.map((amt) {
                return GestureDetector(
                  onTap: () {
                    _amountController.text = amt.toString();
                    setState(() => _errorMsg = null);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Text(
                      _formatCurrency(amt),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

            // Nút tạo QR
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GestureDetector(
                      key: const ValueKey('btn_pay'),
                      onTap: _createPaymentLink,
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppTheme.glowShadow(AppTheme.primary),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code, color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'Tạo mã QR thanh toán',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Ghi chú
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sau khi quét mã QR và thanh toán thành công, lịch sử giao dịch sẽ được lưu ngay trên thiết bị.',
                      style: TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Màn hình WebView PayOS ──────────────────────────────────────
class PayOSWebViewScreen extends StatefulWidget {
  final String url;
  final int amount;
  final int orderCode;
  final String apiBaseUrl;
  final String accessToken;

  const PayOSWebViewScreen({
    super.key, 
    required this.url, 
    required this.amount,
    required this.orderCode,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<PayOSWebViewScreen> createState() => _PayOSWebViewScreenState();
}

class _PayOSWebViewScreenState extends State<PayOSWebViewScreen> {
  late final WebViewController _webController;
  bool _isPageLoading = true;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    // WebView Controller chỉ nên khởi tạo trên Mobile (Android/iOS)
    if (!kIsWeb) {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) => setState(() => _isPageLoading = true),
          onPageFinished: (_) => setState(() => _isPageLoading = false),
          onNavigationRequest: (request) {
            if (request.url.contains('/payment/success')) {
              _verifyWithServer(); // Kiểm tra với Server thay vì tin URL hoàn toàn
              return NavigationDecision.prevent;
            }
            if (request.url.contains('/payment/cancel')) {
              _handleResult(success: false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ))
        ..loadRequest(Uri.parse(widget.url));
    } else {
      _isPageLoading = false;
    }
  }

  Future<void> _verifyWithServer() async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);

    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/payment/check-status/${widget.orderCode}'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        if (body['data']['status'] == 'completed') {
          _handleResult(success: true);
          return;
        }
      }
      
      // Nếu chưa completed (có thể Webhook chậm), đợi 2s rồi thử lại
      await Future.delayed(const Duration(seconds: 2));
      _verifyWithServer();
    } catch (e) {
      _handleResult(success: false);
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _handleResult({required bool success}) async {
    // Cập nhật trạng thái giao dịch ảo trong SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('local_transactions') ?? '[]';
    final List<dynamic> list = jsonDecode(raw);
    // Cập nhật giao dịch pending đầu tiên thành completed/cancelled
    for (int i = 0; i < list.length; i++) {
      if (list[i]['status'] == 'pending' && list[i]['amount'] == widget.amount) {
        list[i]['status'] = success ? 'completed' : 'cancelled';
        break;
      }
    }
    await prefs.setString('local_transactions', jsonEncode(list));

    if (mounted) {
      _showResultDialog(success);
    }
  }

  void _showResultDialog(bool success) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: success ? const Color(0xFFE8FAF0) : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle : Icons.cancel,
                color: success ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              success ? 'Nạp tiền thành công!' : 'Giao dịch bị hủy',
              style: TextStyle(
                color: success ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (success) ...[
              const SizedBox(height: 8),
              Text(
                'Giao dịch đã được lưu vào lịch sử thiết bị.',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog
              Navigator.of(context).pop(); // Đóng WebView
              if (success) Navigator.of(context).pop(); // Về DepositScreen
            },
            child: Text(
              'Xong',
              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thanh toán PayOS',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          kIsWeb 
            ? const Center(child: Text('Vui lòng thanh toán ở tab mới vừa mở.'))
            : WebViewWidget(controller: _webController),
          if (_isPageLoading || _isCheckingStatus)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (_isCheckingStatus) ...[
                      const SizedBox(height: 16),
                      const Text('Đang xác nhận với hệ thống...', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

