import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/store_provider.dart';
import '../../app_theme.dart';
import '../../widgets/custom_loading.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<String> _selectedItemIds = [];
  Map<String, dynamic>? _selectedPromotion;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<StoreProvider>();
      provider.fetchCart();
      provider.fetchAvailablePromotions();
    });
  }

  void _toggleSelection(String id, bool? value) {
    setState(() {
      if (value == true) {
        _selectedItemIds.add(id);
      } else {
        _selectedItemIds.remove(id);
      }
    });
  }

  void _toggleAll(bool? value, List<dynamic> cartItems) {
    setState(() {
      _selectedItemIds.clear();
      if (value == true) {
        _selectedItemIds.addAll(cartItems.map((e) => e['item_id'].toString()));
      }
    });
  }

  String _formatCurrency(num amount) {
    final integerAmount = amount.round();
    return integerAmount
        .toString()
        .replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => '${m[1]},');
  }

  String _getPromotionCode(Map<String, dynamic> promotion) {
    return (promotion['sample_voucher_code'] ?? '').toString().trim();
  }

  String _getPromotionDiscountLabel(Map<String, dynamic> promotion) {
    final discountType = (promotion['discount_type'] ?? '').toString().toLowerCase();
    final discountValue = num.tryParse(promotion['discount_value']?.toString() ?? '0') ?? 0;

    if (discountType == 'percent') {
      final suffix = discountValue % 1 == 0 ? 0 : 2;
      return 'Giảm ${discountValue.toStringAsFixed(suffix)}%';
    }

    return 'Giảm ${_formatCurrency(discountValue)} đ';
  }

  Map<String, dynamic>? _resolveSelectedPromotion(List<Map<String, dynamic>> promotions) {
    final selected = _selectedPromotion;
    if (selected == null) return null;

    final selectedCode = _getPromotionCode(selected).toUpperCase();
    if (selectedCode.isEmpty) return null;

    for (final promo in promotions) {
      final code = _getPromotionCode(promo).toUpperCase();
      if (code == selectedCode) {
        return promo;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selectedPromotion == null) return;
      setState(() {
        _selectedPromotion = null;
      });
    });

    return null;
  }

  double _calculateSubtotal(List<dynamic> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      if (_selectedItemIds.contains(item['item_id'].toString())) {
        total += double.parse(item['price'].toString());
      }
    }
    return total;
  }

  double _calculateDiscount(
    double subtotal,
    Map<String, dynamic>? promotion,
  ) {
    if (promotion == null || subtotal <= 0) return 0;

    final discountType = (promotion['discount_type'] ?? '').toString().toLowerCase();
    final discountValue = num.tryParse(promotion['discount_value']?.toString() ?? '0') ?? 0;
    if (discountValue <= 0) return 0;

    final rawDiscount = discountType == 'percent'
        ? (subtotal * discountValue / 100)
        : discountValue.toDouble();

    if (rawDiscount <= 0) return 0;
    return rawDiscount > subtotal ? subtotal : rawDiscount;
  }

  Future<void> _openPromotionPicker(StoreProvider provider) async {
    if (provider.isPromotionsLoading) return;

    final promotions = provider.availablePromotions;
    if (promotions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hiện chưa có mã giảm giá khả dụng')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final currentCode = _selectedPromotion == null
            ? ''
            : _getPromotionCode(_selectedPromotion!).toUpperCase();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Chọn mã giảm giá',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Không áp dụng mã'),
                  trailing: currentCode.isEmpty
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedPromotion = null;
                    });
                  },
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: promotions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final promo = promotions[index];
                      final code = _getPromotionCode(promo);
                      final isSelected = code.toUpperCase() == currentCode;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.local_offer_outlined,
                          color: isSelected ? Colors.green : Colors.grey.shade700,
                        ),
                        title: Text(
                          (promo['name'] ?? 'Mã ưu đãi').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${_getPromotionDiscountLabel(promo)} • $code',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedPromotion = promo;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _checkout() async {
    if (_selectedItemIds.isEmpty) return;

    setState(() => _isProcessing = true);
    final provider = context.read<StoreProvider>();
    final voucherCode = _selectedPromotion == null ? null : _getPromotionCode(_selectedPromotion!);
    final result = await provider.checkoutCart(_selectedItemIds, voucherCode: voucherCode);
    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result['success']) {
      final savedAmount = num.tryParse(result['discountAmount']?.toString() ?? '0') ?? 0;
      final appliedVoucher = result['appliedVoucher'] is Map
          ? Map<String, dynamic>.from(result['appliedVoucher'])
          : null;
      final appliedCode = (appliedVoucher?['code'] ?? '').toString();
      final successText = savedAmount > 0
          ? 'Thanh toán thành công. Tiết kiệm ${_formatCurrency(savedAmount)} đ${appliedCode.isNotEmpty ? ' với mã $appliedCode' : ''}.'
          : (result['message'] ?? 'Thanh toán thành công');

      setState(() {
        _selectedItemIds.clear();
        _selectedPromotion = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successText), backgroundColor: Colors.green),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thanh toán thất bại'),
          content: Text(result['message'] ?? 'Có lỗi xảy ra.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            )
          ],
        ),
      );
    }
  }

  void _removeItem(String itemId) async {
    setState(() => _isProcessing = true);
    await context.read<StoreProvider>().removeFromCart(itemId);
    setState(() {
      _selectedItemIds.remove(itemId);
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final storeProvider = context.watch<StoreProvider>();
    final cartItems = storeProvider.cartItems;
    final promotions = storeProvider.availablePromotions;
    final selectedPromotion = _resolveSelectedPromotion(promotions);
    final subtotal = _calculateSubtotal(cartItems);
    final discountAmount = _calculateDiscount(subtotal, selectedPromotion);
    final payableTotal = (subtotal - discountAmount).clamp(0, double.infinity).toDouble();
    final bool allSelected = cartItems.isNotEmpty && _selectedItemIds.length == cartItems.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Giỏ hàng (${cartItems.length})',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: theme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          storeProvider.isCartLoading
              ? const Center(child: CustomLoading(size: 80))
              : cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 80, color: theme.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('Giỏ hàng trống', style: TextStyle(color: theme.textMuted, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 180, top: 12),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final itemId = item['item_id'].toString();
                        final isSelected = _selectedItemIds.contains(itemId);

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                activeColor: theme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => _toggleSelection(itemId, val),
                              ),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: theme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: item['thumbnail_url'] != null
                                    ? Image.network(item['thumbnail_url'], fit: BoxFit.contain)
                                    : Icon(Icons.inventory_2_outlined, color: theme.primary.withOpacity(0.5), size: 40),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['item_name'] ?? 'Sản phẩm',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textDark),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_formatCurrency(num.tryParse(item['price']?.toString() ?? '0') ?? 0)} đ',
                                      style: TextStyle(color: theme.primary, fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeItem(itemId),
                              )
                            ],
                          ),
                        );
                      },
                    ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: const Center(child: CustomLoading(size: 80)),
            ),
        ],
      ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12, top: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _isProcessing ? null : () => _openPromotionPicker(storeProvider),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.primary.withOpacity(0.14)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer_outlined, color: theme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              storeProvider.isPromotionsLoading
                                  ? 'Đang tải mã giảm giá...'
                                  : selectedPromotion != null
                                      ? '${selectedPromotion['name']} (${_getPromotionCode(selectedPromotion)})'
                                      : 'Chọn mã giảm giá',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (selectedPromotion != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Đã áp mã',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                IconButton(
                                  icon: Icon(Icons.close, color: theme.textMuted, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _selectedPromotion = null;
                                    });
                                  },
                                ),
                              ],
                            )
                          else
                            Icon(Icons.chevron_right, color: theme.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: allSelected,
                        activeColor: theme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => _toggleAll(val, cartItems),
                      ),
                      const Text('Tất cả', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Tạm tính:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            '${_formatCurrency(subtotal)} đ',
                            style: TextStyle(color: theme.textMuted, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          if (discountAmount > 0)
                            Text(
                              '- ${_formatCurrency(discountAmount)} đ',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          Text(
                            '${_formatCurrency(payableTotal)} đ',
                            style: TextStyle(color: theme.primary, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _selectedItemIds.isEmpty || _isProcessing ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          disabledBackgroundColor: theme.primary.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: Text(
                          'Mua hàng (${_selectedItemIds.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
