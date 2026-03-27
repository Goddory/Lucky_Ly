import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/store_provider.dart';
import '../../app_theme.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchRevenue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final store = context.watch<StoreProvider>();
    final data = store.revenueData;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Doanh thu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: theme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                style: TextStyle(color: theme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildChart(data, theme),
              const SizedBox(height: 32),
              Text(
                'Lịch sử giao dịch gần đây',
                style: TextStyle(color: theme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (data.isEmpty)
                const Center(child: Text('Chưa có dữ liệu giao dịch'))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length > 5 ? 5 : data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return _RevenueItemTile(item: item, theme: theme);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<dynamic> data, AppTheme theme) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text('Đang tải dữ liệu...')),
      );
    }

    final List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
        spots.add(FlSpot(i.toDouble(), double.parse(data[i]['amount'].toString())));
    }

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: theme.divider, strokeWidth: 1)),
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
                  // Show only some labels
                  if (data.length > 5 && v.toInt() % (data.length ~/ 3) != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'T${v.toInt() + 1}', // Placeholder for date
                      style: TextStyle(color: theme.textMuted, fontSize: 10),
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
              color: theme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.primary.withValues(alpha: 0.15),
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
  final AppTheme theme;

  const _RevenueItemTile({required this.item, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            child: const Icon(Icons.add, color: Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn hàng #${item['id']}',
                  style: TextStyle(color: theme.textDark, fontWeight: FontWeight.bold),
                ),
                Text(
                  item['created_at']?.toString().substring(0, 10) ?? '',
                  style: TextStyle(color: theme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '+${item['amount']}đ',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
