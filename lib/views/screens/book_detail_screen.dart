import 'dart:async';
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
import '../../viewmodels/notification_provider.dart';
import '../../core/utils/snackbar_utils.dart';
import '../widgets/custom_dialog.dart';
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Xác nhận mượn sách',
        message:
            'Bạn muốn mượn cuốn "${_book!.title}"?\n\nHạn trả dự kiến: 14 ngày kể từ hôm nay.',
        icon: Icons.auto_stories_rounded,
        iconColor: Colors.blueAccent,
        confirmLabel: 'Mượn ngay',
        onConfirm: () => Navigator.pop(ctx, true),
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
        SnackBarUtils.showSuccess(
          context,
          'Mượn sách thành công! Vui lòng trả đúng hạn.',
        );
        // Fetch ngay để badge đỏ hiện lên tức thì
        if (mounted) {
          context.read<NotificationProvider>().fetchNotifications();
        }
        await _fetchBookDetail();
        if (mounted) Navigator.pop(context, true);
      } else {
        final msg = res.data?['error'] ?? 'Không thể mượn sách.';
        SnackBarUtils.showError(context, msg);
      }
    } on DioException catch (e) {
      SnackBarUtils.showError(context, NetworkErrorHandler.getFriendlyMessage(e));
    } finally {
      setState(() => _isBorrowing = false);
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
                color: Colors.grey[300],
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
                color: Colors.grey[600],
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
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
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
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
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

                const SizedBox(height: 16),

                // ── Sách liên quan / Đề xuất ────────────────────
                _buildRelatedBooksSection(),

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
            tag: widget.heroTag.isNotEmpty ? widget.heroTag : 'book_${book.id}',
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
                        errorBuilder: (_, err, stack) =>
                            _buildImagePlaceholder(),
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
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: book.isAvailable
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: book.isAvailable ? Colors.green : Colors.orange,
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
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                  disabledBackgroundColor: Colors.blueAccent.withValues(
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
                  side: BorderSide(color: Colors.orange[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  Icons.access_time,
                  color: Colors.orange[400],
                  size: 20,
                ),
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

  // ────────────────────────────────────────────────────────────────
  // SECTION 4: Sách liên quan / Đề xuất
  // ────────────────────────────────────────────────────────────────
  Widget _buildRelatedBooksSection() {
    // Nếu đang load hoặc danh sách rỗng → ẩn hoặc shimmer
    if (_isLoadingRelated) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, __) => Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tiêu đề ───────────────────────────────────────────
          Row(
            children: [
              Icon(sectionIcon, size: 20, color: const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text(
                sectionTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
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
              separatorBuilder: (_, __) => const SizedBox(width: 12),
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
                      ? Image.network(
                          book.displayImageUrl,
                          fit: BoxFit.cover,
                          headers: kIsWeb
                              ? const {'ngrok-skip-browser-warning': 'true'}
                              : const {},
                          errorBuilder: (_, __, ___) => _buildMiniPlaceholder(),
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 30,
          color: Colors.grey[400],
        ),
      ),
    );
  }
}
