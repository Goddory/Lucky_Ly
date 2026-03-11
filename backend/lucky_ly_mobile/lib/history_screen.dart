import 'package:flutter/material.dart';

class _C {
  static const primary = Color(0xFF0EA5D8);
  static const accent = Color(0xFF19C6C4);
  static const bg = Color(0xFFF2F6FA);
  static const card = Colors.white;
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
}

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
    // Giả lập gọi API từ Database
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _transactions = []; // Xóa mock data, chuẩn bị nhận dữ liệu thật
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Lịch sử giao dịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _C.primary,
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
              ? const Center(child: CircularProgressIndicator(color: _C.primary))
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
          Icon(Icons.history_toggle_off, size: 80, color: _C.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Chưa có giao dịch nào', style: TextStyle(color: _C.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Giao dịch gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _C.textDark)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _C.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 16, color: _C.primary),
            const SizedBox(width: 4),
            Text(_filter, style: const TextStyle(color: _C.primary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    // Logic hiển thị item giao dịch khi có data thật
    return const SizedBox.shrink();
  }
}
