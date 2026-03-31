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
  bool _isProcessing = false;

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

  double _calculateTotal(List<dynamic> cartItems) {
    double total = 0;
    for (var item in cartItems) {
      if (_selectedItemIds.contains(item['item_id'].toString())) {
        total += double.parse(item['price'].toString());
      }
    }
    return total;
  }

  void _checkout() async {
    if (_selectedItemIds.isEmpty) return;

    setState(() => _isProcessing = true);
    final provider = context.read<StoreProvider>();
    final result = await provider.checkoutCart(_selectedItemIds);
    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (result['success']) {
      setState(() => _selectedItemIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
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
                      padding: const EdgeInsets.only(bottom: 100, top: 12),
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
                                      '${item['price'].toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} đ',
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
              child: Row(
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
                      const Text('Tổng thanh toán:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        '${_calculateTotal(cartItems).toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} đ',
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
                  )
                ],
              ),
            )
          : null,
    );
  }
}
