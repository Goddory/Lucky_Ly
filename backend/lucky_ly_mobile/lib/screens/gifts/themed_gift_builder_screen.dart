import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../data/gift_catalog.dart';
import '../../app_theme.dart';
import 'gift_preview_screen.dart';
import '../../widgets/glb_model_viewer.dart';

class ThemedGiftBuilderScreen extends StatefulWidget {
  const ThemedGiftBuilderScreen({super.key, required this.theme});
  final String theme; // 'tet' or 'valentine'

  @override
  State<ThemedGiftBuilderScreen> createState() =>
      _ThemedGiftBuilderScreenState();
}

class _ThemedGiftBuilderScreenState extends State<ThemedGiftBuilderScreen>
    with SingleTickerProviderStateMixin {
  late final List<GiftModel> _models;
  late final List<GiftSticker> _stickers;
  int _selectedModelIndex = 0;
  final List<_PlacedSticker> _placedStickers = [];
  final Map<int, _StickerGestureState> _gestureStates = {};
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();
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
    _cashController.dispose();
    super.dispose();
  }

  Color get _themeColor => const Color(0xFF952cb1);
  Color get _themeAccent => const Color(0xFFbe004c);
  LinearGradient get _themeGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9333ea), Color(0xFFf472b6)],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.8),
              elevation: 0.5,
              shadowColor: const Color(0xFF45274b).withOpacity(0.2),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF7e22ce)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                widget.theme == 'tet' ? 'Quà Tết' : 'Quà Valentine',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Color(0xFF581c87),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 88, left: 16, right: 16, bottom: 24),
              children: [
                _buildSectionTitle('Chọn mẫu quà 3D', Icons.view_in_ar),
                const SizedBox(height: 12),
                _buildModelCarousel(),
                const SizedBox(height: 32),
                _buildSectionTitle('Khu vực thiết kế', Icons.dashboard_customize),
                const SizedBox(height: 12),
                _buildDesignArea(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Thêm sticker', Icons.auto_awesome),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'TẤT CẢ',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: Color(0xFF952cb1),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStickerGrid(),
                const SizedBox(height: 32),
                _buildSectionTitle('Lời nhắn', Icons.message_outlined),
                const SizedBox(height: 12),
                _buildMessageInput(),
                const SizedBox(height: 32),
                _buildSectionTitle(
                  widget.theme == 'tet' ? 'Tiền mừng tuổi (Lì xì)' : 'Gửi kèm tiền mặt',
                  Icons.account_balance_wallet_outlined,
                ),
                const SizedBox(height: 12),
                _buildCashInput(),
                const SizedBox(height: 24),
              ],
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
            color: const Color(0xFFFDD6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF952cb1), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: Color(0xFF75547a),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildModelCarousel() {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: _models.length,
        itemBuilder: (context, index) {
          final model = _models[index];
          final isSelected = index == _selectedModelIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedModelIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 110,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEFFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF952cb1) : Colors.transparent,
                  width: isSelected ? 2.0 : 0.0,
                ),
                boxShadow: [
                  if (isSelected) 
                    BoxShadow(
                      color: const Color(0xFF952cb1).withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: isSelected
                            ? _pulseAnimation
                            : const AlwaysStoppedAnimation(1.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForModel(model.thumbnailIcon),
                            color: const Color(0xFF952cb1),
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          model.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: isSelected ? const Color(0xFF952cb1) : const Color(0xFF75547a),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF952cb1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
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

  Widget _buildStickerThumb(
    GiftSticker sticker, {
    double size = 64,
    bool dragging = false,
  }) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFFC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: dragging
            ? [
                BoxShadow(
                  color: const Color(0xFF952cb1).withOpacity(0.3),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            sticker.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.auto_awesome, color: Color(0xFF75547a), size: 24),
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
          _placedStickers.add(
            _PlacedSticker(
              sticker: details.data,
              x: localOffset.dx.clamp(0, 300),
              y: localOffset.dy.clamp(0, 200),
              scale: 1.0,
              rotation: 0.0,
            ),
          );
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 380,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEFFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFF952cb1)
                  : Colors.transparent,
              width: isHovering ? 2.5 : 0.0,
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
                      child: GlbModelViewer(
                        key: ValueKey(_models[_selectedModelIndex].id),
                        assetPath: _models[_selectedModelIndex].assetPath,
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
                    onScaleStart: (details) {
                      _gestureStates[idx] = _StickerGestureState(
                        focalPoint: details.focalPoint,
                        startX: placed.x,
                        startY: placed.y,
                        startScale: placed.scale,
                        startRotation: placed.rotation,
                      );
                    },
                    onScaleUpdate: (details) {
                      final state = _gestureStates[idx];
                      if (state == null) return;

                      final dx = details.focalPoint.dx - state.focalPoint.dx;
                      final dy = details.focalPoint.dy - state.focalPoint.dy;

                      setState(() {
                        placed.x = (state.startX + dx).clamp(0.0, 260.0);
                        placed.y = (state.startY + dy).clamp(0.0, 190.0);
                        placed.scale = (state.startScale * details.scale).clamp(
                          0.5,
                          2.5,
                        );
                        placed.rotation = state.startRotation + details.rotation;
                      });
                    },
                    onScaleEnd: (_) {
                      _gestureStates.remove(idx);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Transform.rotate(
                          angle: placed.rotation,
                          child: Transform.scale(
                            scale: placed.scale,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Image.asset(
                                placed.sticker.assetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.auto_awesome,
                                  color: _themeColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _placedStickers.removeAt(idx);
                                _gestureStates.remove(idx);
                              });
                            },
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
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
                  bottom: 12,
                  left: 0,
                  right: 0,
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

  Widget _buildCashInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE6FE), width: 2),
      ),
      child: TextField(
        controller: _cashController,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Color(0xFF45274b),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập số tiền (VD: 20000)',
          hintStyle: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: const Color(0xFF75547a).withOpacity(0.4),
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.payments_outlined, color: Color(0xFF952cb1)),
          suffixText: 'VNĐ',
          suffixStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: Color(0xFF952cb1),
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Stack(
      children: [
        TextField(
          controller: _messageController,
          maxLines: 4,
          maxLength: 200,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: Color(0xFF45274b), 
            fontSize: 15
          ),
          decoration: InputDecoration(
            hintText: widget.theme == 'tet'
                ? 'Nhập lời chúc của bạn tại đây...'
                : 'Gửi lời yêu thương...',
            hintStyle: TextStyle(color: const Color(0xFF75547a).withOpacity(0.4), fontFamily: 'Plus Jakarta Sans'),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFFE6FE), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF952cb1), width: 2),
            ),
            counterStyle: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: const Color(0xFF75547a).withOpacity(0.5),
              fontSize: 11,
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 16,
          child: Row(
            children: [
              Icon(Icons.edit_note, size: 18, color: const Color(0xFF75547a).withOpacity(0.4)),
              const SizedBox(width: 4),
              Text(
                'TÙY CHỈNH',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: const Color(0xFF75547a).withOpacity(0.4),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDD6FF),
                  foregroundColor: const Color(0xFF952cb1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () {
                  setState(() => _placedStickers.clear());
                },
                child: const Text(
                  'Đặt lại', 
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF9333ea), Color(0xFFf472b6)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFa855f7).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GiftPreviewScreen(
                        theme: widget.theme,
                        model: _models[_selectedModelIndex],
                        stickers: _placedStickers
                            .map(
                              (s) => {
                                'id': s.sticker.id,
                                'x': s.x,
                                'y': s.y,
                                'scale': s.scale,
                                'rotation': s.rotation,
                              },
                            )
                            .toList(),
                        message: _messageController.text.trim(),
                        cashAmount: double.tryParse(_cashController.text) ?? 0,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Xem trước & Gửi',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForModel(String iconName) {
    switch (iconName) {
      case 'redeem':
        return Icons.redeem;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'local_florist':
        return Icons.local_florist;
      case 'pets':
        return Icons.pets;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'favorite':
        return Icons.favorite;
      case 'smart_toy':
        return Icons.smart_toy;
      case 'cake':
        return Icons.cake;
      default:
        return Icons.card_giftcard;
    }
  }
}

class _PlacedSticker {
  final GiftSticker sticker;
  double x;
  double y;
  double scale;
  double rotation;

  _PlacedSticker({
    required this.sticker,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

class _StickerGestureState {
  final Offset focalPoint;
  final double startX;
  final double startY;
  final double startScale;
  final double startRotation;

  _StickerGestureState({
    required this.focalPoint,
    required this.startX,
    required this.startY,
    required this.startScale,
    required this.startRotation,
  });
}
