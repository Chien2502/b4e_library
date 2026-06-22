import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/network_error_handler.dart';
import '../../core/services/push_notification_service.dart';
import '../../data/models/book_model.dart';
import '../../data/models/book_detail_model.dart';
import '../../viewmodels/auth_provider.dart';

import '../../core/utils/snackbar_utils.dart';
import '../../core/theme/theme_extensions.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/borrow_delivery_bottom_sheet.dart';
import 'login_screen.dart';
import '../../core/utils/page_transitions.dart';


class BookDetailScreen extends StatefulWidget {
  final int bookId;
  final String heroTag; // Dùng cho Hero animation từ card

  const BookDetailScreen({super.key, required this.bookId, this.heroTag = ''});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final DioClient _dioClient = DioClient();

  BookDetail? _book;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isBorrowing = false;
  bool _showRealtimeBorrowedNotice = false;

  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;

  // ── Related books ──────────────────────────────────────────────
  List<Book> _relatedBooks = [];
  bool _isLoadingRelated = false;
  String _relatedType = 'random'; // 'category' hoặc 'random'
  final ScrollController _relatedScrollController = ScrollController();
  bool _isLoadingMoreRelated = false;
  bool _hasMoreRelated = true;

  @override
  void initState() {
    super.initState();
    _fetchBookDetail();
    _setupFCMListener();
    _relatedScrollController.addListener(_onRelatedScroll);
  }

  void _onRelatedScroll() {
    if (_relatedScrollController.position.pixels >=
        _relatedScrollController.position.maxScrollExtent - 50) {
      _loadMoreRelatedBooks();
    }
  }

  void _setupFCMListener() {
    _fcmSubscription = PushNotificationService().bookStatusStream.listen((
      data,
    ) {
      if (data['book_id'] == widget.bookId) {
        final bool isAvail = data['is_available'];

        if (_book != null && _book!.isAvailable && !isAvail) {
          if (mounted) {
            SnackBarUtils.showError(
              context,
              'Rất tiếc, ai đó vừa mượn cuốn sách này vài giây trước.',
            );
          }
          setState(() {
            _showRealtimeBorrowedNotice = true;
          });
        } else if (isAvail) {
          setState(() {
            _showRealtimeBorrowedNotice = false;
          });
        }

        if (mounted && _book != null && _book!.isAvailable != isAvail) {
          setState(() {
            _book!.isAvailable = isAvail;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    _relatedScrollController.dispose();
    super.dispose();
  }

  // ── Gọi API read_single.php?id={bookId} ────────────────────────
  // Tương tự details.js: fetch rồi renderBookDetails()
  Future<void> _fetchBookDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _showRealtimeBorrowedNotice = false;
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
        _fetchRelatedBooks();
      } else if (response.statusCode == 404) {
        setState(() => _errorMessage = 'Không tìm thấy sách.');
      } else {
        setState(() => _errorMessage = 'Lỗi server: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        setState(
          () => _errorMessage = 'Sách này không còn tồn tại hoặc đã bị xóa.',
        );
      } else {
        setState(
          () => _errorMessage = NetworkErrorHandler.getFriendlyMessage(e),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = NetworkErrorHandler.getFriendlyMessage(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Lấy danh sách sách liên quan ──────────────────────────────
  Future<void> _fetchRelatedBooks() async {
    setState(() => _isLoadingRelated = true);
    try {
      final Response res = await _dioClient.dio.get(
        ApiConstants.relatedBooks,
        queryParameters: {'book_id': widget.bookId, 'limit': 10},
      );
      if (res.statusCode == 200 && res.data['data'] != null) {
        final list = (res.data['data'] as List)
            .map((j) => Book.fromJson(j))
            .toList();
        setState(() {
          _relatedBooks = list;
          _relatedType = res.data['type']?.toString() ?? 'random';
          _hasMoreRelated = list.length == 10;
        });
      }
    } catch (_) {
      // Không ảnh hưởng giao diện chính
    } finally {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  Future<void> _loadMoreRelatedBooks() async {
    if (_isLoadingRelated || _isLoadingMoreRelated || !_hasMoreRelated) return;
    setState(() => _isLoadingMoreRelated = true);
    try {
      final Response res = await _dioClient.dio.get(
        ApiConstants.relatedBooks,
        queryParameters: {'book_id': widget.bookId, 'limit': 10},
      );
      if (res.statusCode == 200 && res.data['data'] != null) {
        final list = (res.data['data'] as List)
            .map((j) => Book.fromJson(j))
            .toList();

        int addedCount = 0;
        setState(() {
          for (var book in list) {
            if (!_relatedBooks.any((b) => b.id == book.id)) {
              _relatedBooks.add(book);
              addedCount++;
            }
          }
          if (addedCount == 0) {
            _hasMoreRelated = false;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMoreRelated = false);
    }
  }

  Future<void> _handleBorrow() async {
    if (_book == null || !_book!.isAvailable) return;

    // ── Kiểm tra auth trước khi mượn ──────────────────────────────
    final auth = context.read<AuthProvider>();
    if (auth.status != AuthStatus.authenticated) {
      _showLoginPrompt();
      return;
    }

    // ── Mở Bottom Sheet chọn hình thức mượn ───────────────────────
    final success = await BorrowDeliveryBottomSheet.show(
      context,
      bookId: widget.bookId,
      bookTitle: _book!.title,
    );

    if (success == true && mounted) {
      await _fetchBookDetail();
    }
  }

  /// Hiển thị bottom sheet mời đăng nhập khi chưa có tài khoản
  void _showLoginPrompt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: ctx.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.lock_outline, color: Color(0xFF1E88E5), size: 40),
            const SizedBox(height: 12),
            const Text(
              'Đăng nhập để mượn sách',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn cần có tài khoản B4E để có thể mượn sách.\nĐăng nhập miễn phí, nhanh chóng!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ctx.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // đóng bottom sheet
                  // Push LoginScreen, sau khi login chỉ pop về book detail
                  Navigator.push(
                    context,
                    FadeSlideRoute(
                      page: const LoginScreen(popOnSuccess: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Để sau',
                style: TextStyle(color: ctx.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chi tiết sách',
          style: TextStyle(
            color: context.textPrimary,
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
            Icon(Icons.error_outline, color: context.colors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.error),
            ),
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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Ảnh + Tên + Badge ──────────────────
          _buildHeader(book),

          if (_showRealtimeBorrowedNotice)
            _buildRealtimeBorrowedNotice(),

          // ── Nút mượn sách ─────────────────────────────
          _buildBorrowButton(book, isAvailable),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: context.divider.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),
          ),

          // ── Thông tin chi tiết ─────────────────────────
          _buildInfoSection(book),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Divider(color: context.divider.withValues(alpha: 0.3), height: 1, indent: 20, endIndent: 20),
          ),

          // ── Mô tả ──────────────────────────────────────
          if (book.description.isNotEmpty)
            _buildDescriptionSection(book.description),

          const SizedBox(height: 8),

          // ── Sách liên quan / Đề xuất ────────────────────
          _buildRelatedBooksSection(),

          const SizedBox(height: 40), // Khoảng trống dưới cùng
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // SECTION 1: Header — Ảnh bìa + Tiêu đề + Badge trạng thái
  // Layout: Ảnh bên trái, thông tin bên phải (giống web reference)
  // ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BookDetail book) {
    return Stack(
      children: [
        // 1. Ảnh bìa nền làm mờ (Blur Background)
        Positioned.fill(
          child: ClipRect(
            child: ShaderMask(
              // Gradient che phủ giúp ảnh mờ hòa quyện và biến mất dần về phía dưới
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.75, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: book.displayImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book.displayImageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        httpHeaders: kIsWeb
                            ? const {'ngrok-skip-browser-warning': 'true'}
                            : const {},
                      )
                    : Container(color: context.card),
              ),
            ),
          ),
        ),

        // Lớp tint phủ (overlay color) làm dịu ảnh nền mờ theo màu chủ đạo của theme
        Positioned.fill(
          child: Container(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.4),
          ),
        ),

        // 2. Nội dung chính: Ảnh bìa sắc nét + Thông tin
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ảnh bìa sách (Centered & Large)
              Hero(
                tag: widget.heroTag.isNotEmpty ? widget.heroTag : 'book_${book.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 150,
                      height: 215,
                      child: book.displayImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: book.displayImageUrl,
                              fit: BoxFit.cover,
                              httpHeaders: kIsWeb
                                  ? const {'ngrok-skip-browser-warning': 'true'}
                                  : const {},
                              placeholder: (context, url) => _buildImagePlaceholder(),
                              errorWidget: (context, url, error) =>
                                  _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

          // Tên sách (Centered)
          Text(
            book.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Tác giả (Centered)
          Text(
            book.author.isNotEmpty ? book.author : 'Chưa rõ tác giả',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Badge trạng thái (Centered)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: book.isAvailable
                  ? (context.isDarkMode
                      ? Colors.green.withValues(alpha: 0.15)
                      : const Color(0xFFE8F5E9))
                  : (book.isBusy
                      ? (context.isDarkMode
                          ? Colors.amber.withValues(alpha: 0.15)
                          : const Color(0xFFFFFDE7))
                      : (context.isDarkMode
                          ? Colors.orange.withValues(alpha: 0.15)
                          : const Color(0xFFFFF3E0))),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: book.isAvailable
                    ? Colors.green
                    : (book.isBusy ? Colors.amber[700]! : Colors.orange),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  book.isAvailable
                      ? Icons.check_circle_outline
                      : (book.isBusy ? Icons.hourglass_empty : Icons.access_time),
                  size: 14,
                  color: book.isAvailable
                      ? (context.isDarkMode ? Colors.green[300] : Colors.green[700])
                      : (book.isBusy
                          ? (context.isDarkMode ? Colors.amber[300] : Colors.amber[700])
                          : (context.isDarkMode ? Colors.orange[300] : Colors.orange[700])),
                ),
                const SizedBox(width: 6),
                Text(
                  book.isAvailable
                      ? 'Có sẵn'
                      : (book.isBusy ? 'Đang bận' : 'Đã mượn'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: book.isAvailable
                        ? (context.isDarkMode ? Colors.green[300] : Colors.green[700])
                        : (book.isBusy
                            ? (context.isDarkMode ? Colors.amber[300] : Colors.amber[700])
                            : (context.isDarkMode ? Colors.orange[300] : Colors.orange[700])),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ],
);
}

  // ────────────────────────────────────────────────────────────────
  // SECTION 2: Thông tin meta (Tác giả, Thể loại, Năm XB, NXB)
  // ────────────────────────────────────────────────────────────────
  Widget _buildInfoSection(BookDetail book) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          Icon(icon, size: 18, color: context.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, thickness: 0.5, color: context.divider);

  // ────────────────────────────────────────────────────────────────
  // SECTION 3: Mô tả sách
  // ────────────────────────────────────────────────────────────────
  Widget _buildDescriptionSection(String description) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
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
  Widget _buildBorrowButton(BookDetail book, bool isAvailable) {
    final bool isBusy = book.isBusy;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: isAvailable
            ? ElevatedButton.icon(
                onPressed: _isBorrowing ? null : _handleBorrow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  disabledBackgroundColor: context.colors.primary.withValues(
                    alpha: 0.6,
                  ),
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
                    : const Icon(
                        Icons.book_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
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
                  side: BorderSide(color: isBusy ? Colors.amber[300]! : Colors.orange[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  isBusy ? Icons.hourglass_empty : Icons.access_time,
                  color: isBusy ? Colors.amber[400] : Colors.orange[400],
                  size: 20,
                ),
                label: Text(
                  isBusy ? 'Sách đang bận giao dịch' : 'Sách đang được mượn',
                  style: TextStyle(
                    color: isBusy ? Colors.amber[700] : Colors.orange[700],
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRealtimeBorrowedNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0x29FF9800)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange[400]!,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sách đã được mượn',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.isDarkMode
                        ? Colors.orange[300]
                        : Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rất tiếc, đã có người nhanh tay mượn cuốn sách này trước. Vui lòng tham khảo những quyển sách khác!',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: context.divider.withValues(alpha: 0.5),
      child: Center(
        child: Icon(Icons.menu_book_outlined, size: 50, color: context.textSecondary),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // SECTION 4: Sách liên quan / Đề xuất
  // ────────────────────────────────────────────────────────────────
  Widget _buildRelatedBooksSection() {
    // Nếu đang load hoặc danh sách rỗng → ẩn hoặc shimmer
    if (_isLoadingRelated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: context.divider,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, r) => const SizedBox(width: 12),
                itemBuilder: (_, i) => Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: context.divider.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_relatedBooks.isEmpty) return const SizedBox.shrink();

    // Tiêu đề dựa trên loại gợi ý
    final sectionTitle = _relatedType == 'category'
        ? 'Sách cùng thể loại'
        : 'Có thể bạn quan tâm';
    final sectionIcon = _relatedType == 'category'
        ? Icons.category_rounded
        : Icons.auto_awesome_rounded;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tiêu đề ───────────────────────────────────────────
          Row(
            children: [
              Icon(sectionIcon, size: 20, color: context.colors.primary),
              const SizedBox(width: 8),
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Danh sách cuộn ngang ──────────────────────────────
          SizedBox(
            height: 210,
            child: ListView.separated(
              controller: _relatedScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _relatedBooks.length + (_isLoadingMoreRelated ? 1 : 0),
              separatorBuilder: (_, r) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                if (i == _relatedBooks.length) {
                  return const SizedBox(
                    width: 50,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return _buildRelatedBookCard(_relatedBooks[i]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedBookCard(Book book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(
              bookId: book.id,
              heroTag: 'related_${book.id}',
            ),
          ),
        );
      },
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa
            Hero(
              tag: 'related_${book.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 120,
                  height: 155,
                  child:
                      book.displayImageUrl.isNotEmpty &&
                          !book.displayImageUrl.contains('placeholder')
                      ? CachedNetworkImage(
                          imageUrl: book.displayImageUrl,
                          fit: BoxFit.cover,
                          httpHeaders: kIsWeb
                              ? const {'ngrok-skip-browser-warning': 'true'}
                              : const {},
                          placeholder: (context, url) => _buildMiniPlaceholder(),
                          errorWidget: (context, url, error) => _buildMiniPlaceholder(),
                        )
                      : _buildMiniPlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Tên sách
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlaceholder() {
    return Container(
      color: context.divider.withValues(alpha: 0.5),
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 30,
          color: context.textSecondary,
        ),
      ),
    );
  }
}

class _BorrowConfirmDialog extends StatefulWidget {
  final String bookTitle;

  const _BorrowConfirmDialog({required this.bookTitle});

  @override
  State<_BorrowConfirmDialog> createState() => _BorrowConfirmDialogState();
}

class _BorrowConfirmDialogState extends State<_BorrowConfirmDialog> {
  int _borrowDays = 14;

  @override
  Widget build(BuildContext context) {
    final returnDate = DateTime.now().add(Duration(days: _borrowDays));
    final returnDateStr = "${returnDate.day.toString().padLeft(2, '0')}/${returnDate.month.toString().padLeft(2, '0')}/${returnDate.year}";

    return CustomDialog(
      title: 'Tùy chọn mượn sách',
      message: 'Bạn muốn mượn cuốn "${widget.bookTitle}" trong bao lâu?',
      icon: Icons.calendar_month_rounded,
      iconColor: Colors.blueAccent,
      confirmLabel: 'Xác nhận mượn',
      onConfirm: () => Navigator.pop(context, _borrowDays),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Số ngày mượn:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$_borrowDays ngày', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _borrowDays.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            activeColor: const Color(0xFF1565C0),
            label: '$_borrowDays ngày',
            onChanged: (val) => setState(() => _borrowDays = val.toInt()),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Color(0xFF1565C0), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hạn trả: $returnDateStr',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
