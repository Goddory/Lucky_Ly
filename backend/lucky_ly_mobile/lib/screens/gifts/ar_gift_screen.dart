import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:lucky_ly_mobile/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ARGiftScreen extends StatefulWidget {
  final Map<String, dynamic> gift;
  final String modelPath;

  const ARGiftScreen({
    super.key,
    required this.gift,
    required this.modelPath,
  });

  @override
  State<ARGiftScreen> createState() => _ARGiftScreenState();
}

class _ARGiftScreenState extends State<ARGiftScreen> with SingleTickerProviderStateMixin {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  ARNode? giftNode;
  ARPlaneAnchor? currentAnchor;
  Timer? animationTimer;
  Timer? _scanHintTimer;
  late AnimationController _pulseController;

  bool isSupported = true;
  bool isInitialized = false;
  bool isPlaced = false;
  bool isChecking = true;
  bool _showTapHint = false; // after scan timeout, show "tap anywhere" hint
  double _time = 0.0;
  String _scanStatus = 'Đang khởi tạo AR...';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkARCoreAvailability();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanHintTimer?.cancel();
    animationTimer?.cancel();
    arSessionManager?.dispose();
    super.dispose();
  }

  Future<void> _checkARCoreAvailability() async {
    try {
      final bool? available = await const MethodChannel('WJ_arcore_check')
          .invokeMethod<bool>('checkAvailability');
      if (mounted) {
        if (available == true) {
          setState(() => isChecking = false);
        } else {
          setState(() {
            isChecking = false;
            isSupported = false;
          });
          _showInstallARCoreDialog();
        }
      }
    } on MissingPluginException {
      if (mounted) setState(() => isChecking = false);
    } catch (e) {
      if (mounted) setState(() => isChecking = false);
    }
  }

  void _showInstallARCoreDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.view_in_ar, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('Cần cài ARCore', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
            ],
          ),
          content: const Text(
            'Thiết bị cần cài "Google Play Services for AR" (ARCore) để sử dụng tính năng Camera AR.\n\n'
            'Bấm nút bên dưới để mở Google Play Store và cài đặt.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Quay lại'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final nav = Navigator.of(ctx);
                final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.google.ar.core');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                nav.pop();
                nav.pop();
              },
              icon: const Icon(Icons.shop, size: 18),
              label: const Text('Cài ARCore'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.of(ctx).primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('AR không khả dụng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () async {
                final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.google.ar.core');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Cài ARCore'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.of(ctx).primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Camera AR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [
            Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))
          ]),
        ),
      ),
      body: isChecking
          ? const Center(child: CircularProgressIndicator())
          : !isSupported
              ? _buildUnsupportedView()
              : Stack(
                  children: [
                    ARView(
                      onARViewCreated: onARViewCreated,
                      planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
                    ),
                    // Scanning overlay with instructions
                    if (!isPlaced && isSupported)
                      _buildScanningOverlay(),
                    // Reset button when gift is placed
                    if (isPlaced)
                      Positioned(
                        bottom: 40,
                        left: 40,
                        right: 40,
                        child: ElevatedButton.icon(
                          onPressed: _resetPlacement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 6,
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Đặt lại', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildScanningOverlay() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scanning animation icon
          if (!_showTapHint)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + 0.5 * _pulseController.value,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.phone_android, color: Colors.white, size: 32),
                  ),
                );
              },
            ),
          if (_showTapHint)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + 0.5 * _pulseController.value,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.greenAccent, width: 2),
                      color: Colors.greenAccent.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.touch_app, color: Colors.greenAccent, size: 32),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              _scanStatus,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_in_ar, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Cần cài đặt ARCore',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thiết bị chưa cài "Google Play Services for AR".\nVui lòng cài từ Play Store rồi thử lại.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.google.ar.core');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.shop),
              label: const Text('Mở Play Store'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetPlacement() {
    if (currentAnchor != null) {
      arAnchorManager?.removeAnchor(currentAnchor!);
    }
    currentAnchor = null;
    giftNode = null;
    animationTimer?.cancel();
    setState(() {
      isPlaced = false;
      _showTapHint = false;
      _scanStatus = 'Di chuyển điện thoại chậm để quét lại bề mặt...';
    });
    // Restart the scan hint timer
    _startScanHintTimer();
  }

  void _startScanHintTimer() {
    _scanHintTimer?.cancel();
    // Phase 1: After 3s — tell user to move phone slowly
    _scanHintTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || isPlaced) return;
      setState(() {
        _scanStatus = 'Di chuyển điện thoại chậm qua lại trên bề mặt phẳng...';
      });

      // Phase 2: After 6s more — show "tap to place" instruction
      _scanHintTimer = Timer(const Duration(seconds: 6), () {
        if (!mounted || isPlaced) return;
        setState(() {
          _showTapHint = true;
          _scanStatus = '✅ Chạm vào bề mặt phẳng (sàn/bàn) để đặt quà!';
        });
      });
    });
  }

  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    // Intercept native errors
    arSessionManager!.onErrorCallback = (String error) {
      if (!mounted) return;
      if (error.toLowerCase().contains('session is null')) {
        setState(() => isSupported = false);
        _showErrorDialog(
          'ARCore chưa sẵn sàng trên thiết bị.\n\n'
          'Vui lòng cập nhật "Google Play Services for AR" trên Play Store.\n\nChi tiết: $error',
        );
      } else {
        // Normal error (e.g. failed to add node, missing asset, etc.)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi AR: $error'),
          backgroundColor: Colors.redAccent,
        ));
      }
    };

    try {
      arSessionManager!.onInitialize(
        showFeaturePoints: false, // Turned off because users thought they were the gift
        showPlanes: true,         // Only show the plane grid
        showWorldOrigin: false,
        handlePans: false,
        handleRotation: false,
      );
      if (mounted) {
        setState(() {
          isInitialized = true;
          _scanStatus = 'Hướng camera xuống bàn/sàn và di chuyển chậm...';
        });
      }
      arObjectManager?.onInitialize();
      arSessionManager?.onPlaneOrPointTap = onPlaneOrPointTapped;

      // Start scan hint timer
      _startScanHintTimer();
    } catch (e) {
      if (mounted) {
        setState(() => isSupported = false);
      }
      _showErrorDialog(
        'Không thể khởi động AR.\n\nLỗi: $e',
      );
    }
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (!mounted || isPlaced || hitTestResults.isEmpty) return;
    if (!isInitialized || arAnchorManager == null || arObjectManager == null) return;

    var hit = hitTestResults.first;
    var newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
    bool? added = await arAnchorManager?.addAnchor(newAnchor);

    if (added != null && added) {
      currentAnchor = newAnchor;

      try {
        // MỘT MẸO RẤT QUAN TRỌNG:
        // ar_flutter_plugin không hỗ trợ giải mã file .glb từ thư mục assets một cách chính xác
        // (nó sẽ coi là file .gltf và văng lỗi "Unable to load renderable").
        // Cách giải quyết: Copy file .glb từ asset ra thư mục app_flutter (DocumentsDir)
        // và dùng NodeType.fileSystemAppFolderGLB.
        final docsDir = await getApplicationDocumentsDirectory();
        final filename = widget.modelPath.split('/').last;
        final file = File('${docsDir.path}/$filename');

        if (!await file.exists()) {
          final byteData = await rootBundle.load(widget.modelPath);
          await file.writeAsBytes(
              byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
          );
        }

        var node = ARNode(
          type: NodeType.fileSystemAppFolderGLB,
          uri: filename,
          scale: vector.Vector3(0.4, 0.4, 0.4),
          position: vector.Vector3(0, 0, 0),
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
        );

        bool? nodeAdded = await arObjectManager?.addNode(node, planeAnchor: newAnchor);
        if (nodeAdded != null && nodeAdded) {
          giftNode = node;
          _scanHintTimer?.cancel();
          if (mounted) setState(() => isPlaced = true);
          _startAnimationLoop();
        } else {
          arAnchorManager?.removeAnchor(newAnchor);
        }
      } catch (e) {
        arAnchorManager?.removeAnchor(newAnchor);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Lỗi tải 3D: $e'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    }
  }

  void _startAnimationLoop() {
    animationTimer?.cancel();
    _time = 0.0;
    animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || giftNode == null) {
        timer.cancel();
        return;
      }
      _time += 0.05;

      double rotX = _time * 0.8;
      double wobbleY = math.sin(_time * 1.5) * 0.08;
      double wobbleZ = math.cos(_time * 2.0) * 0.06;

      final q = vector.Quaternion.euler(rotX, wobbleY, wobbleZ);
      final transform = vector.Matrix4.compose(
        vector.Vector3(0, 0, 0),
        q,
        giftNode!.scale,
      );
      giftNode!.transform = transform;
    });
  }
}
