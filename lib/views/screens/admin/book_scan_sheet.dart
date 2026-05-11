import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/barcode_service.dart';
import '../../../core/services/book_ai_service.dart';
import '../../../core/utils/snackbar_utils.dart';

/// Bottom sheet để chọn phương thức nhập thông tin sách tự động.
///
/// [onResult] được gọi sau khi scan/phân tích hoàn tất.
/// [showBarcodeOption] = false để ẩn nút scan mã vạch.
///
/// QUAN TRỌNG: Phải là StatefulWidget để giữ context an toàn
/// qua các async gap sau khi sheet bị pop.
class BookScanSheet extends StatefulWidget {
  final void Function(BookLookupResult result, File? scannedImage) onResult;
  final bool showBarcodeOption;

  const BookScanSheet({
    super.key,
    required this.onResult,
    this.showBarcodeOption = true,
  });

  @override
  State<BookScanSheet> createState() => _BookScanSheetState();
}

class _BookScanSheetState extends State<BookScanSheet> {

  // ── Barcode scan ─────────────────────────────────────────────────────────────

  Future<void> _scanBarcode() async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);
    nav.pop(); // Đóng sheet

    final result = await BarcodeService.instance.scanIsbn(context);
    if (result == null) return;

    // Hiện loading trên root navigator (không bị ảnh hưởng bởi sheet đã pop)
    _showGlobalLoadingOn(rootNav, 'Đang tra cứu ISBN ${result.isbn}...');

    final bookResult = await BookAiService.instance.lookupByIsbn(result.isbn);

    rootNav.pop(); // Đóng loading
    widget.onResult(bookResult, null);
  }

  // ── Camera / Gallery ─────────────────────────────────────────────────────────

  Future<void> _analyzeWithSource(ImageSource source) async {
    if (!mounted) return;
    // Capture trước khi bất kỳ await nào
    final nav = Navigator.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);

    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: source,
        imageQuality: 50, // Giảm chất lượng xuống 50%
        maxWidth: 600,    // Giới hạn chiều ngang 600px để file siêu nhẹ (< 100KB)
      );
    } catch (e) {
      SnackBarUtils.showError(context, source == ImageSource.camera
          ? 'Không thể mở camera: $e'
          : 'Không thể mở thư viện ảnh: $e');
      return;
    }

    if (picked == null) return;

    nav.pop(); // Đóng sheet
    _showGlobalLoadingOn(rootNav, 'AI đang phân tích bìa sách...');

    BookLookupResult bookResult;
    try {
      bookResult =
          await BookAiService.instance.analyzeBookCover(File(picked.path));
    } catch (e) {
      bookResult = BookLookupResult(error: 'Lỗi phân tích: $e');
    }

    rootNav.pop(); // Đóng loading
    widget.onResult(bookResult, File(picked.path));
  }

  // ── Loading helpers ───────────────────────────────────────────────────────────

  void _showGlobalLoadingOn(NavigatorState nav, String msg) {
    nav.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black38,
        pageBuilder: (context, animation, secondaryAnimation) =>
            _LoadingDialog(message: msg),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Thêm sách nhanh',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 6),
          Text('Chọn phương thức điền thông tin sách',
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Option 1: Barcode
          if (widget.showBarcodeOption) ...[
            _Option(
              icon: Icons.qr_code_scanner,
              color: const Color(0xFF1E88E5),
              title: 'Scan mã vạch ISBN',
              subtitle: 'Quét barcode trên bìa/gáy sách để tra cứu tự động',
              onTap: _scanBarcode,
            ),
            const SizedBox(height: 12),
          ],

          // Option 2: AI Cover — camera
          _Option(
            icon: Icons.photo_camera_outlined,
            color: const Color(0xFF7C4DFF),
            title: 'Chụp ảnh bìa sách (AI)',
            subtitle: 'Mở camera và chụp ảnh bìa để AI nhận diện',
            onTap: () => _analyzeWithSource(ImageSource.camera),
          ),
          const SizedBox(height: 12),

          // Option 3: AI Cover — gallery
          _Option(
            icon: Icons.photo_library_outlined,
            color: const Color(0xFF00897B),
            title: 'Chọn ảnh từ thư viện (AI)',
            subtitle: 'Chọn ảnh bìa sẵn có trên máy để AI nhận diện',
            onTap: () => _analyzeWithSource(ImageSource.gallery),
          ),
          const SizedBox(height: 12),

          // Option 4: Manual
          _Option(
            icon: Icons.edit_outlined,
            color: Colors.grey[600]!,
            title: 'Nhập tay',
            subtitle: 'Điền thủ công thông tin sách vào form',
            onTap: () {
              Navigator.of(context).pop();
              widget.onResult(const BookLookupResult(), null);
            },
          ),
        ],
      ),
    );
  }
}

// ── Loading dialog (tách riêng widget để tránh capture context cũ) ────────────

class _LoadingDialog extends StatelessWidget {
  final String message;
  const _LoadingDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF1E88E5)),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Option tile ───────────────────────────────────────────────────────────────

class _Option extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
