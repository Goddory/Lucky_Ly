import 'dart:io';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../core/database/database_helper.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';


class Avatar3DScreen extends StatefulWidget {
  const Avatar3DScreen({super.key});

  @override
  State<Avatar3DScreen> createState() => _Avatar3DScreenState();
}

class _Avatar3DScreenState extends State<Avatar3DScreen> {
  String? _localModelPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLatestAvatar();
  }

  Future<void> _loadLatestAvatar() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> avatars = await db.query(
        'avatars',
        where: 'isDeleted = ?',
        whereArgs: [0],
        orderBy: 'clientUpdatedAt DESC',
        limit: 1,
      );

      if (avatars.isNotEmpty) {
        final path = avatars.first['localPath'] as String?;
        if (path != null && await File(path).exists()) {
          setState(() {
            _localModelPath = path;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'File model 3D không tồn tại.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải avatar: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Avatar 3D của tôi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF0EA5D8),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CustomLoading(size: 80),
            SizedBox(height: 16),
            Text(
              'Đang tải model 3D...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadLatestAvatar();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5D8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_localModelPath == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5D8).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.view_in_ar,
                  color: Color(0xFF0EA5D8),
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Chưa có Avatar 3D',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hãy tạo avatar mới từ mục "Tạo Model 3D" trong hồ sơ!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Quay lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5D8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Hiển thị model 3D bằng ModelViewer (model_viewer_plus)
    // Hỗ trợ file .glb local
    final fileUri = 'file://$_localModelPath';
    return ModelViewer(
      src: fileUri,
      alt: 'Avatar 3D của bạn',
      autoRotate: true,
      cameraControls: true,
      autoPlay: true,
      backgroundColor: const Color(0xFFF4F7FC),
    );
  }
}
