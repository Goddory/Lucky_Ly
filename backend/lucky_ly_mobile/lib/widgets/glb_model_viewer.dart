import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';


class GlbModelViewer extends StatefulWidget {
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
    _resolveSource();
  }

  @override
  void didUpdateWidget(covariant GlbModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _resolveSource();
    }
  }

  Future<void> _resolveSource() async {
    setState(() {
      _src = null;
      _error = null;
    });

    if (kIsWeb) {
      setState(() => _src = widget.assetPath);
      return;
    }

    try {
      final byteData = await rootBundle.load(widget.assetPath);
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.assetPath.split('/').last;
      final targetFile = File('${tempDir.path}/gift_preview_$fileName');

      if (!targetFile.existsSync() || targetFile.lengthSync() != bytes.length) {
        await targetFile.writeAsBytes(bytes, flush: true);
      }

      if (!mounted) return;
      setState(() => _src = targetFile.uri.toString());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
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

    if (_src == null) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: const CustomLoading(size: 80),
        ),
      );
    }

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
