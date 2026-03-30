import 'dart:async';
import 'dart:math' as math;
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
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:lucky_ly_mobile/app_theme.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';

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

class _ARGiftScreenState extends State<ARGiftScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  ARNode? giftNode;
  ARPlaneAnchor? currentAnchor;
  Timer? animationTimer;

  bool isSupported = true;
  bool isPlaced = false;
  double _time = 0.0;

  @override
  void dispose() {
    animationTimer?.cancel();
    arSessionManager?.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('AR không khả dụng', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.of(context).primary,
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
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          if (!isPlaced && isSupported)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Hướng camera xuống sàn/bàn và chọn bề mặt nhấp nháy',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (isPlaced)
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (currentAnchor != null) {
                    arAnchorManager?.removeAnchor(currentAnchor!);
                  }
                  currentAnchor = null;
                  giftNode = null;
                  animationTimer?.cancel();
                  setState(() {
                    isPlaced = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Đặt lại mặt phẳng', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    arSessionManager?.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: false,
      handlePans: true,
      handleRotation: false, // User requested fixed rotation
    ).catchError((e) {
      if (mounted) {
        setState(() => isSupported = false);
        _showErrorDialog("Thiết bị của bạn không hỗ trợ ARCore/ARKit mặt phẳng. Vui lòng thử lại trên thiết bị khác ($e).");
      }
    });

    arObjectManager?.onInitialize();
    arSessionManager?.onPlaneOrPointTap = onPlaneOrPointTapped;
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (isPlaced || hitTestResults.isEmpty) return;

    var hit = hitTestResults.first;
    var newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
    bool? added = await arAnchorManager?.addAnchor(newAnchor);

    if (added != null && added) {
      currentAnchor = newAnchor;
      
      // Node initialization with vector3
      var node = ARNode(
        type: NodeType.localGLTF2,
        uri: widget.modelPath,
        scale: vector.Vector3(0.5, 0.5, 0.5), // Scale properly fit
        position: vector.Vector3(0, 0, 0),
        rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0)
      );
      
      bool? nodeAdded = await arObjectManager?.addNode(node, planeAnchor: newAnchor);
      if (nodeAdded != null && nodeAdded) {
        giftNode = node;
        setState(() {
          isPlaced = true;
        });
        
        // Cố định, tự xoay và lắc lư nhẹ
        _startAnimationLoop();
      } else {
        arAnchorManager?.removeAnchor(newAnchor);
      }
    }
  }

  void _startAnimationLoop() {
    animationTimer?.cancel();
    _time = 0.0;
    // Update transformation via timer at 60fps (16ms)
    animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (giftNode == null || arObjectManager == null) {
        timer.cancel();
        return;
      }
      _time += 0.016; // Increment by 16ms approx

      // Xoay vòng quanh trục Y (quay đều)
      double rotationAmount = _time; // 1 rad / s

      // Lắc lư nhẹ theo trục X và Z
      double wobbleX = math.sin(_time * 2.0) * 0.1; // Biên độ nhỏ
      double wobbleZ = math.cos(_time * 2.5) * 0.1;

      // Construct a quaternion from Euler angles (wobbleX, rotationAmount, wobbleZ)
      vector.Quaternion q = vector.Quaternion.euler(wobbleX, rotationAmount, wobbleZ);
      
      final transform = vector.Matrix4.compose(giftNode!.position, q, giftNode!.scale);
      
      giftNode!.transform = transform;
    });
  }
}
