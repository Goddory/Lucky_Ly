import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../data/gift_catalog.dart';
import '../../app_theme.dart';
import 'gift_preview_screen.dart';
import '../../widgets/glb_model_viewer.dart';

/// ThemedGiftBuilderScreen - Màn hình tạo quà theo chủ đề
/// 
/// Chức năng chính:
/// - Chọn mẫu quà 3D theo theme (Tết / Valentine)
/// - Kéo thả sticker vào khu vực thiết kế
/// - Nhập lời nhắn và số tiền kèm theo
/// - Chuyển sang màn preview trước khi gửi quà
/// 
/// Màn hình này đóng vai trò là gift composer:
/// user chọn model, trang trí, nhập message, nhập cash rồi xem trước.
class ThemedGiftBuilderScreen extends StatefulWidget {
  /// Theme đang sử dụng ('tet' hoặc 'valentine')
  const ThemedGiftBuilderScreen({super.key, required this.theme});

  /// Giá trị theme để lấy bộ model/sticker phù hợp
  final String theme; // 'tet' or 'valentine'

  @override
  State<ThemedGiftBuilderScreen> createState() =>
      _ThemedGiftBuilderScreenState();
}

/// State của màn hình tạo quà theo theme
class _ThemedGiftBuilderScreenState extends State<ThemedGiftBuilderScreen>
    with SingleTickerProviderStateMixin {
  /// Danh sách model 3D theo theme hiện tại
  late final List<GiftModel> _models;

  /// Danh sách sticker có thể kéo thả vào thiết kế
  late final List<GiftSticker> _stickers;

  /// Index của model 3D đang được chọn trong carousel
  int _selectedModelIndex = 0;

  /// Danh sách sticker đã được đặt vào khu vực thiết kế
  final List<_PlacedSticker> _placedStickers = [];

  /// Lưu trạng thái gesture scale/drag cho từng sticker đã đặt
  final Map<int, _StickerGestureState> _gestureStates = {};

  /// Controller cho nội dung lời nhắn
  final TextEditingController _messageController = TextEditingController();

  /// Controller cho số tiền kèm theo
  final TextEditingController _cashController = TextEditingController();

  /// Animation controller tạo hiệu ứng pulse nhẹ cho model đang chọn
  late AnimationController _pulseController;

  /// Animation scale nhẹ để làm model đang chọn nổi bật hơn
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    /// Load model và sticker theo theme từ GiftCatalog
    _models = GiftCatalog.getModels(widget.theme);
    _stickers = GiftCatalog.getStickers(widget.theme);

    /// Tạo animation pulse lặp liên tục cho model được chọn
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    /// Scale dao động từ 1.0 đến 1.05 để tạo cảm giác sống động
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    /// Giải phóng controller và text controllers để tránh memory leak
    _pulseController.dispose();
    _messageController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  /// Màu nhấn chính của UI
  Color get _themeColor => const Color(0xFF952cb1);

  /// Màu accent phụ
  Color get _themeAccent => const Color(0xFFbe004c);

  /// Gradient nền chủ đạo cho các phần nhấn mạnh
  LinearGradient get _themeGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9333ea), Color(0xFFf472b6)],
  );

  @override
  Widget build(BuildContext context) {
    /// Layout tổng thể: app bar mờ, vùng thiết kế, bottom bar hành động
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        /// AppBar tùy biến cao 64px
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            /// Hiệu ứng kính mờ cho app bar
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
              /// Padding trên cùng chừa chỗ cho app bar trong suốt
              padding: const EdgeInsets.only(top: 88, left: 16, right: 16, bottom: 24),
              children: [
                /// Tiêu đề khu chọn model 3D
                _buildSectionTitle('Chọn mẫu quà 3D', Icons.view_in_ar),
                const SizedBox(height: 12),

                /// Carousel ngang chọn model quà
                _buildModelCarousel(),
                const SizedBox(height: 32),

                /// Khu vực đặt và chỉnh sửa quà
                _buildSectionTitle('Khu vực thiết kế', Icons.dashboard_customize),
                const SizedBox(height: 12),
                _buildDesignArea(),
                const SizedBox(height: 32),

                /// Khu vực sticker kéo thả
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

                /// Danh sách sticker dạng ngang
                _buildStickerGrid(),
                const SizedBox(height: 32),

                /// Input lời nhắn cá nhân
                _buildSectionTitle('Lời nhắn', Icons.message_outlined),
                const SizedBox(height: 12),
                _buildMessageInput(),
                const SizedBox(height: 32),

                /// Input tiền mặt / lì xì theo theme
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

  /// Xây dựng tiêu đề cho từng section trong màn hình
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

  /// Carousel ngang cho phép chọn mẫu quà 3D
  /// 
  /// Cách hoạt động:
  /// - Hiển thị từng model trong list _models
  /// - Chạm vào item sẽ set _selectedModelIndex
  /// - Item được chọn có viền, shadow và hiệu ứng pulse
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
            /// Chọn model hiện tại
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
                      /// Model đang được chọn thì pulse nhẹ
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

                      /// Tên model 3D
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
                    /// Dấu check ở góc trên phải để đánh dấu item đang chọn
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

  /// Grid sticker dạng ngang cho phép kéo thả vào khu thiết kế
  Widget _buildStickerGrid() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _stickers.length,
        itemBuilder: (context, index) {
          final sticker = _stickers[index];
          return Draggable<GiftSticker>(
            /// Sticker được kéo ra khỏi list
            data: sticker,
            feedback: Material(
              color: Colors.transparent,
              child: _buildStickerThumb(sticker, size: 60, dragging: true),
            ),
            /// Khi đang kéo thì chỗ cũ mờ đi
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildStickerThumb(sticker),
            ),
            /// Thumbnail sticker bình thường
            child: _buildStickerThumb(sticker),
          );
        },
      ),
    );
  }

  /// Thumbnail nhỏ cho mỗi sticker
  /// 
  /// Tham số:
  /// - size: kích thước hiển thị
  /// - dragging: có đang kéo hay không để đổi shadow
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

  /// Khu vực thiết kế chính, nơi người dùng thả sticker lên quà
  /// 
  /// Chức năng:
  /// - Nhận sticker từ DragTarget
  /// - Hiển thị model quà 3D ở giữa
  /// - Render các sticker đã đặt
  /// - Cho phép kéo, xoay, phóng to và xóa sticker
  Widget _buildDesignArea() {
    return DragTarget<GiftSticker>(
      onAcceptWithDetails: (details) {
        /// Chuyển tọa độ global của sticker về local trong vùng thiết kế
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localOffset = box.globalToLocal(details.offset);
        setState(() {
          /// Thêm sticker mới vào danh sách sticker đã đặt
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
        /// Khi đang kéo sticker lên vùng này thì đổi viền để báo hiệu drop target
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
              /// Preview chính của mẫu quà 3D đang chọn
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

              /// Render tất cả sticker đã được đặt lên khu thiết kế
              ..._placedStickers.asMap().entries.map((entry) {
                final idx = entry.key;
                final placed = entry.value;
                return Positioned(
                  left: placed.x.clamp(0, 260),
                  top: placed.y.clamp(0, 190),
                  child: GestureDetector(
                    /// Bắt đầu gesture scale/drag để lưu trạng thái gốc
                    onScaleStart: (details) {
                      _gestureStates[idx] = _StickerGestureState(
                        focalPoint: details.focalPoint,
                        startX: placed.x,
                        startY: placed.y,
                        startScale: placed.scale,
                        startRotation: placed.rotation,
                      );
                    },
                    /// Cập nhật vị trí, scale và rotation của sticker khi kéo/chụm
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
                    /// Xóa trạng thái gesture khi kết thúc
                    onScaleEnd: (_) {
                      _gestureStates.remove(idx);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        /// Sticker hiển thị với xoay và scale hiện tại
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
                        /// Nút x nhỏ để xóa sticker khỏi vùng thiết kế
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

              /// Hint hướng dẫn nếu chưa đặt sticker nào
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

  /// Input nhập số tiền kèm theo quà
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

  /// Input nhập lời nhắn gửi kèm quà
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
          /// Thanh hành động phía dưới màn hình
          /// 
          /// Gồm:
          /// - Nút Đặt lại: xóa sticker đã đặt
          /// - Nút Xem trước & Gửi: mở GiftPreviewScreen với dữ liệu hiện tại
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
                  /// Nút reset dùng màu nhạt để không lấn át nút chính
                  backgroundColor: const Color(0xFFFDD6FF),
                  foregroundColor: const Color(0xFF952cb1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () {
                  /// Chỉ xóa sticker, không ảnh hưởng model hay lời nhắn
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

          /// Nút chính sang bước preview và gửi
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
                  /// Để gradient từ Container bên ngoài hiển thị
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                onPressed: () {
                  /// Điều hướng sang màn preview, truyền toàn bộ dữ liệu đã cấu hình
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

  /// Map tên icon từ catalog sang IconData của Flutter
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

/// Lưu thông tin một sticker đã được đặt vào vùng thiết kế
class _PlacedSticker {
  /// Sticker gốc từ catalog
  final GiftSticker sticker;

  /// Tọa độ X trong vùng thiết kế
  double x;

  /// Tọa độ Y trong vùng thiết kế
  double y;

  /// Hệ số scale của sticker
  double scale;

  /// Góc xoay của sticker (radian)
  double rotation;

  _PlacedSticker({
    required this.sticker,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
  });
}

/// Lưu state gốc của gesture để phục vụ kéo/xoay/phóng to sticker
class _StickerGestureState {
  /// Điểm chạm gốc khi bắt đầu gesture
  final Offset focalPoint;

  /// Vị trí X ban đầu của sticker
  final double startX;

  /// Vị trí Y ban đầu của sticker
  final double startY;

  /// Scale ban đầu
  final double startScale;

  /// Rotation ban đầu
  final double startRotation;

  _StickerGestureState({
    required this.focalPoint,
    required this.startX,
    required this.startY,
    required this.startScale,
    required this.startRotation,
  });
}
