import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';

class ComboSuggestionScreen extends StatefulWidget {
  const ComboSuggestionScreen({super.key});

  @override
  State<ComboSuggestionScreen> createState() => _ComboSuggestionScreenState();
}

class _ComboSuggestionScreenState extends State<ComboSuggestionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchCombos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final combos = store.combos;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF5F8),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildGlassAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(context, store),
                      const SizedBox(height: 40),
                      _buildListHeader(combos.length),
                      const SizedBox(height: 24),
                      if (combos.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text('Chưa có gợi ý combo nào', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        _buildComboCards(combos),
                      const SizedBox(height: 48),
                      _buildAnalyticsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildGlassAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFFBF5F8).withOpacity(0.8),
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF8F2BAD)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Gợi ý Combo',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.bold,
          color: Color(0xFF8F2BAD),
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.auto_awesome, color: Color(0xFF8F2BAD)),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroSection(BuildContext context, StoreProvider store) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8F2BAD), Color(0xFFE37CFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F2BAD).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Apriori Smart Analysis',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Khám phá thói quen mua sắm ẩn giấu và tối đa doanh thu với phân tích dữ liệu thông minh.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _runAnalysis(context, store),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8F2BAD),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                ),
                child: const Text('Phân tích ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _runAnalysis(BuildContext context, StoreProvider store) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFF8F2BAD))),
    );
    await store.runApriori();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildListHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          'Danh sách đề xuất',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF302E30)),
        ),
        Text(
          '$count KẾT QUẢ',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF797678), letterSpacing: 1.5),
        ),
      ],
    );
  }

  Widget _buildComboCards(List<dynamic> combos) {
    return Column(
      children: combos.asMap().entries.map((entry) {
        final i = entry.key;
        final combo = entry.value;
        final List<dynamic> items = combo['items'] ?? [];
        final confidence = double.tryParse(combo['confidence']?.toString() ?? '0') ?? 0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ComboCard(
            comboNumber: (i + 1).toString().padLeft(2, '0'),
            tagType: confidence > 0.8 ? 'Đánh giá cao' : 'Khuyên dùng',
            confidence: '${(confidence * 100).toStringAsFixed(0)}%',
            items: items.map((e) => e.toString()).toList(),
            growth: '+${(confidence * 30).toStringAsFixed(0)}%', // Giả lập mức độ tăng trưởng
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnalyticsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFF2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tại sao chọn các combo này?',
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF302E30)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hệ thống thu thập dữ liệu giao dịch lịch sử để dự đoán cơ hội bán thêm (upsell) tốt nhất cho gian hàng của bạn.',
            style: TextStyle(color: Color(0xFF5E5B5D), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildStatBox('ĐỘ CHÍNH XÁC', '99.2%', const Color(0xFF8F2BAD))),
              const SizedBox(width: 16),
              Expanded(child: _buildStatBox('ĐỘ NÂNG CAO', '3.4x', const Color(0xFFB70049))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF797678), letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.w800, color: valueColor)),
        ],
      ),
    );
  }

}

class ComboCard extends StatelessWidget {
  final String comboNumber;
  final String tagType;
  final String confidence;
  final List<String> items;
  final String growth;

  const ComboCard({
    super.key,
    required this.comboNumber,
    required this.tagType,
    required this.confidence,
    required this.items,
    required this.growth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E1E5).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF302E30).withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Combo Gợi ý #$comboNumber', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFB70049), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(tagType.toUpperCase(), style: const TextStyle(color: Color(0xFFB70049), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    ],
                  )
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF8F2BAD).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('Tin cậy: $confidence', style: const TextStyle(color: Color(0xFF8F2BAD), fontSize: 12, fontWeight: FontWeight.w900)),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          _buildItemRow(),
          const SizedBox(height: 24),
          
          const Divider(color: Color(0xFFE1DBDF), height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('POTENTIAL GROWTH', style: TextStyle(color: Color(0xFF797678), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(growth, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Color(0xFF8F2BAD), fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8F2BAD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 2,
                ),
                child: const Text('Tạo Combo', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildItemRow() {
    return LayoutBuilder(builder: (context, constraints) {
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 16,
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final name = entry.value;
          
          return IntrinsicWidth(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMiniItem(name),
                if (i < items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.add, color: Color(0xFF8F2BAD), size: 16),
                  ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildMiniItem(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8F2BAD).withOpacity(0.1)),
      ),
      child: Text(
        name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF302E30)),
        textAlign: TextAlign.center,
      ),
    );
  }
}
