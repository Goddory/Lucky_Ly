import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/store_provider.dart';
import '../../app_theme.dart';

class ComboSuggestionScreen extends StatefulWidget {
  const ComboSuggestionScreen({super.key});

  @override
  State<ComboSuggestionScreen> createState() => _ComboSuggestionScreenState();
}

class _ComboSuggestionScreenState extends State<ComboSuggestionScreen> {
  final softPinkBg = const Color(0xFFFFF0F3);
  final accentPink = const Color(0xFFFF758F);

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
      backgroundColor: softPinkBg,
      appBar: AppBar(
        title: Text('Gợi ý Combo', style: GoogleFonts.comfortaa(color: accentPink, fontWeight: FontWeight.w900)),
        backgroundColor: softPinkBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentPink),
      ),
      body: RefreshIndicator(
        onRefresh: () => store.fetchCombos(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(accentPink, store),
              const SizedBox(height: 32),
              Text(
                'Danh sách đề xuất',
                style: GoogleFonts.comfortaa(color: accentPink.withValues(alpha: 0.8), fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (combos.isEmpty)
                const _EmptyCombos()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: combos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final combo = combos[index];
                    return _ComboTile(combo: combo, accentPink: accentPink);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent, StoreProvider store) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded, color: Colors.white, size: 50),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Apriori',
                  style: GoogleFonts.comfortaa(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Phân tích hành vi mua để gợi ý quà tặng.',
                  style: GoogleFonts.beVietnamPro(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _runAnalysis(store),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text('Phân tích ngay', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _runAnalysis(StoreProvider store) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    await store.runApriori();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xử lý hoàn tất!')),
      );
    }
  }
}

class _ComboTile extends StatelessWidget {
  final Map<String, dynamic> combo;
  final Color accentPink;

  const _ComboTile({required this.combo, required this.accentPink});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = combo['items'] ?? [];
    final double confidenceValue = double.tryParse(combo['confidence']?.toString() ?? '0') ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                combo['name'] ?? 'Combo Gợi ý',
                style: GoogleFonts.comfortaa(color: const Color(0xFF2B2D42), fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: accentPink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  'Tin cậy: ${(confidenceValue * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.beVietnamPro(color: accentPink, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _MiniItemCard(name: items[i].toString(), accentPink: accentPink),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Icon(Icons.add_rounded, size: 18, color: accentPink.withValues(alpha: 0.3)),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniItemCard extends StatelessWidget {
  final String name;
  final Color accentPink;
  const _MiniItemCard({required this.name, required this.accentPink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accentPink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: accentPink.withValues(alpha: 0.1)),
      ),
      child: Text(name, style: GoogleFonts.beVietnamPro(color: const Color(0xFF2B2D42), fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyCombos extends StatelessWidget {
  const _EmptyCombos();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.auto_awesome_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Chưa có combo đề xuất.', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
