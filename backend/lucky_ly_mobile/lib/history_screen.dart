import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'app_theme.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'Gần nhất';
  bool _isLoading = true;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final response = await authProvider.apiClient.get('/api/payment/history');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _transactions = data is List
                ? data
                : (data['data'] ?? data['transactions'] ?? []);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.of(context).bg,
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppTheme.of(context).primaryGradient)),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading 
              ? Center(child: const CustomLoading(size: 80))
              : _transactions.isEmpty 
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      return _buildTransactionItem(tx);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CustomLoading(size: 100),
          const SizedBox(height: 24),
          Text('Chưa có giao dịch nào', style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Giao dịch gần đây', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.of(context).textDark, letterSpacing: -0.5)),
          _buildFilterChip(),
        ],
      ),
    );
  }

  Widget _buildFilterChip() {
    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => _filter = val),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Gần nhất', child: Text('Gần nhất')),
        const PopupMenuItem(value: 'Xa nhất', child: Text('Xa nhất')),
        const PopupMenuItem(value: 'Tháng này', child: Text('Tháng này')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.of(context).primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.of(context).primary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.filter_list, size: 16, color: AppTheme.of(context).primary),
            const SizedBox(width: 6),
            Text(_filter, style: TextStyle(color: AppTheme.of(context).primary, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    bool isMinus = tx['tx_type'] == 'withdraw' ||
      tx['tx_type'] == 'purchase' ||
      tx['tx_type'] == 'transfer' ||
      tx['tx_type'] == 'gift_sent';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.of(context).primary.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (isMinus ? Colors.red : Colors.green).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(isMinus ? Icons.arrow_outward : Icons.south_west, color: isMinus ? Colors.red : Colors.green),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['note']?.isNotEmpty == true ? tx['note'] : (tx['tx_type']?.toUpperCase() ?? 'GIAO DỊCH'), style: TextStyle(color: AppTheme.of(context).textDark, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(tx['created_at'] != null ? tx['created_at'].split('T')[0] : '', style: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 13)),
              ],
            ),
          ),
          Text(
            '${isMinus ? '-' : '+'}${tx['amount']?.toString() ?? '0'}đ',
            style: TextStyle(color: isMinus ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
