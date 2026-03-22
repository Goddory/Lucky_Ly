import 'package:flutter/material.dart';
import '../../data/gift_catalog.dart';
import '../../app_theme.dart';
import 'gift_preview_screen.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ThemedGiftBuilderScreen extends StatefulWidget {
  const ThemedGiftBuilderScreen({super.key, required this.theme});
  final String theme; // 'tet' or 'valentine'

  @override
  State<ThemedGiftBuilderScreen> createState() => _ThemedGiftBuilderScreenState();
}

class _ThemedGiftBuilderScreenState extends State<ThemedGiftBuilderScreen>
    with SingleTickerProviderStateMixin {
  late final List<GiftModel> _models;
  late final List<GiftSticker> _stickers;
  int _selectedModelIndex = 0;
  final List<_PlacedSticker> _placedStickers = [];
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _models = GiftCatalog.getModels(widget.theme);
    _stickers = GiftCatalog.getStickers(widget.theme);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Color get _themeColor =>
      widget.theme == 'tet' ? const Color(0xFFc0392b) : const Color(0xFFe84393);
  Color get _themeAccent =>
      widget.theme == 'tet' ? const Color(0xFFf39c12) : const Color(0xFF9b59b6);
  LinearGradient get _themeGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: widget.theme == 'tet'
            ? [const Color(0xFFe74c3c), const Color(0xFFc0392b)]
            : [const Color(0xFFfd79a8), const Color(0xFFe84393)],
      );

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.of(context);
    return Scaffold(
      backgroundColor: appTheme.bg,
      appBar: AppBar(
        title: Text(
          widget.theme == 'tet' ? 'Quà Tết' : 'Quà Valentine',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: _themeGradient)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Chọn mẫu quà 3D', Icons.view_in_ar),
                  const SizedBox(height: 12),
                  _buildModelCarousel(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Thêm sticker', Icons.auto_awesome),
                  const SizedBox(height: 12),
                  _buildStickerGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Khu vực thiết kế', Icons.dashboard_customize),
                  const SizedBox(height: 12),
                  _buildDesignArea(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Lời nhắn', Icons.message_outlined),
                  const SizedBox(height: 12),
                  _buildMessageInput(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _themeColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.of(context).textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildModelCarousel() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _models.length,
        itemBuilder: (context, index) {
          final model = _models[index];
          final isSelected = index == _selectedModelIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedModelIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 120,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? _themeColor.withValues(alpha: 0.1) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? _themeColor : Colors.grey.shade200,
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: _themeColor.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))]
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: isSelected ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _themeAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForModel(model.thumbnailIcon),
                        color: _themeColor,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      model.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.of(context).textDark,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 4),
                    Container(
                      width: 20, height: 3,
                      decoration: BoxDecoration(
                        color: _themeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickerGrid() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _stickers.length,
        itemBuilder: (context, index) {
          final sticker = _stickers[index];
          return Draggable<GiftSticker>(
            data: sticker,
            feedback: Material(
              color: Colors.transparent,
              child: _buildStickerThumb(sticker, size: 60, dragging: true),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildStickerThumb(sticker),
            ),
            child: _buildStickerThumb(sticker),
          );
        },
      ),
    );
  }

  Widget _buildStickerThumb(GiftSticker sticker, {double size = 56, bool dragging = false}) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _themeColor.withValues(alpha: 0.15)),
        boxShadow: dragging
            ? [BoxShadow(color: _themeColor.withValues(alpha: 0.3), blurRadius: 12)]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            sticker.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.auto_awesome, color: _themeColor, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignArea() {
    return DragTarget<GiftSticker>(
      onAcceptWithDetails: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localOffset = box.globalToLocal(details.offset);
        setState(() {
          _placedStickers.add(_PlacedSticker(
            sticker: details.data,
            x: localOffset.dx.clamp(0, 300),
            y: localOffset.dy.clamp(0, 200),
          ));
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.theme == 'tet'
                  ? [const Color(0xFFFFF5F5), const Color(0xFFFEF3E2)]
                  : [const Color(0xFFFFF0F6), const Color(0xFFF8F0FC)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovering ? _themeColor : _themeColor.withValues(alpha: 0.15),
              width: isHovering ? 2.5 : 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Stack(
            children: [
              // Main gift preview
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: ModelViewer(
                        key: ValueKey(_models[_selectedModelIndex].id),
                        src: _models[_selectedModelIndex].assetPath,
                        alt: _models[_selectedModelIndex].name,
                        autoRotate: true,
                        cameraControls: true,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _models[_selectedModelIndex].name,
                      style: TextStyle(
                        color: AppTheme.of(context).textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Placed stickers
              ..._placedStickers.asMap().entries.map((entry) {
                final idx = entry.key;
                final placed = entry.value;
                return Positioned(
                  left: placed.x.clamp(0, 260),
                  top: placed.y.clamp(0, 190),
                  child: GestureDetector(
                    onTap: () => setState(() => _placedStickers.removeAt(idx)),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: 44, height: 44,
                          child: Image.asset(
                            placed.sticker.assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.auto_awesome, color: _themeColor, size: 20),
                          ),
                        ),
                        Positioned(
                          top: -6, right: -6,
                          child: Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Icon(Icons.close, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // Hint for drag
              if (_placedStickers.isEmpty && !isHovering)
                Positioned(
                  bottom: 12, left: 0, right: 0,
                  child: Text(
                    'Kéo sticker vào đây để trang trí',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.of(context).textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _themeColor.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: _messageController,
        maxLines: 3,
        maxLength: 200,
        style: TextStyle(color: AppTheme.of(context).textDark, fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.theme == 'tet'
              ? 'Chúc mừng năm mới! 🎉'
              : 'Gửi lời yêu thương... 💕',
          hintStyle: TextStyle(color: AppTheme.of(context).textLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterStyle: TextStyle(color: AppTheme.of(context).textMuted, fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _placedStickers.clear());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Đặt lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _themeColor,
                side: BorderSide(color: _themeColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GiftPreviewScreen(
                      theme: widget.theme,
                      model: _models[_selectedModelIndex],
                      stickers: _placedStickers
                          .map((s) => {'id': s.sticker.id, 'x': s.x, 'y': s.y})
                          .toList(),
                      message: _messageController.text.trim(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Xem trước & Gửi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForModel(String iconName) {
    switch (iconName) {
      case 'redeem': return Icons.redeem;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'local_florist': return Icons.local_florist;
      case 'pets': return Icons.pets;
      case 'emoji_events': return Icons.emoji_events;
      case 'favorite': return Icons.favorite;
      case 'smart_toy': return Icons.smart_toy;
      case 'cake': return Icons.cake;
      default: return Icons.card_giftcard;
    }
  }
}

class _PlacedSticker {
  final GiftSticker sticker;
  final double x;
  final double y;

  _PlacedSticker({required this.sticker, required this.x, required this.y});
}
