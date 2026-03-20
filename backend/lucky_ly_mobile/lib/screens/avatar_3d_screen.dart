import 'package:flutter/material.dart';
import 'package:flutter_unity_widget_2/flutter_unity_widget_2.dart';
import '../core/database/database_helper.dart';

class Avatar3DScreen extends StatefulWidget {
  const Avatar3DScreen({Key? key}) : super(key: key);

  @override
  State<Avatar3DScreen> createState() => _Avatar3DScreenState();
}

class _Avatar3DScreenState extends State<Avatar3DScreen> {
  UnityWidgetController? _unityWidgetController;
  String? _localModelPath;

  @override
  void initState() {
    super.initState();
    _loadLatestAvatar();
  }

  Future<void> _loadLatestAvatar() async {
    final dbHelper = DatabaseHelper.instance;
    // Tìm avatar mới nhất
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> avatars = await db.query(
      'avatars',
      orderBy: 'clientUpdatedAt DESC',
      limit: 1,
    );

    if (avatars.isNotEmpty) {
      setState(() {
        _localModelPath = avatars.first['localPath'];
      });
      // Nếu Unity đã load xong, gọi luôn
      if (_unityWidgetController != null && _localModelPath != null) {
        _sendModelPathToUnity(_localModelPath!);
      }
    }
  }

  void onUnityCreated(controller) {
    _unityWidgetController = controller;
    if (_localModelPath != null) {
      _sendModelPathToUnity(_localModelPath!);
    }
  }

  void _sendModelPathToUnity(String path) {
    // Gọi method LoadAvatarFromPath của object AvatarManager trong Unity
    _unityWidgetController?.postMessage(
      'AvatarManager',
      'LoadAvatarFromPath',
      path,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar 3D của tôi'),
        backgroundColor: const Color(0xFF0EA5D8),
      ),
      body: Stack(
        children: [
          UnityWidget(
            onUnityCreated: onUnityCreated,
            useAndroidViewSurface: true, // Yêu cầu từ thư viện
          ),
          if (_localModelPath == null)
            const Center(
              child: Text(
                'Bạn chưa có avatar 3D nào. Hãy nhấn tạo mới!',
                style: TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
