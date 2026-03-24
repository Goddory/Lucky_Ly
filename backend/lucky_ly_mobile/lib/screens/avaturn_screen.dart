import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/database/database_helper.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';


class AvaturnScreen extends StatefulWidget {
  // Domain Avaturn chinh thuc cua Lucky Ly.
  static const defaultAvaturnSubdomain = 'https://luckyly.avaturn.dev/';

  // Co the truyen domain khac khi can, neu khong se dung domain mac dinh.
  final String avaturnSubdomain;

  const AvaturnScreen({
    super.key,
    this.avaturnSubdomain = defaultAvaturnSubdomain,
  });

  @override
  State<AvaturnScreen> createState() => _AvaturnScreenState();
}

class _AvaturnScreenState extends State<AvaturnScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'AvaturnEventChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleAvaturnMessage(message.message);
        },
      )
      // Chèn mã JS để hứng sự kiện window postMessage từ iFrame/WebView của Avaturn
      // và pass data xuống Flutter thông qua AvaturnEventChannel.
      ..setOnConsoleMessage((message) {
        print("JS Console: ${message.message}");
      })
      ..loadRequest(Uri.parse(widget.avaturnSubdomain));
  }

  void _handleAvaturnMessage(String messageParams) async {
    try {
      final Map<String, dynamic> data = jsonDecode(messageParams);
      if (data['eventName'] == 'v2.avatar.exported') {
        final String modelUrl = data['data']['url'];
        // Tải .glb về máy
        await _downloadAndCacheAvatar(modelUrl);
      }
    } catch (e) {
      print("Error parsing avaturn message: $e");
    }
  }

  Future<void> _downloadAndCacheAvatar(String url) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: const CustomLoading(size: 80)),
      );

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.glb';
        final file = File('${dir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);

        // Lưu bản ghi vào SQLite
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.insertAvatar({
          'localId': DateTime.now().millisecondsSinceEpoch.toString(),
          'url': url,
          'localPath': file.path,
          'clientUpdatedAt': DateTime.now().toIso8601String(),
          'isDeleted': 0,
          'isSync': 0, // Flag dirty record cho việc Push Data
        });

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pop(context, file.path); // Trả về màn Profile
        }
      }
    } catch (e) {
      print("Download error: $e");
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lỗi khi tải Avatar 3D")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Avatar 3D'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: const CustomLoading(size: 80)),
        ],
      ),
    );
  }
}
