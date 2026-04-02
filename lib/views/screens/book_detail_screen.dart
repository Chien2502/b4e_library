import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/book_detail_model.dart';

class BookDetailScreen extends StatefulWidget {
  final int bookId;
  final String heroTag; // Dùng cho Hero animation từ card

  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.heroTag = '',
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final DioClient _dioClient = DioClient();

  BookDetail? _book;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isBorrowing = false;

  @override
  void initState() {
    super.initState();
    _fetchBookDetail();
  }

  // ── Gọi API read_single.php?id={bookId} ────────────────────────
  // Tương tự details.js: fetch rồi renderBookDetails()
  Future<void> _fetchBookDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final Response response = await _dioClient.dio.get(
        ApiConstants.readSingleBook,
        queryParameters: {'id': widget.bookId},
      );

      if (response.statusCode == 200) {
        setState(() {
          _book = BookDetail.fromJson(response.data);
        });
      } else if (response.statusCode == 404) {
        setState(() => _errorMessage = 'Không tìm thấy sách.');
      } else {
        setState(() => _errorMessage = 'Lỗi server: ${response.statusCode}');
      }
    } on DioException catch (e) {
      setState(() => _errorMessage = 'Lỗi kết nối: ${e.message ?? e.type.name}');
    } catch (e) {
      setState(() => _errorMessage = 'Đã xảy ra lỗi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBorrow() async {
    if (_book == null || !_book!.isAvailable) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận mượn sách'),
        content: Text('Bạn muốn mượn cuốn "${_book!.title}"?\n\nHạn trả: 14 ngày kể từ hôm nay.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBorrowing = true);

    try {
      final Response res = await _dioClient.dio.post(
        ApiConstants.createBorrowing,
        data: {'book_id': widget.bookId},
      );

      if (res.statusCode == 201) {
        _showSnackBar('Mượn sách thành công! Vui lòng trả đúng hạn. 📚',
            isError: false);
        // Tải lại chi tiết để cập nhật trạng thái badge
        await _fetchBookDetail();
        // Trả về true để màn hình danh sách biết cần reload
        if (mounted) Navigator.pop(context, true);
      } else {
        final msg = res.data?['error'] ?? 'Không thể mượn sách.';
        _showSnackBar(msg, isError: true);
      }
    } on DioException catch (e) {
      final serverMsg = e.response?.data?['error'];
      _showSnackBar(serverMsg ?? 'Lỗi kết nối: ${e.message}', isError: true);
    } finally {
      setState(() => _isBorrowing = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết sách',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchBookDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_book == null) return const SizedBox.shrink();

    final book = _book!;
    final isAvailable = book.isAvailable;

    return Column(
      children: [
        // ── Nội dung cuộn được ──────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Ảnh + Tên + Badge ──────────────────
                _buildHeader(book),

                const SizedBox(height: 20),

                // ── Thông tin chi tiết ─────────────────────────
                _buildInfoSection(book),

                const SizedBox(height: 20),

                // ── Mô tả ──────────────────────────────────────
                if (book.description.isNotEmpty)
                  _buildDescriptionSection(book.description),

                const SizedBox(height: 100), // Khoảng trống cho nút phía dưới
              ],
            ),
          ),
        ),

        // ── Nút hành động cố định ──────────────────────────────
        _buildBottomAction(book, isAvailable),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // SECTION 1: Header — Ảnh bìa + Tiêu đề + Badge trạng thái
  // Layout: Ảnh bên trái, thông tin bên phải (giống web reference)
  // ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BookDetail book) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh bìa sách
          Hero(
            tag: widget.heroTag.isNotEmpty
                ? widget.heroTag
                : 'book_${book.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 130,
                height: 180,
                child: book.displayImageUrl.isNotEmpty
                    ? Image.network(
                        book.displayImageUrl,
                        fit: BoxFit.cover,
                        headers: kIsWeb
                            ? const {'ngrok-skip-browser-warning': 'true'}
                            : const {},
                        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                      )
                    : _buildImagePlaceholder(),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Tiêu đề + badge trạng thái
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                // Tên sách
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0), // Xanh đậm — giống web
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 10),

                // Badge trạng thái
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: book.isAvailable
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: book.isAvailable
                          ? Colors.green
                          : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        book.isAvailable
                            ? Icons.check_circle_outline
                            : Icons.access_time,
                        size: 14,
                        color: book.isAvailable
                            ? Colors.green[700]
                            : Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        book.isAvailable ? 'Có sẵn' : 'Đã mượn',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: book.isAvailable
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // SECTION 2: Thông tin meta (Tác giả, Thể loại, Năm XB, NXB)
  // ────────────────────────────────────────────────────────────────
  Widget _buildInfoSection(BookDetail book) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.person_outline,
            label: 'Tác giả',
            value: book.author.isNotEmpty ? book.author : 'Chưa rõ',
            valueColor: const Color(0xFF1565C0),
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Thể loại',
            value: book.categoryName,
            valueColor: const Color(0xFF1565C0),
          ),
          if (book.year.isNotEmpty) ...[
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Năm xuất bản',
              value: book.year,
            ),
          ],
          if (book.publisher.isNotEmpty) ...[
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.business_outlined,
              label: 'Nhà xuất bản',
              value: book.publisher,
              valueColor: const Color(0xFF1565C0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F0F0));

  // ────────────────────────────────────────────────────────────────
  // SECTION 3: Mô tả sách
  // ────────────────────────────────────────────────────────────────
  Widget _buildDescriptionSection(String description) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // BOTTOM: Nút Mượn sách / trạng thái Đã mượn (cố định ở đáy)
  // ────────────────────────────────────────────────────────────────
  Widget _buildBottomAction(BookDetail book, bool isAvailable) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: isAvailable
            ? ElevatedButton.icon(
                onPressed: _isBorrowing ? null : _handleBorrow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  disabledBackgroundColor: Colors.blueAccent.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: _isBorrowing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.book_outlined,
                        color: Colors.white, size: 20),
                label: Text(
                  _isBorrowing ? 'Đang xử lý...' : 'Mượn sách này',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : OutlinedButton.icon(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(Icons.access_time,
                    color: Colors.orange[400], size: 20),
                label: Text(
                  'Sách đang được mượn',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.menu_book_outlined, size: 50, color: Colors.grey),
      ),
    );
  }
}
