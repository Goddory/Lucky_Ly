import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/store_provider.dart';
import '../../app_theme.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  final softPinkBg = const Color(0xFFFFF0F3);
  final accentPink = const Color(0xFFFF758F);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchRevenue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final data = store.revenueData;

    return Scaffold(
      backgroundColor: softPinkBg,
      appBar: AppBar(
        title: Text('Doanh thu', style: GoogleFonts.comfortaa(color: accentPink, fontWeight: FontWeight.w900)),
        backgroundColor: softPinkBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentPink),
      ),
      body: RefreshIndicator(
        onRefresh: () => store.fetchRevenue(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biểu đồ tăng trưởng',
                style: GoogleFonts.comfortaa(color: accentPink.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _buildChart(data, accentPink),
              const SizedBox(height: 32),
              Text(
                'Lịch sử giao dịch',
                style: GoogleFonts.comfortaa(color: accentPink.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (data.isEmpty)
                Center(child: Text('Chưa có dữ liệu giao dịch', style: GoogleFonts.beVietnamPro(color: Colors.grey)))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length > 5 ? 5 : data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return _RevenueItemTile(item: item, accentPink: accentPink);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<dynamic> data, Color accent) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Center(child: Text('Đang tải dữ liệu...', style: GoogleFonts.beVietnamPro())),
      );
    }

    final List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
        spots.add(FlSpot(i.toDouble(), double.parse(data[i]['amount'].toString())));
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: accent.withValues(alpha: 0.05), strokeWidth: 1)),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  if (v.toInt() >= data.length) return const SizedBox.shrink();
                  if (data.length > 5 && v.toInt() % (data.length ~/ 3) != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'T${v.toInt() + 1}',
                      style: GoogleFonts.beVietnamPro(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: accent,
              barWidth: 6,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color accentPink;

  const _RevenueItemTile({required this.item, required this.accentPink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE9FFEF), shape: BoxShape.circle),
            child: const Icon(Icons.add_rounded, color: Color(0xFF2ECC71), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn hàng #${item['id']}',
                  style: GoogleFonts.comfortaa(color: const Color(0xFF2B2D42), fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  item['created_at']?.toString().substring(0, 10) ?? '',
                  style: GoogleFonts.beVietnamPro(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            '+${item['amount']}đ',
            style: GoogleFonts.comfortaa(color: const Color(0xFF2ECC71), fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
