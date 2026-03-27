import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class GiftQRScreen extends StatefulWidget {
  final String? giftToken; // If provided, show QR. If null, show Scanner.
  const GiftQRScreen({super.key, this.giftToken});

  @override
  State<GiftQRScreen> createState() => _GiftQRScreenState();
}

class _GiftQRScreenState extends State<GiftQRScreen> {
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    if (widget.giftToken != null) {
      _isScanning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isScanning ? 'Quét mã nhận quà' : 'Mã QR của bạn'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isScanning ? _buildScanner() : _buildQRDisplay(),
      floatingActionButton: widget.giftToken == null ? null : FloatingActionButton.extended(
        onPressed: () => setState(() => _isScanning = !_isScanning),
        label: Text(_isScanning ? 'Xem mã của tôi' : 'Quét mã mới'),
        icon: Icon(_isScanning ? Icons.qr_code : Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null) {
                _handleScannedCode(code);
              }
            }
          },
        ),
        // Overlay for better UX
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Di chuyển camera tới mã QR để nhận quà',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRDisplay() {
    final String claimUrl = 'luckyly://claim?token=${widget.giftToken}';
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Đưa mã này cho người nhận để họ quét',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 40),
          Center(
            child: QrImageView(
              data: claimUrl,
              version: QrVersions.auto,
              size: 280.0,
              gapless: false,
              embeddedImage: const AssetImage('assets/images/logo_small.png'),
              embeddedImageStyle: const QrEmbeddedImageStyle(
                size: Size(40, 40),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () {
               // Logic to share link
            },
            icon: const Icon(Icons.share),
            label: const Text('Chia sẻ link nhận quà'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mã này có hiệu lực trong 24 giờ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _handleScannedCode(String code) {
    debugPrint('QR Scanned: $code');
    // Basic validation
    if (code.contains('luckyly://claim?token=')) {
      final token = code.split('token=').last;
      _navigateToClaim(token);
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã QR không hợp lệ')));
    }
  }

  void _navigateToClaim(String token) {
     // Navigator.push(context, MaterialPageRoute(builder: (_) => GiftClaimScreen(token: token)));
  }
}
