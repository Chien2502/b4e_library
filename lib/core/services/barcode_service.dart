import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Kết quả sau khi scan ISBN từ mã vạch.
class BarcodeResult {
  final String isbn;
  BarcodeResult(this.isbn);
}

/// Service quản lý việc scan mã vạch ISBN.
///
/// Không khả dụng trên Web — dùng [isSupported] để kiểm tra trước.
class BarcodeService {
  BarcodeService._();
  static final BarcodeService instance = BarcodeService._();

  /// Trả về false nếu chạy trên Web (mobile_scanner không hỗ trợ Web).
  bool get isSupported => !kIsWeb;

  /// Mở màn hình scan mã vạch và trả về [BarcodeResult] khi quét thành công,
  /// hoặc null nếu người dùng huỷ.
  Future<BarcodeResult?> scanIsbn(BuildContext context) async {
    if (!isSupported) return null;
    return await Navigator.of(context).push<BarcodeResult>(
      MaterialPageRoute(builder: (_) => const _BarcodeScanPage()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal scan page
// ─────────────────────────────────────────────────────────────────────────────

class _BarcodeScanPage extends StatefulWidget {
  const _BarcodeScanPage();

  @override
  State<_BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<_BarcodeScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.code128],
  );

  bool _processed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processed) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    // ISBN thường là EAN-13 (13 chữ số) bắt đầu bằng 978 hoặc 979
    // hoặc ISBN-10 (10 ký tự)
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final isIsbn = (digits.length == 13 &&
            (digits.startsWith('978') || digits.startsWith('979'))) ||
        digits.length == 10 ||
        raw.length == 10;

    if (!isIsbn) return; // Bỏ qua nếu không phải ISBN

    _processed = true;
    _controller.stop();

    if (mounted) {
      Navigator.of(context).pop(BarcodeResult(digits));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan mã vạch ISBN',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay khung scan
          Center(
            child: Container(
              width: 280,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1E88E5), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Hướng dẫn
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Đưa mã vạch ISBN vào khung',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
