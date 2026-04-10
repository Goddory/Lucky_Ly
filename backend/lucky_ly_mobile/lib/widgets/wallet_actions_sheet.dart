import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/api_client.dart';

// ─────────────────────────────────────────────────────────────────
// PUBLIC ENTRY POINTS
// ─────────────────────────────────────────────────────────────────

// Mở bottom sheet nạp tiền, dùng API base từ cấu hình hiện tại của app.
Future<void> showTopUpSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TopUpSheet(apiBaseUrl: ApiClient.getBaseUrl()),
  );
}

// Mở bottom sheet rút tiền về ngân hàng.
Future<void> showWithdrawSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _WithdrawSheet(apiBaseUrl: ApiClient.getBaseUrl()),
  );
}

// Mở bottom sheet chuyển tiền giữa các người dùng qua email.
Future<void> showTransferSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TransferSheet(apiBaseUrl: ApiClient.getBaseUrl()),
  );
}

// Mở bottom sheet admin để cộng tiền trực tiếp vào ví người dùng.
Future<void> showAdminAddMoneySheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AdminAddMoneySheet(apiBaseUrl: ApiClient.getBaseUrl()),
  );
}

// ─────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────
// Bảng màu dùng chung cho toàn bộ sheet để giữ giao diện đồng nhất.
const _kPrimary = Color(0xFF952CB1);
const _kPink = Color(0xFFBE004C);
const _kBg = Color(0xFFFFF7FB);
const _kTextDark = Color(0xFF45274B);
const _kTextMuted = Color(0xFF75547A);
const _kDivider = Color(0xFFE2E8F0);

// ─────────────────────────────────────────────────────────────────
// SHARED BOTTOM SHEET SHELL
// ─────────────────────────────────────────────────────────────────
// Khung layout dùng chung cho mọi sheet: handle, icon, tiêu đề và nội dung.
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    this.icon,
    this.assetPath,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData? icon;
  final String? assetPath;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Bottom inset giúp sheet không bị bàn phím che khuất.
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh kéo ở phía trên để người dùng nhận biết đây là bottom sheet.
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Icon hoặc ảnh đại diện cho từng loại thao tác.
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: assetPath != null
                  ? Center(child: Image.asset(assetPath!, width: 36, height: 36, fit: BoxFit.contain))
                  : Icon(icon, color: iconColor, size: 36),
            ),
            const SizedBox(height: 16),
            // Tiêu đề chính của sheet.
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 4),
            // Dòng mô tả ngắn giải thích hành động.
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: _kTextMuted),
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// QUICK AMOUNT CHIPS
// ─────────────────────────────────────────────────────────────────
// Các nút chọn nhanh số tiền để nhập liệu nhanh hơn.
class _QuickAmountChips extends StatelessWidget {
  const _QuickAmountChips({
    required this.amounts,
    required this.onSelected,
  });

  final List<int> amounts;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      // Wrap cho phép chip tự xuống dòng khi màn hình hẹp.
      spacing: 8,
      runSpacing: 8,
      children: amounts.map((a) {
        // Hiển thị gọn: 50K, 100K, 1Tr...
        final label = a >= 1000000
            ? '${a ~/ 1000000}Tr'
            : '${a ~/ 1000}K';
        return GestureDetector(
          onTap: () => onSelected(a),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _kPrimary.withValues(alpha: 0.25)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: _kPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STYLED TEXT FIELD
// ─────────────────────────────────────────────────────────────────
// TextField có style thống nhất cho cả amount, email, note...
class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.hint,
    this.prefix,
    this.suffix,
    this.inputType,
    this.formatters,
  });

  final TextEditingController controller;
  final String hint;
  final Widget? prefix;
  final String? suffix;
  final TextInputType? inputType;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: formatters,
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: _kTextDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kDivider, fontWeight: FontWeight.normal, fontSize: 16),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: _kTextMuted, fontWeight: FontWeight.w600, fontSize: 14),
        prefixIcon: prefix,
        filled: true,
        fillColor: _kBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: _kPrimary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PRIMARY BUTTON
// ─────────────────────────────────────────────────────────────────
// Nút hành động chính dùng chung cho mọi sheet.
class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    this.color = _kPrimary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Button cao và rộng để dễ thao tác trên mobile.
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 1. NẠP TIỀN — chọn cổng thanh toán
// ─────────────────────────────────────────────────────────────────
// Bottom sheet nạp tiền, cho phép chọn cổng thanh toán và số tiền.
class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet({required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final _amountCtrl = TextEditingController(text: '50000');
  bool _isLoading = false;
  String _selectedGateway = 'momo';

  final _gateways = const [
    // Mỗi gateway gồm id, tên, màu và asset icon.
    _GatewayDef('momo', 'MoMo', Color(0xFFA50064), 'assets/ảnh icon Luckyly/Lucky_Ly/pay/momo.png'),
    _GatewayDef('vnpay', 'VNPay', Color(0xFF005BAA), 'assets/ảnh icon Luckyly/Lucky_Ly/pay/vnpay.png'),
    _GatewayDef('zalopay', 'ZaloPay', Color(0xFF0068FF), 'assets/ảnh icon Luckyly/Lucky_Ly/pay/zalo.png'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Chỉ giữ lại chữ số để tránh lỗi parse từ input người dùng.
    final amountText =
        _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Lấy token để gọi API thanh toán có xác thực.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ??
          prefs.getString('access_token');

      // Tạo payload theo cổng đang chọn.
      final path = '/api/payment/$_selectedGateway/create';
      final body = {
        'amount': int.parse(amountText),
        'orderInfo': 'Nap tien vao vi Lucky Ly',
      };
      // ZaloPay cần returnUrl để xử lý callback sau thanh toán.
      if (_selectedGateway == 'zalopay') {
        body['returnUrl'] = 'luckyly://payment/return';
      }

      // Gửi request tạo giao dịch thanh toán lên backend.
      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Nếu backend trả payUrl thì mở cổng thanh toán bằng app ngoài.
        final data = jsonDecode(response.body);
        final payUrl = data['payUrl'] as String?;
        if (payUrl != null) {
          final uri = Uri.parse(payUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (mounted) Navigator.pop(context);
          } else {
            _showErr('Không thể mở cổng thanh toán');
          }
        }
      } else {
        final err = jsonDecode(response.body);
        _showErr(err['message'] ?? 'Tạo thanh toán thất bại');
      }
    } catch (e) {
      _showErr('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    // Dựng UI nạp tiền dựa trên shell dùng chung.
    return _SheetShell(
      assetPath: 'assets/ảnh icon Luckyly/Lucky_Ly/trang_chu/nạp tiền.png',
      iconColor: _kPrimary,
      title: 'Nạp tiền vào ví',
      subtitle: 'Chọn cổng thanh toán và nhập số tiền',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chọn cổng thanh toán.
          Row(
            children: _gateways.map((g) {
              final isSelected = _selectedGateway == g.id;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selectedGateway = g.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? g.color.withValues(alpha: 0.12)
                          : _kBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? g.color
                            : _kDivider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        ColorFiltered(
                          colorFilter: isSelected
                              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                              : const ColorFilter.matrix(<double>[
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0,      0,      0,      1, 0,
                                ]),
                          child: Image.asset(
                            g.assetPath,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          g.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? g.color
                                : _kTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Các mốc số tiền nạp nhanh.
          _QuickAmountChips(
            amounts: const [
              50000, 100000, 200000, 500000, 1000000
            ],
            onSelected: (v) =>
                _amountCtrl.text = v.toString(),
          ),

          const SizedBox(height: 16),

          // Ô nhập số tiền chính.
          _StyledField(
            controller: _amountCtrl,
            hint: 'Nhập số tiền',
            suffix: 'VNĐ',
            inputType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),

          const SizedBox(height: 24),

          _PrimaryBtn(
            label: 'Nạp tiền ngay',
            onPressed: _submit,
            isLoading: _isLoading,
            color: _gateways
                .firstWhere((g) => g.id == _selectedGateway)
                .color,
          ),
        ],
      ),
    );
  }
}

class _GatewayDef {
  final String id;
  final String name;
  final Color color;
  final String assetPath;

  const _GatewayDef(this.id, this.name, this.color, this.assetPath);
}

// ─────────────────────────────────────────────────────────────────
// 2. RÚT TIỀN
// ─────────────────────────────────────────────────────────────────
// Bottom sheet rút tiền về ngân hàng.
class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountCtrl = TextEditingController(text: '100000');
  final _accountCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  String _selectedBank = 'VCB';
  bool _isLoading = false;

  static const _banks = [
    ('VCB', 'Vietcombank'),
    ('TCB', 'Techcombank'),
    ('ACB', 'ACB'),
    ('MB', 'MBBank'),
    ('VPB', 'VPBank'),
    ('BIDV', 'BIDV'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Bắt buộc phải có đủ số tiền, số tài khoản và tên chủ tài khoản.
    final amountText =
        _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty ||
        _accountCtrl.text.trim().isEmpty ||
        _accountNameCtrl.text.trim().isEmpty) {
      _showErr('Vui lòng điền đầy đủ thông tin');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gửi yêu cầu rút tiền lên backend.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ??
          prefs.getString('access_token');

      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/payment/wallet/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': int.parse(amountText),
          'bankCode': _selectedBank,
          'accountNumber': _accountCtrl.text.trim(),
          'accountName': _accountNameCtrl.text.trim(),
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Đóng sheet khi gửi yêu cầu thành công.
        Navigator.pop(context);
        _showSuccess(data['message'] ??
            'Yêu cầu rút tiền đã được ghi nhận');
      } else {
        _showErr(data['message'] ?? 'Rút tiền thất bại');
      }
    } catch (e) {
      _showErr('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    // Dựng UI rút tiền dựa trên shell dùng chung.
    return _SheetShell(
      assetPath: 'assets/ảnh icon Luckyly/Lucky_Ly/trang_chu/rút tiền.png',
      iconColor: _kPink,
      title: 'Rút tiền',
      subtitle: 'Rút về tài khoản ngân hàng của bạn',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Số tiền rút nhanh.
          _QuickAmountChips(
            amounts: const [100000, 200000, 500000, 1000000, 2000000],
            onSelected: (v) => _amountCtrl.text = v.toString(),
          ),
          const SizedBox(height: 16),

          // Ô nhập số tiền.
          _StyledField(
            controller: _amountCtrl,
            hint: 'Số tiền rút',
            suffix: 'VNĐ',
            inputType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),

          // Chọn ngân hàng nhận tiền.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBank,
                isExpanded: true,
                icon: const Icon(Icons.expand_more, color: _kPrimary),
                style: const TextStyle(
                    color: _kTextDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedBank = v);
                },
                items: _banks
                    .map((b) => DropdownMenuItem(
                          value: b.$1,
                          child: Text('${b.$1} — ${b.$2}'),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Số tài khoản.
          _StyledField(
            controller: _accountCtrl,
            hint: 'Số tài khoản',
            inputType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            prefix: const Icon(Icons.credit_card, color: _kPrimary, size: 20),
          ),
          const SizedBox(height: 12),

          // Tên chủ tài khoản.
          _StyledField(
            controller: _accountNameCtrl,
            hint: 'Tên chủ tài khoản (in hoa)',
            prefix: const Icon(Icons.person_outline, color: _kPrimary, size: 20),
          ),
          const SizedBox(height: 8),

          // Lưu ý thời gian xử lý.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kPink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: _kPink, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Yêu cầu rút tiền sẽ được xử lý trong 1-3 ngày làm việc.',
                    style: TextStyle(fontSize: 12, color: _kPink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _PrimaryBtn(
            label: 'Gửi yêu cầu rút tiền',
            onPressed: _submit,
            isLoading: _isLoading,
            color: _kPink,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 3. CHUYỂN TIỀN (PEER-TO-PEER)
// ─────────────────────────────────────────────────────────────────
// Bottom sheet chuyển tiền cho người dùng khác qua email.
class _TransferSheet extends StatefulWidget {
  const _TransferSheet({required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  final _emailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '10000');
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Cần email người nhận và số tiền hợp lệ.
    final email = _emailCtrl.text.trim();
    final amountText =
        _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (email.isEmpty || amountText.isEmpty) {
      _showErr('Vui lòng nhập email và số tiền');
      return;
    }

    // Confirm dialog
    // Hộp thoại xác nhận trước khi gửi tiền.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận chuyển tiền',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Chuyển ${int.parse(amountText).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}đ\nđến $email?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Xác nhận',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Gửi request chuyển tiền lên backend.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ??
          prefs.getString('access_token');

      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/payment/wallet/transfer'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'toEmail': email,
          'amount': int.parse(amountText),
          'note': _noteCtrl.text.trim(),
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Đóng sheet và báo thành công nếu backend xử lý OK.
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Chuyển tiền thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErr(data['message'] ?? 'Chuyển tiền thất bại');
      }
    } catch (e) {
      _showErr('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    // Dựng UI chuyển tiền dựa trên shell dùng chung.
    return _SheetShell(
      assetPath: 'assets/ảnh icon Luckyly/Lucky_Ly/trang_chu/chuyển tiền.png',
      iconColor: const Color(0xFF7C3AED),
      title: 'Chuyển tiền',
      subtitle: 'Chuyển tiền cho bạn bè qua email',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email người nhận.
          _StyledField(
            controller: _emailCtrl,
            hint: 'Email người nhận',
            inputType: TextInputType.emailAddress,
            prefix: const Icon(Icons.alternate_email,
                color: _kPrimary, size: 20),
          ),
          const SizedBox(height: 12),

          // Mốc tiền nhanh.
          _QuickAmountChips(
            amounts: const [10000, 20000, 50000, 100000, 200000],
            onSelected: (v) => _amountCtrl.text = v.toString(),
          ),
          const SizedBox(height: 12),

          // Số tiền chuyển.
          _StyledField(
            controller: _amountCtrl,
            hint: 'Số tiền',
            suffix: 'VNĐ',
            inputType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),

          // Nội dung chuyển tiền tùy chọn.
          _StyledField(
            controller: _noteCtrl,
            hint: 'Lời nhắn (tuỳ chọn)...',
            prefix: const Icon(Icons.sticky_note_2_outlined,
                color: _kPrimary, size: 20),
          ),
          const SizedBox(height: 20),

          _PrimaryBtn(
            label: 'Chuyển ngay',
            onPressed: _submit,
            isLoading: _isLoading,
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ADMIN: CỘNG TIỀN VÀO VÍ NGƯỜI DÙNG
// ─────────────────────────────────────────────────────────────────
// Bottom sheet riêng cho admin để cộng tiền vào ví người dùng.
class _AdminAddMoneySheet extends StatefulWidget {
  const _AdminAddMoneySheet({required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<_AdminAddMoneySheet> createState() => _AdminAddMoneySheetState();
}

class _AdminAddMoneySheetState extends State<_AdminAddMoneySheet> {
  final _emailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '100000');
  final _noteCtrl = TextEditingController(text: 'Hệ thống cộng tiền');
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Cần email người dùng và số tiền để thực hiện cộng tiền.
    final email = _emailCtrl.text.trim();
    final amountText = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (email.isEmpty || amountText.isEmpty) {
      _showErr('Vui lòng nhập email và số tiền');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận cộng tiền',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Cộng ${int.parse(amountText).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}đ\ncho tài khoản $email?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC0065B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Xác nhận',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Gửi request admin-add lên backend.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ??
          prefs.getString('access_token');

      final response = await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/payment/wallet/admin-add'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'toEmail': email,
          'amount': int.parse(amountText),
          'note': _noteCtrl.text.trim(),
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Đóng sheet sau khi thao tác thành công.
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Cộng tiền thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showErr(data['message'] ?? 'Cộng tiền thất bại');
      }
    } catch (e) {
      _showErr('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    // Dựng UI cộng tiền theo layout dùng chung.
    return _SheetShell(
      icon: Icons.account_balance_wallet,
      iconColor: const Color(0xFFC0065B),
      title: 'Quản trị: Cộng tiền',
      subtitle: 'Nạp tiền trực tiếp vào ví người dùng',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StyledField(
            controller: _emailCtrl,
            hint: 'Email người dùng',
            inputType: TextInputType.emailAddress,
            prefix: const Icon(Icons.alternate_email,
                color: Color(0xFFC0065B), size: 20),
          ),
          const SizedBox(height: 12),
          // Mốc tiền cộng nhanh.
          _QuickAmountChips(
            amounts: const [100000, 200000, 500000, 1000000, 5000000],
            onSelected: (v) => _amountCtrl.text = v.toString(),
          ),
          const SizedBox(height: 12),
          // Số tiền cộng vào ví.
          _StyledField(
            controller: _amountCtrl,
            hint: 'Số tiền nạp',
            suffix: 'VNĐ',
            inputType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          // Ghi chú lý do cộng tiền.
          _StyledField(
            controller: _noteCtrl,
            hint: 'Lý do/Ghi chú...',
            prefix: const Icon(Icons.sticky_note_2_outlined,
                color: Color(0xFFC0065B), size: 20),
          ),
          const SizedBox(height: 20),
          _PrimaryBtn(
            label: 'Xác nhận nạp tiền',
            onPressed: _submit,
            isLoading: _isLoading,
            color: const Color(0xFFC0065B),
          ),
        ],
      ),
    );
  }
}
