import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../app_theme.dart';

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
    final theme = AppTheme.of(context);
    final store = context.watch<StoreProvider>();
    final combos = store.combos;

    return Scaffold(
      backgroundColor: theme.bg,
      appBar: AppBar(
        title: const Text('Gợi ý Combo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: theme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => store.fetchCombos(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, store),
              const SizedBox(height: 24),
              Text(
                'Danh sách Combo đề xuất',
                style: TextStyle(color: theme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (combos.isEmpty)
                const _EmptyCombos()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: combos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final combo = combos[index];
                    return _ComboTile(combo: combo, theme: theme);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppTheme theme, StoreProvider store) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: theme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thuật toán Apriori',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Phân tích hành vi mua để gợi ý các cặp quà tặng đi kèm.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _runAnalysis(store),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Phân tích lại ngay', style: TextStyle(fontWeight: FontWeight.bold)),
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
  final AppTheme theme;

  const _ComboTile({required this.combo, required this.theme});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = combo['items'] ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                combo['name'] ?? 'Combo Gợi ý',
                style: TextStyle(color: theme.textDark, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'Tin cậy: ${((combo['confidence'] ?? 0) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: theme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _MiniItemCard(name: items[i].toString(), theme: theme),
                if (i < items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.add, size: 16, color: Colors.grey),
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
  final AppTheme theme;
  const _MiniItemCard({required this.name, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: theme.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.divider)),
      child: Text(name, style: TextStyle(color: theme.textDark, fontSize: 13, fontWeight: FontWeight.w500)),
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
