import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../../app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;
  const StatisticsScreen({super.key, required this.apiBaseUrl, required this.accessToken});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _overview = {};
  List<Map<String, dynamic>> _chartData = [];

  String? _selectedMetric;
  String _selectedPeriod = 'month';
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTime _selectedDate = DateTime.now();

  bool _isChartLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<_MetricInfo> _metrics = [
    _MetricInfo('total_users', 'Tổng người dùng', Icons.people, const Color(0xFF0EA5D8)),
    _MetricInfo('active_users', 'Đang hoạt động', Icons.eco, const Color(0xFF10B981)),
    _MetricInfo('locked_users', 'Đã bị khóa', Icons.lock_outline, const Color(0xFFEF4444)),
    _MetricInfo('total_designs', 'Thiết kế', Icons.design_services, const Color(0xFFF59E0B)),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchOverview();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchOverview() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/stats/overview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        setState(() {
          _overview = Map<String, dynamic>.from(data['stats']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchChartData(String metric) async {
    setState(() => _isChartLoading = true);

    final apiMetric = metric == 'total_users'
        ? 'users'
        : metric == 'active_users'
            ? 'active_users'
            : metric == 'locked_users'
                ? 'locked_users'
                : 'designs';

    try {
      final queryParams = {
        'metric': apiMetric,
        'period': _selectedPeriod,
        'year': _selectedYear.toString(),
        'month': _selectedMonth.toString(),
        'startDate': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      };

      final uri = Uri.parse('${widget.apiBaseUrl}/api/stats/chart').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        setState(() {
          _chartData = List<Map<String, dynamic>>.from(data['data']);
          _isChartLoading = false;
        });
        _animController.forward(from: 0);
      } else {
        setState(() => _isChartLoading = false);
      }
    } catch (e) {
      setState(() => _isChartLoading = false);
    }
  }

  void _onMetricTap(String metricKey) {
    setState(() {
      if (_selectedMetric == metricKey) {
        _selectedMetric = null;
        _chartData = [];
      } else {
        _selectedMetric = metricKey;
      }
    });
    if (_selectedMetric != null) {
      _fetchChartData(_selectedMetric!);
    }
  }

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    if (_selectedMetric != null) {
      _fetchChartData(_selectedMetric!);
    }
  }

  String _getOverviewValue(String key) {
    final val = _overview[key];
    if (val == null) return '0';
    final n = int.tryParse(val.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.bg,
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: theme.primary))
                : RefreshIndicator(
                    onRefresh: _fetchOverview,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildStatCard(_metrics[0])),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard(_metrics[1])),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildStatCard(_metrics[2])),
                              const SizedBox(width: 12),
                              Expanded(child: _buildStatCard(_metrics[3])),
                            ],
                          ),
                          if (_selectedMetric != null) ...[
                            const SizedBox(height: 24),
                            _buildPeriodFilter(),
                            const SizedBox(height: 12),
                            _buildDateSelector(),
                            const SizedBox(height: 16),
                            _buildChartSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_MetricInfo metric) {
    final theme = AppTheme.of(context);
    final isSelected = _selectedMetric == metric.key;
    return GestureDetector(
      onTap: () => _onMetricTap(metric.key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? metric.color.withValues(alpha: 0.08) : theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? metric.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: metric.color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
              : AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: metric.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(metric.icon, color: metric.color, size: 22),
                ),
                if (isSelected)
                  Icon(Icons.bar_chart_rounded, color: metric.color, size: 20),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _getOverviewValue(metric.key),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                color: isSelected ? metric.color : theme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.title,
              style: TextStyle(
                color: theme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    final theme = AppTheme.of(context);

    return Row(
      children: [
        Text('Lọc theo:', style: TextStyle(fontWeight: FontWeight.w700, color: theme.textDark, fontSize: 15)),
        const SizedBox(width: 12),
        _buildPeriodChip('day', 'Ngày'),
        const SizedBox(width: 8),
        _buildPeriodChip('month', 'Tháng'),
        const SizedBox(width: 8),
        _buildPeriodChip('year', 'Năm'),
      ],
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final theme = AppTheme.of(context);
    final isActive = _selectedPeriod == value;
    return GestureDetector(
      onTap: () => _onPeriodChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? theme.primaryGradient : null,
          color: isActive ? null : theme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : theme.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : theme.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final theme = AppTheme.of(context);
    final currentMetric = _metrics.firstWhere((m) => m.key == _selectedMetric);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: currentMetric.color),
          const SizedBox(width: 10),
          if (_selectedPeriod == 'day') ...[
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: ColorScheme.light(primary: currentMetric.color),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  if (_selectedMetric != null) _fetchChartData(_selectedMetric!);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: currentMetric.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: currentMetric.color, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: currentMetric.color, size: 18),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Year picker
            GestureDetector(
              onTap: () async {
                final years = List.generate(5, (i) => DateTime.now().year - i);
                final picked = await _showPickerDialog('Chọn năm', years.map((y) => y.toString()).toList());
                if (picked != null) {
                  setState(() => _selectedYear = int.parse(picked));
                  if (_selectedMetric != null) _fetchChartData(_selectedMetric!);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: currentMetric.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text('Năm $_selectedYear', style: TextStyle(fontWeight: FontWeight.w700, color: currentMetric.color, fontSize: 13)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: currentMetric.color, size: 18),
                  ],
                ),
              ),
            ),
            if (_selectedPeriod == 'month') ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () async {
                  final months = List.generate(12, (i) => (i + 1).toString());
                  final picked = await _showPickerDialog('Chọn tháng', months);
                  if (picked != null) {
                    setState(() => _selectedMonth = int.parse(picked));
                    if (_selectedMetric != null) _fetchChartData(_selectedMetric!);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: currentMetric.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text('Tháng $_selectedMonth', style: TextStyle(fontWeight: FontWeight.w700, color: currentMetric.color, fontSize: 13)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: currentMetric.color, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<String?> _showPickerDialog(String title, List<String> items) async {
    final theme = AppTheme.of(context);

    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: theme.textDark)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(items[i], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(ctx, items[i]),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    final theme = AppTheme.of(context);
    final currentMetric = _metrics.firstWhere((m) => m.key == _selectedMetric);

    if (_isChartLoading) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Center(child: CircularProgressIndicator(color: currentMetric.color)),
      );
    }

    if (_chartData.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: theme.textLight),
              SizedBox(height: 12),
              Text('Không có dữ liệu cho khoảng thời gian này', style: TextStyle(color: theme.textMuted, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_rounded, color: currentMetric.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  currentMetric.title,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: currentMetric.color),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: currentMetric.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedPeriod == 'day' ? '7 ngày' : _selectedPeriod == 'month' ? 'Tháng $_selectedMonth' : 'Năm $_selectedYear',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: currentMetric.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: _chartData.length <= 7
                  ? _buildBarChart(currentMetric)
                  : _buildLineChart(currentMetric),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(_MetricInfo metric) {
    final theme = AppTheme.of(context);
    final maxY = _chartData.fold<double>(0, (prev, e) => (e['value'] as int).toDouble() > prev ? (e['value'] as int).toDouble() : prev);
    final interval = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + interval,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: TextStyle(fontSize: 11, color: theme.textLight, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= _chartData.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatLabel(_chartData[idx]['label'].toString()),
                    style: TextStyle(fontSize: 10, color: theme.textMuted, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (val) => FlLine(color: theme.divider.withValues(alpha: 0.5), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _chartData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value['value'] as int).toDouble(),
                width: _chartData.length <= 4 ? 28 : 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [metric.color.withValues(alpha: 0.6), metric.color],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(_MetricInfo metric) {
    final theme = AppTheme.of(context);
    final maxY = _chartData.fold<double>(0, (prev, e) => (e['value'] as int).toDouble() > prev ? (e['value'] as int).toDouble() : prev);
    final interval = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble();
    final labelInterval = (_chartData.length / 6).ceil();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY + interval,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((s) => LineTooltipItem(
                    '${s.y.toInt()}',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  )).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: interval,
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: TextStyle(fontSize: 11, color: theme.textLight, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelInterval.toDouble(),
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= _chartData.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _formatLabel(_chartData[idx]['label'].toString()),
                    style: TextStyle(fontSize: 10, color: theme.textMuted, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (val) => FlLine(color: theme.divider.withValues(alpha: 0.5), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['value'] as int).toDouble())).toList(),
            isCurved: true,
            curveSmoothness: 0.3,
            color: metric.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: metric.color,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [metric.color.withValues(alpha: 0.25), metric.color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String raw) {
    if (_selectedPeriod == 'day') {
      // raw is date like 2026-03-18
      final parts = raw.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}';
      return raw;
    }
    if (_selectedPeriod == 'month') return 'Ng $raw';
    // year: month number
    final monthNames = ['', 'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12'];
    final idx = int.tryParse(raw);
    if (idx != null && idx >= 1 && idx <= 12) return monthNames[idx];
    return raw;
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: theme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5D8).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.analytics_outlined, color: Color(0xFF10B981), size: 32),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo & Thống kê',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Nhấn vào chỉ số để xem biểu đồ',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricInfo {
  final String key;
  final String title;
  final IconData icon;
  final Color color;
  const _MetricInfo(this.key, this.title, this.icon, this.color);
}
