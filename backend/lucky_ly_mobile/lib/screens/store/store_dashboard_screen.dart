import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import 'inventory_screen.dart';
import 'revenue_screen.dart';
import 'combo_suggestion_screen.dart';

class StoreDashboardScreen extends StatefulWidget {
  const StoreDashboardScreen({super.key});

  @override
  State<StoreDashboardScreen> createState() => _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends State<StoreDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final overview = store.overview;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF5F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context),
                const SizedBox(height: 24),
                _buildHeroCard(overview),
                const SizedBox(height: 24),
                _buildBentoGrid(overview, context),
                const SizedBox(height: 24),
                _buildTrendingSection(overview), // Dynamic Trending
                const SizedBox(height: 24),
                _buildFeaturesSection(context),
                const SizedBox(height: 24),
                _buildDraftsSection(context, overview), // Dynamic Drafts
                const SizedBox(height: 24),
                _buildSchedulerSection(context, overview), // Dynamic Scheduler
                const SizedBox(height: 24),
                _buildPromoBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF8F2BAD)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Quản lý Cửa hàng',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8F2BAD),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Color(0xFF5E5B5D)),
              onPressed: () {},
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE37CFF).withOpacity(0.2),
              ),
              child: const Icon(Icons.person, color: Color(0xFF8F2BAD)),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildHeroCard(Map<String, dynamic>? overview) {
    final revenue = overview?['totalRevenue']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8F2BAD), Color(0xFFE37CFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F2BAD).withOpacity(0.15),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doanh thu',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '$revenue đ',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '+12% vs last month',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(Map<String, dynamic>? overview, BuildContext context) {
    final totalItems = overview?['totalItems']?.toString() ?? '0';
    final totalOrders = overview?['totalOrders']?.toString() ?? '0';
    final totalCombos = overview?['totalCombos']?.toString() ?? '0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSmallCard(totalItems, 'Sản phẩm', Icons.inventory_2, const Color(0xFFB70049), const Color(0xFFFFC2CA).withOpacity(0.3))),
            const SizedBox(width: 16),
            Expanded(child: _buildSmallCard(totalOrders, 'Đơn hàng', Icons.shopping_bag, const Color(0xFF652FE7), const Color(0xFFB8A3FF).withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComboSuggestionScreen())),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFF302E30).withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE37CFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Color(0xFF8F2BAD), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Gợi ý Combo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
                        const Text('Khám phá gợi ý thông minh', style: TextStyle(color: Color(0xFF5E5B5D), fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8F2BAD).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Color(0xFF8F2BAD)),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCard(String value, String label, IconData icon, Color iconColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF302E30).withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
          Text(label, style: const TextStyle(color: Color(0xFF5E5B5D), fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tính năng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
            TextButton(
              onPressed: () {},
              child: const Text('Xem tất cả', style: TextStyle(color: Color(0xFF8F2BAD), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildFeatureTile(
          'Kho vật phẩm', 'Quản lý tồn kho và nhập hàng', Icons.inventory, const Color(0xFF8F2BAD), false,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen())),
        ),
        const SizedBox(height: 12),
        _buildFeatureTile(
          'Doanh thu & Biểu đồ', 'Theo dõi tăng trưởng kinh doanh', Icons.bar_chart_rounded, const Color(0xFFB70049), false,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueScreen())),
        ),
        const SizedBox(height: 12),
        _buildFeatureTile(
          'Gợi ý Combo', 'Tăng doanh số với gợi ý thông minh', Icons.psychology, const Color(0xFF8F2BAD), true,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComboSuggestionScreen())),
        ),
      ],
    );
  }

  Widget _buildFeatureTile(String title, String subtitle, IconData icon, Color iconColor, bool isSmart, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5EFF2),
          borderRadius: BorderRadius.circular(16),
          border: isSmart ? Border.all(color: const Color(0xFFE37CFF).withOpacity(0.2), width: 2) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isSmart) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE37CFF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Smart', style: TextStyle(color: Color(0xFF47005B), fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF5E5B5D), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB0ACAF)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(Map<String, dynamic>? overview) {
    final hotItem = overview?['hotItem'];
    final suggestion = overview?['creativeSuggestion'];

    return Row(
      children: [
        Expanded(
          child: _buildTrendCard(
            'Hot nhất tuần',
            hotItem?['name'] ?? 'Đang tính toán...',
            '${hotItem?['count'] ?? 0} lượt dùng',
            const Color(0xFFB70049),
            const Color(0xFFFFC2CA).withOpacity(0.3),
            Icons.local_fire_department,
            onTap: () => _showSmartDetail(context, 'Thống kê Sản phẩm Hot', 'Sản phẩm "${hotItem?['name']}" đang được lồng vào quà tặng nhiều nhất trong 7 ngày qua.'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTrendCard(
            'Gợi ý Sáng tạo',
            suggestion?['title'] ?? 'Chủ đề mới',
            suggestion?['sub'] ?? 'Khám phá ngay',
            const Color(0xFF8F2BAD),
            const Color(0xFFE37CFF).withOpacity(0.2),
            Icons.tips_and_updates,
            onTap: () => _showSmartDetail(context, 'Gợi ý Xu hướng', 'Phong cách "${suggestion?['title']}" đang có lượng tìm kiếm tăng vọt 200%. Hãy sáng tạo thêm nội dung này!'),
          ),
        ),
      ],
    );
  }

  void _showSmartDetail(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8F2BAD))),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String title, String main, String sub, Color color, Color bgColor, IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: const Color(0xFF302E30).withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF797678))),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(main, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF302E30), overflow: TextOverflow.ellipsis)),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsSection(BuildContext context, Map<String, dynamic>? overview) {
    final drafts = overview?['drafts'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vật phẩm đang chờ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: drafts.length,
            itemBuilder: (ctx, index) {
              final draft = drafts[index];
              IconData iconData = Icons.brush;
              if (draft['icon'] == 'edit_note') iconData = Icons.edit_note;
              if (draft['icon'] == 'view_in_ar') iconData = Icons.view_in_ar;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildDraftCard(
                  draft['name'], 
                  draft['progress'], 
                  iconData,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đang mở bản nháp: ${draft['name']}...'))
                    );
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryScreen()));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDraftCard(String name, String progress, IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECE6EA)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFBF5F8), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF8F2BAD), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                  Text(progress, style: const TextStyle(fontSize: 11, color: Color(0xFF8F2BAD), fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedulerSection(BuildContext context, Map<String, dynamic>? overview) {
    final schedules = overview?['schedules'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lịch đăng bài', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans')),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF5F8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8F2BAD).withOpacity(0.1)),
          ),
          child: Column(
            children: schedules.asMap().entries.map((entry) {
              final idx = entry.key;
              final schedule = entry.value;
              return Column(
                children: [
                  _buildScheduleItem(
                    schedule['title'], 
                    schedule['date'], 
                    schedule['isNear'],
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF8F2BAD),
                          content: Text('Sự kiện "${schedule['title']}" diễn ra vào ${schedule['date']}'),
                        ),
                      );
                    },
                  ),
                  if (idx < schedules.length - 1)
                    const Divider(height: 32, color: Color(0xFFECE6EA)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(String title, String date, bool isNear, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isNear ? const Color(0xFF8F2BAD) : const Color(0xFFECE6EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.calendar_month, color: isNear ? Colors.white : const Color(0xFF797678), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(date, style: TextStyle(fontSize: 12, color: isNear ? const Color(0xFFB70049) : const Color(0xFF797678), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (isNear)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFC2CA).withOpacity(0.5), borderRadius: BorderRadius.circular(10)),
              child: const Text('SẮP TỚI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB70049))),
            ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C0055),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nâng cấp Cửa hàng', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Mở khóa thêm các tính năng phân tích chuyên sâu.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F2BAD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                    shadowColor: const Color(0xFF8F2BAD).withOpacity(0.5),
                  ),
                  child: const Text('Nâng cấp ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: const Icon(Icons.rocket_launch, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}
