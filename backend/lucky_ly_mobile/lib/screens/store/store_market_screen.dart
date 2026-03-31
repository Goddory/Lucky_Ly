import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../app_theme.dart';
import '../../widgets/custom_loading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_screen.dart';

class StoreMarketScreen extends StatefulWidget {
  const StoreMarketScreen({super.key});

  @override
  State<StoreMarketScreen> createState() => _StoreMarketScreenState();
}

class _StoreMarketScreenState extends State<StoreMarketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF952CB1);
  final Color secondaryColor = const Color(0xFFBE004C);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchMarketItems();
      context.read<StoreProvider>().fetchCart();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSticker(String? category) {
    if (category == null) return false;
    final l = category.toLowerCase();
    return l.contains('sticker') || l.contains('thiệp') || l.contains('hiệu ứng');
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final inventory = store.marketItems;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabs(),
          Expanded(
            child: store.isLoading
                ? const Center(child: CustomLoading(size: 60))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGrid(inventory.where((i) => _isSticker(i['category']?.toString())).toList(), 'Stickers'),
                      _buildGrid(inventory.where((i) => !_isSticker(i['category']?.toString())).toList(), 'Mô hình 3D'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Cửa hàng Lucky',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF45274B),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.shopping_bag_outlined, color: primaryColor, size: 28),
                if (context.watch<StoreProvider>().cartItems.isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFBE004C), shape: BoxShape.circle),
                      child: Text(
                        '${context.watch<StoreProvider>().cartItems.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF1A6FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: primaryColor,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Stickers'),
            Tab(text: 'Mô hình 3D'),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<dynamic> items, String emptyLabel) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 80, color: primaryColor.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text('Chưa có $emptyLabel nào', style: TextStyle(color: primaryColor.withOpacity(0.5))),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(dynamic item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1A6FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: item['assetUrl'] != null 
                        ? Image.network(item['assetUrl'], fit: BoxFit.contain)
                        : Icon(item['category'] == 'Sticker' ? Icons.emoji_emotions_outlined : Icons.view_in_ar, 
                               color: primaryColor.withOpacity(0.3), size: 40),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.favorite_border, color: primaryColor, size: 20),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['itemName'] ?? 'Vật phẩm mới',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['price']?.toString() ?? '0'} đ',
                      style: TextStyle(color: secondaryColor, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleAddToCart(context, item),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 14),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _handleAddToCart(BuildContext context, dynamic item) async {
    final storeProvider = context.read<StoreProvider>();
    final itemName = item['itemName'] ?? item['item_name'] ?? 'Vật phẩm này';
    final itemId = item['itemId'] ?? item['item_id'];
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang thêm vào giỏ hàng...'), duration: Duration(milliseconds: 600)),
    );

    final result = await storeProvider.addToCart(itemId);

    if (!context.mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm $itemName vào giỏ'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Thêm thất bại'), backgroundColor: Colors.red),
      );
    }
  }
}
