import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:model_viewer_plus/model_viewer_plus.dart';

class _C {
  static const primary = Color(0xFF0EA5D8);
  static const bg = Color(0xFFF2F6FA);
  static const textMuted = Color(0xFF64748B);
}

class MobileStudioScreen extends StatefulWidget {
  const MobileStudioScreen({super.key});

  @override
  State<MobileStudioScreen> createState() => _MobileStudioScreenState();
}

class _MobileStudioScreenState extends State<MobileStudioScreen> {
  static final String _apiBaseUrl =
      const String.fromEnvironment('API_BASE_URL', defaultValue: '').isNotEmpty
          ? const String.fromEnvironment('API_BASE_URL')
          : (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux ? 'http://localhost:4000' : 'http://10.0.2.2:4000');

  String _currentModelSrc = 'assets/models/tet/lixi_red.glb';
  final List<String> _appliedStickers = [];

  final List<String> _availableModels = [
    'assets/models/tet/BanhChung.glb',
    'assets/models/tet/Phao hoa 1 day.glb',
    'assets/models/tet/Quat.glb',
    'assets/models/tet/lixi_dragon.glb',
    'assets/models/tet/lixi_gold.glb',
    'assets/models/tet/lixi_hoamai.glb',
    'assets/models/tet/lixi_phucloc.glb',
    'assets/models/tet/lixi_red.glb',
  ];

  final List<String> _availableStickers = [
    'assets/stickers/tet/cau_doi.png',
    'assets/stickers/tet/den_long.png',
    'assets/stickers/tet/hoa_dao.png',
    'assets/stickers/tet/hoa_mai.png',
    'assets/stickers/tet/phao_hoa.png',
  ];

  void _showModelModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn Mô Hình 3D',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _availableModels.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final modelPath = _availableModels[index];
                    final modelName = modelPath.split('/').last.replaceAll('.glb', '');
                    final isSelected = _currentModelSrc == modelPath;

                    return ListTile(
                      onTap: () {
                        setState(() => _currentModelSrc = modelPath);
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: isSelected ? _C.primary.withValues(alpha: 0.1) : _C.bg,
                      leading: Icon(Icons.view_in_ar, color: isSelected ? _C.primary : _C.textMuted),
                      title: Text(
                        modelName,
                        style: TextStyle(
                          color: isSelected ? _C.primary : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: _C.primary) : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showStickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thêm Nhãn Dán',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _availableStickers.length,
                  itemBuilder: (context, index) {
                    final stickerPath = _availableStickers[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _appliedStickers.add(stickerPath));
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _C.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _C.primary.withValues(alpha: 0.2)),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(stickerPath, fit: BoxFit.contain),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        title: const Text(
          'Xưởng Studio 3D',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _C.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_appliedStickers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Xóa nhãn dán cuối',
              onPressed: () {
                setState(() => _appliedStickers.removeLast());
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          // 3D Model Viewer & Stickers
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                   ModelViewer(
                    key: ValueKey(_currentModelSrc),
                    backgroundColor: Colors.transparent,
                    src: _currentModelSrc,
                    alt: 'Mô hình 3D Lucky Ly',
                    ar: true,
                    autoRotate: true,
                    cameraControls: true,
                    disableZoom: false,
                  ),
                  // Render applied stickers floating on top
                  ..._appliedStickers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final path = entry.value;
                    // Simple scattered positioning logic
                    final leftOffset = 40.0 + (index * 30) % 200;
                    final topOffset = 40.0 + (index * 40) % 300;
                    return Positioned(
                      left: leftOffset,
                      top: topOffset,
                      child: Image.asset(path, width: 80, height: 80),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Toolbars
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _C.primary.withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StudioTool(icon: Icons.view_in_ar, label: 'Mô hình', onTap: _showModelModal),
                  _StudioTool(icon: Icons.auto_awesome, label: 'Nhãn dán', onTap: _showStickerModal),
                  _StudioTool(icon: Icons.color_lens, label: 'Màu sắc', onTap: () {}),
                  _StudioTool(icon: Icons.text_fields, label: 'Văn bản', onTap: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioTool extends StatelessWidget {
  const _StudioTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.primary),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: _C.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
