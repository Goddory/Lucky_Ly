import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';


class GlbModelViewer extends StatefulWidget {
  // Widget hiển thị model 3D định dạng GLB/GLTF từ asset nội bộ.
  const GlbModelViewer({
    super.key,
    required this.assetPath,
    required this.alt,
    this.backgroundColor = Colors.transparent,
    this.autoRotate = true,
    this.cameraControls = true,
  });

  final String assetPath;
  final String alt;
  final Color backgroundColor;
  final bool autoRotate;
  final bool cameraControls;

  @override
  State<GlbModelViewer> createState() => _GlbModelViewerState();
}

class _GlbModelViewerState extends State<GlbModelViewer> {
  String? _src;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Resolve source ngay khi widget được khởi tạo để chuẩn bị đường dẫn cho ModelViewer.
    _resolveSource();
  }

  @override
  void didUpdateWidget(covariant GlbModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu assetPath đổi thì tải lại source mới.
    if (oldWidget.assetPath != widget.assetPath) {
      _resolveSource();
    }
  }

  Future<void> _resolveSource() async {
    // Reset state trước khi xử lý để UI có thể chuyển sang trạng thái loading.
    setState(() {
      _src = null;
      _error = null;
    });

    // Trên web có thể dùng trực tiếp assetPath vì không cần copy file sang thư mục tạm.
    if (kIsWeb) {
      setState(() => _src = widget.assetPath);
      return;
    }

    try {
      // Mobile/Desktop: đọc asset từ bundle, ghi ra file tạm rồi đưa URI cho package model_viewer_plus.
      final byteData = await rootBundle.load(widget.assetPath);
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.assetPath.split('/').last;
      final targetFile = File('${tempDir.path}/gift_preview_$fileName');

      // Chỉ ghi lại nếu file chưa có hoặc kích thước khác để tránh làm việc thừa.
      if (!targetFile.existsSync() || targetFile.lengthSync() != bytes.length) {
        await targetFile.writeAsBytes(bytes, flush: true);
      }

      if (!mounted) return;
      setState(() => _src = targetFile.uri.toString());
    } catch (e) {
      if (!mounted) return;
      // Lưu lỗi để build hiển thị fallback thay vì crash.
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Khi có lỗi tải model thì hiển thị trạng thái fallback đơn giản.
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.broken_image_outlined,
              color: Colors.redAccent,
              size: 28,
            ),
            SizedBox(height: 8),
            Text('Không tải được model 3D', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    // Trong lúc đang resolve source thì hiển thị loading spinner.
    if (_src == null) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: const CustomLoading(size: 80),
        ),
      );
    }

    // ModelViewer là widget thực sự render model 3D.
    return ModelViewer(
      key: ValueKey(_src),
      src: _src!,
      alt: widget.alt,
      autoRotate: widget.autoRotate,
      cameraControls: widget.cameraControls,
      backgroundColor: widget.backgroundColor,
    );
  }
}
