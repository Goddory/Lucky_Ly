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

/// ARGiftScreen - Màn hình thực tế tăng cường để hiển thị quà 3D trong không gian thật
/// 
/// Chức năng chính:
/// - Kiểm tra ARCore/AR services trên thiết bị
/// - Hiển thị camera AR với plane detection
/// - Cho phép chạm vào mặt phẳng để đặt mô hình quà 3D
/// - Hiển thị hint quét bề mặt và nút đặt lại
/// 
/// Input:
/// - gift: Dữ liệu quà tặng để phục vụ UI/logic mở rộng sau này
/// - modelPath: Đường dẫn asset tới file mô hình 3D (.glb)
class ARGiftScreen extends StatefulWidget {
  /// Thông tin quà tặng hiện tại
  final Map<String, dynamic> gift;

  /// Đường dẫn asset tới mô hình 3D sẽ render trong AR
  final String modelPath;

  /// Constructor của màn hình AR quà tặng
  const ARGiftScreen({
    super.key,
    required this.gift,
    required this.modelPath,
  });

  @override
  State<ARGiftScreen> createState() => _ARGiftScreenState();
}

/// State của ARGiftScreen, quản lý toàn bộ vòng đời AR session và placement logic
class _ARGiftScreenState extends State<ARGiftScreen> with SingleTickerProviderStateMixin {
  /// Quản lý AR session lifecycle
  ARSessionManager? arSessionManager;

  /// Quản lý thêm node/mô hình 3D vào AR scene
  ARObjectManager? arObjectManager;

  /// Quản lý anchor để ghim mô hình vào mặt phẳng thực tế
  ARAnchorManager? arAnchorManager;

  /// Node mô hình quà đang được render
  ARNode? giftNode;

  /// Anchor hiện tại của mô hình quà
  ARPlaneAnchor? currentAnchor;

  /// Timer chạy animation xoay/lắc nhẹ cho mô hình
  Timer? animationTimer;

  /// Timer đếm thời gian để đổi hint quét bề mặt
  Timer? _scanHintTimer;

  /// Animation controller dùng cho hiệu ứng pulse của hint
  late AnimationController _pulseController;

  /// Cờ cho biết AR có được hỗ trợ trên thiết bị hay không
  bool isSupported = true;

  /// Cờ cho biết AR đã khởi tạo xong chưa
  bool isInitialized = false;

  /// Cờ cho biết quà đã được đặt xuống mặt phẳng chưa
  bool isPlaced = false;

  /// Cờ trong lúc đang kiểm tra ARCore availability
  bool isChecking = true;

  /// Cờ hiển thị hint "chạm vào bề mặt" sau khi scan đủ lâu
  bool _showTapHint = false; // after scan timeout, show "tap anywhere" hint

  /// Biến thời gian dùng để tạo animation xoay/lắc
  double _time = 0.0;

  /// Trạng thái text hiển thị bên dưới icon scan
  String _scanStatus = 'Đang khởi tạo AR...';

  /// initState: khởi tạo pulse animation và kiểm tra ARCore
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _checkARCoreAvailability();
  }

  /// dispose: giải phóng timer, controller và AR session để tránh leak
  @override
  void dispose() {
    _pulseController.dispose();
    _scanHintTimer?.cancel();
    animationTimer?.cancel();
    arSessionManager?.dispose();
    super.dispose();
  }

  /// Kiểm tra thiết bị có hỗ trợ ARCore hay không
  /// 
  /// Flow:
  /// 1. Gọi MethodChannel native để check ARCore
  /// 2. Nếu không có plugin native thì bỏ qua và tiếp tục
  /// 3. Nếu không hỗ trợ → mở dialog hướng dẫn cài ARCore
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

  /// Hiển thị dialog hướng dẫn cài ARCore khi thiết bị chưa có hỗ trợ
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
        /// Hiển thị dialog lỗi chung khi AR không thể chạy
        /// 
        /// Thường được gọi khi:
        /// - Session null
        /// - Lỗi native ARCore
        /// - Không thể khởi động AR session
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
            /// Scaffold chính với AppBar trong suốt và AR camera làm nền
  }

  void _showErrorDialog(String message) {
                /// AppBar trong suốt để nhìn thấy camera phía sau
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
          /// Trong lúc kiểm tra ARCore → hiển thị loading
          ? const Center(child: CircularProgressIndicator())
          : !isSupported
              /// Nếu thiết bị không hỗ trợ → hiển thị màn hình thay thế
              ? _buildUnsupportedView()
              : Stack(
                  children: [
                    /// ARView là camera AR chính với plane detection
                    ARView(
                      onARViewCreated: onARViewCreated,
                      planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
                    ),

                    /// Lớp overlay hướng dẫn scan và đặt quà
                    if (!isPlaced && isSupported)
                      _buildScanningOverlay(),

                    /// Nút đặt lại vị trí quà sau khi đã place
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

          /// Overlay hướng dẫn người dùng scan bề mặt và chạm để đặt quà
  Widget _buildScanningOverlay() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// Icon pulse thay đổi tùy theo trạng thái scan
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

          /// Khi hết thời gian scan ban đầu thì chuyển sang icon chạm tay
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

          /// Dòng trạng thái mô tả người dùng cần làm gì tiếp theo
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

  /// Màn hình fallback khi thiết bị không hỗ trợ ARCore
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

  /// Reset lại trạng thái đặt quà để người dùng có thể chọn vị trí khác
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

  /// Khởi động timer nhắc scan bề mặt sau một khoảng thời gian
  /// 
  /// Mục tiêu:
  /// - Sau 3 giây: nhắc người dùng di chuyển điện thoại chậm hơn
  /// - Sau 6 giây tiếp theo: đổi sang hint chạm bề mặt để đặt quà
  void _startScanHintTimer() {
    _scanHintTimer?.cancel();

    /// Giai đoạn 1: Sau 3 giây, nhắc di chuyển điện thoại chậm
    _scanHintTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || isPlaced) return;
      setState(() {
        _scanStatus = 'Di chuyển điện thoại chậm qua lại trên bề mặt phẳng...';
      });

      /// Giai đoạn 2: Sau thêm 6 giây, chuyển sang hint chạm để đặt
      _scanHintTimer = Timer(const Duration(seconds: 6), () {
        if (!mounted || isPlaced) return;
        setState(() {
          _showTapHint = true;
          _scanStatus = '✅ Chạm vào bề mặt phẳng (sàn/bàn) để đặt quà!';
        });
      });
    });
  }

  /// Callback được gọi khi ARView đã sẵn sàng
  /// 
  /// Nhận các manager cần thiết để vận hành AR scene:
  /// - SessionManager: điều khiển session
  /// - ObjectManager: thêm object/node
  /// - AnchorManager: quản lý anchor
  /// - LocationManager: hỗ trợ định vị nếu cần
  void onARViewCreated(
      ARSessionManager sessionManager,
      ARObjectManager objectManager,
      ARAnchorManager anchorManager,
      ARLocationManager locationManager) {
    arSessionManager = sessionManager;
    arObjectManager = objectManager;
    arAnchorManager = anchorManager;

    /// Bắt lỗi native từ AR session để hiển thị message thân thiện
    arSessionManager!.onErrorCallback = (String error) {
      if (!mounted) return;
      if (error.toLowerCase().contains('session is null')) {
        setState(() => isSupported = false);
        _showErrorDialog(
          'ARCore chưa sẵn sàng trên thiết bị.\n\n'
          'Vui lòng cập nhật "Google Play Services for AR" trên Play Store.\n\nChi tiết: $error',
        );
      } else {
        /// Lỗi bình thường: fail add node, thiếu asset, v.v.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi AR: $error'),
          backgroundColor: Colors.redAccent,
        ));
      }
    };

    try {
      arSessionManager!.onInitialize(
        /// Tắt feature points để tránh người dùng nhầm với quà
        showFeaturePoints: false,
        /// Chỉ hiển thị plane grid để người dùng biết bề mặt có thể đặt quà
        showPlanes: true,
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

      /// Bắt đầu timer nhắc scan bề mặt
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

  /// Xử lý khi người dùng chạm vào mặt phẳng hoặc điểm AR hợp lệ
  /// 
  /// Quy trình:
  /// 1. Kiểm tra điều kiện hợp lệ: đã init, chưa đặt quà, có hit test result
  /// 2. Tạo anchor mới từ world transform của điểm chạm
  /// 3. Copy file .glb từ assets ra thư mục app để ar_flutter_plugin load được
  /// 4. Tạo ARNode và add vào plane anchor
  /// 5. Nếu thành công: lưu node, dừng hint timer, bật animation
  /// 6. Nếu thất bại: remove anchor và báo lỗi
  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (!mounted || isPlaced || hitTestResults.isEmpty) return;
    if (!isInitialized || arAnchorManager == null || arObjectManager == null) return;

    var hit = hitTestResults.first;
    var newAnchor = ARPlaneAnchor(transformation: hit.worldTransform);
    bool? added = await arAnchorManager?.addAnchor(newAnchor);

    if (added != null && added) {
      currentAnchor = newAnchor;

      try {
        
        /// ar_flutter_plugin không load .glb trực tiếp từ assets một cách ổn định.
        /// Cách an toàn là copy file ra thư mục Documents của app
        /// rồi dùng NodeType.fileSystemAppFolderGLB.
        final docsDir = await getApplicationDocumentsDirectory();
        final filename = widget.modelPath.split('/').last;
        final file = File('${docsDir.path}/$filename');

        if (!await file.exists()) {
          final byteData = await rootBundle.load(widget.modelPath);
          await file.writeAsBytes(
              byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes)
          );
        }

        /// Tạo node mô hình 3D với scale nhỏ vừa phải để phù hợp bề mặt thật
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
          /// Khi đã đặt thành công, chạy animation lặp cho mô hình
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

  /// Chạy animation loop để làm mô hình quà xoay/lắc nhẹ liên tục
  /// 
  /// Hiệu ứng:
  /// - Xoay trục X chậm
  /// - Lắc nhẹ theo Y/Z bằng sin/cos
  /// - Cập nhật mỗi 50ms để tạo cảm giác sống động
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
