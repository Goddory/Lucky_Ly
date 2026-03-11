import 'package:flutter/material.dart';

class _C {
  static const primary = Color(0xFF0EA5D8);
  static const accent = Color(0xFF19C6C4);
  static const bg = Color(0xFFF2F6FA);
  static const card = Colors.white;
  static const textDark = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
}

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  bool _isLoading = true;
  List<dynamic> _offers = [];

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _offers = []; // Xóa mock data
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text('Ưu đãi & Khuyến mãi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _C.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: _C.primary))
          : _offers.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _offers.length,
                  itemBuilder: (context, index) {
                    return _buildOfferCard(_offers[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 80, color: _C.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('Hiện chưa có ưu đãi nào dành cho bạn', style: TextStyle(color: _C.textMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOfferCard(dynamic o) {
    return const SizedBox.shrink();
  }
}
