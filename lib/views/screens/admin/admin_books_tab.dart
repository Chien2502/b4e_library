import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_error_handler.dart';
import '../../../core/services/book_ai_service.dart';
import '../../../viewmodels/book_provider.dart';
import '../../../viewmodels/recommendation_provider.dart';
import '../../widgets/custom_dialog.dart';
import 'book_scan_sheet.dart';
import '../../../core/utils/snackbar_utils.dart';

class AdminBooksTab extends StatefulWidget {
  const AdminBooksTab({super.key});
  @override
  State<AdminBooksTab> createState() => _AdminBooksTabState();
}

class _AdminBooksTabState extends State<AdminBooksTab> {
  final _dio = DioClient().dio;
  List<Map<String, dynamic>> _books = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int _currentPage = 1;
  int _totalPages = 1;
  Timer? _debounce;

  // ── Bộ lọc ──────────────────────────────────────────────────
  String? _selectedStatus;        // null = tất cả, 'available', 'borrowed'
  int? _selectedCategoryId;       // null = tất cả thể loại

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({bool resetPage = false}) async {
    if (resetPage) _currentPage = 1;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (mounted) {
        Future.microtask(() {
          if (mounted) {
            Provider.of<BookProvider>(
              context,
              listen: false,
            ).fetchLatestBooks(forceRefresh: true);
            Provider.of<RecommendationProvider>(
              context,
              listen: false,
            ).fetchPopular(forceRefresh: true);
            Provider.of<RecommendationProvider>(
              context,
              listen: false,
            ).fetchRecommendations(forceRefresh: true);
          }
        });
      }
      final futures = await Future.wait([
        _dio.get(
          ApiConstants.readBooks,
          queryParameters: {
            'page': _currentPage,
            'limit': 10,
            if (_search.isNotEmpty) 'search': _search,
            if (_selectedStatus != null) 'status': _selectedStatus!,
            if (_selectedCategoryId != null)
              'category_id': _selectedCategoryId!,
          },
        ),
        _categories.isEmpty
            ? _dio.get(ApiConstants.readCategories)
            : Future.value(null),
      ]);
      // Books
      final bookRaw = futures[0]!.data;
      List<Map<String, dynamic>> books = [];
      if (bookRaw is List) {
        books = List<Map<String, dynamic>>.from(bookRaw);
      } else if (bookRaw is Map) {
        books = List<Map<String, dynamic>>.from(
          bookRaw['data'] ?? bookRaw['records'] ?? [],
        );

        final pagination = bookRaw['pagination'];
        if (pagination != null) {
          _totalPages =
              int.tryParse(pagination['total_pages']?.toString() ?? '1') ?? 1;
          _currentPage =
              int.tryParse(pagination['current_page']?.toString() ?? '1') ?? 1;
        }
      }
      // Categories
      List<Map<String, dynamic>> cats = _categories;
      if (futures[1] != null && futures[1]!.data != null) {
        final catRaw = futures[1]!.data;
        if (catRaw is List) {
          cats = List<Map<String, dynamic>>.from(catRaw);
        } else if (catRaw is Map) {
          cats = List<Map<String, dynamic>>.from(
            catRaw['data'] ?? catRaw['records'] ?? [],
          );
        }
      }
      setState(() {
        _books = books;
        _categories = cats;
      });
    } on DioException catch (e) {
      setState(() => _error = NetworkErrorHandler.getFriendlyMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteBook(int id, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Xóa sách',
        message:
            'Bạn có chắc muốn xóa cuốn "$title"? Hành động này không thể hoàn tác.',
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.red,
        confirmLabel: 'Xóa ngay',
        confirmColor: Colors.red,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok != true) return;
    try {
      await _dio.post(ApiConstants.deleteBook, data: {'id': id});
      if (!mounted) return;
      _showSnack('Đã xóa sách "$title".', false);
      _loadAll();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['error'] ?? 'Lỗi xóa sách', true);
    }
  }

  void _openForm({Map<String, dynamic>? book}) {
    if (book != null) {
      // Chỉnh sửa — mở thẳng form
      _showBookForm(book: book);
    } else {
      // Thêm mới — hỏi phương thức nhập trước
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BookScanSheet(
          showBarcodeOption: true,
          onResult: (result, scannedImage) {
            if (!result.isSuccess && !result.isNotABook) {
              _showSnack(result.error ?? 'Không thể nhận dạng sách.', true);
              return;
            }
            if (result.isNotABook) {
              _showSnack('AI không nhận ra bìa sách. Vui lòng nhập tay.', true);
              _showBookForm();
              return;
            }
            _showBookForm(prefill: result, scannedImage: scannedImage);
          },
        ),
      );
    }
  }

  void _showBookForm({
    Map<String, dynamic>? book,
    BookLookupResult? prefill,
    File? scannedImage,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookFormSheet(
        book: book,
        prefill: prefill,
        scannedImage: scannedImage,
        categories: _categories,
        dio: _dio,
        onSaved: () {
          Navigator.pop(ctx);
          _loadAll();
        },
      ),
    );
  }

  void _showSnack(String msg, bool err) {
    if (!mounted) return;
    if (err) {
      SnackBarUtils.showError(context, msg);
    } else {
      SnackBarUtils.showSuccess(context, msg);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    var result = _books;

    // Lọc theo trạng thái (client-side fallback)
    if (_selectedStatus != null) {
      result = result.where((b) {
        final s = (b['status'] ?? 'available').toString();
        return s == _selectedStatus;
      }).toList();
    }

    // Lọc theo thể loại (client-side fallback)
    if (_selectedCategoryId != null) {
      result = result.where((b) {
        final cId = int.tryParse('${b['category_id'] ?? ''}');
        return cId == _selectedCategoryId;
      }).toList();
    }

    // Lọc theo search text
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      result = result.where((b) {
        final title = (b['title'] ?? '').toLowerCase();
        final author = (b['author'] ?? '').toLowerCase();
        return title.contains(q) || author.contains(q);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTitleBar(),
        _buildSearchBar(),
        _buildFilterRow(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildTitleBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: Color(0xFF1565C0), size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Quản lý Sách',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text(
              'Thêm sách',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadAll,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        onChanged: (v) {
          setState(() => _search = v);
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 2000), () {
            _loadAll(resetPage: true);
          });
        },
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên sách, tác giả...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Trạng thái: Tất cả / Có sẵn / Đã mượn ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip(null, 'Tất cả', Icons.library_books_outlined),
                const SizedBox(width: 8),
                _statusChip('available', 'Có sẵn', Icons.check_circle_outline),
                const SizedBox(width: 8),
                _statusChip('borrowed', 'Đã mượn', Icons.access_time),
                const SizedBox(width: 12),
                // ── Dropdown thể loại ──
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedCategoryId,
                      isDense: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.blueAccent,
                      ),
                      hint: Text(
                        'Thể loại',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0)),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Tất cả thể loại',
                              style: TextStyle(fontSize: 12, color: Colors.black87)),
                        ),
                        ..._categories.map((cat) {
                          final catId = int.tryParse('${cat['id']}') ?? 0;
                          final catName = cat['name'] ?? '---';
                          return DropdownMenuItem<int?>(
                            value: catId,
                            child: Text(catName,
                                style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          );
                        }),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedCategoryId = v);
                        _loadAll(resetPage: true);
                      },
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

  Widget _statusChip(String? status, String label, IconData icon) {
    final isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedStatus = status);
        _loadAll(resetPage: true);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1565C0).withAlpha(20)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1565C0) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF1565C0) : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF1565C0) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Text(
          _search.isEmpty ? 'Chưa có sách nào' : 'Không tìm thấy kết quả',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadAll(resetPage: true),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: list.length,
              separatorBuilder: (_, a) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _buildCard(list[i]),
            ),
          ),
        ),
        _buildPagination(),
      ],
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentPage > 1
                  ? () {
                      _currentPage--;
                      _loadAll();
                    }
                  : null,
              color: const Color(0xFF1565C0),
            ),
            const SizedBox(width: 8),
            Text(
              'Trang $_currentPage / $_totalPages',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentPage < _totalPages
                  ? () {
                      _currentPage++;
                      _loadAll();
                    }
                  : null,
              color: const Color(0xFF1565C0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> book) {
    final id = int.tryParse('${book['id']}') ?? 0;
    final title = book['title'] ?? '---';
    final author = book['author'] ?? '---';
    final catName = book['category_name'] ?? book['categoryName'] ?? '---';
    final status = book['status'] ?? 'available';
    final imageUrl = '${ApiConstants.uploadsUrl}/${book['image_url'] ?? ''}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cover
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(14),
            ),
            child: SizedBox(
              width: 64,
              height: 84,
              child: (book['image_url'] ?? '').toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      httpHeaders: kIsWeb
                          ? const {'ngrok-skip-browser-warning': 'true'}
                          : const {},
                      placeholder: (context, url) => _placeholder(),
                      errorWidget: (context, url, error) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    author,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          catName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'available'
                              ? Colors.green.withAlpha(20)
                              : Colors.orange.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status == 'available' ? 'Có sẵn' : 'Đã mượn',
                          style: TextStyle(
                            fontSize: 10,
                            color: status == 'available'
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Actions
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Color(0xFF1565C0),
                  ),
                  onPressed: () => _openForm(book: book),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.red[600],
                  ),
                  onPressed: () => _deleteBook(id, title),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.grey[200],
    child: const Icon(Icons.menu_book_outlined, size: 28, color: Colors.grey),
  );
}

// ── Form thêm/sửa sách ──────────────────────────────────────────────
class _BookFormSheet extends StatefulWidget {
  final Map<String, dynamic>? book;
  final BookLookupResult? prefill; // Dữ liệu tự động điền từ AI / ISBN scan
  final File? scannedImage; // Ảnh chụp được từ AI
  final List<Map<String, dynamic>> categories;
  final Dio dio;
  final VoidCallback onSaved;

  const _BookFormSheet({
    this.book,
    this.prefill,
    this.scannedImage,
    required this.categories,
    required this.dio,
    required this.onSaved,
  });

  @override
  State<_BookFormSheet> createState() => _BookFormSheetState();
}

class _BookFormSheetState extends State<_BookFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _authorCtrl;
  late TextEditingController _publisherCtrl;
  late TextEditingController _yearCtrl;
  late TextEditingController _descCtrl;
  int? _categoryId;
  bool _saving = false;

  // ── Image picker state ──────────────────────────────────────────
  XFile? _pickedImage;
  bool _imageChanged = false;

  bool get _isEdit => widget.book != null;

  String get _existingImageUrl {
    final raw = (widget.book?['image_url'] ?? '').toString();
    if (raw.isEmpty) return '';
    return '${ApiConstants.uploadsUrl}/$raw';
  }

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    final p = widget.prefill;
    // Nhập dữ liệu: ưu tiên book (đang sửa) → prefill (từ AI) → rỗng
    _titleCtrl = TextEditingController(
      text: b?['title']?.toString() ?? p?.title ?? '',
    );
    _authorCtrl = TextEditingController(
      text: b?['author']?.toString() ?? p?.author ?? '',
    );
    _publisherCtrl = TextEditingController(
      text: b?['publisher']?.toString() ?? p?.publisher ?? '',
    );
    _yearCtrl = TextEditingController(
      text: b?['year']?.toString() ?? p?.publishYear?.toString() ?? '',
    );
    _descCtrl = TextEditingController(
      text: b?['description']?.toString() ?? p?.description ?? '',
    );
    _categoryId = b != null ? int.tryParse('${b['category_id']}') : null;

    if (widget.scannedImage != null) {
      _pickedImage = XFile(widget.scannedImage!.path);
      _imageChanged = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _publisherCtrl.dispose();
    _yearCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Chọn ảnh từ Gallery hoặc Camera ────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() {
        _pickedImage = file;
        _imageChanged = true;
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Chọn ảnh bìa',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF1565C0),
                  ),
                ),
                title: const Text('Chọn từ thư viện ảnh'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (!kIsWeb)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E5F5),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.purple,
                    ),
                  ),
                  title: const Text('Chụp ảnh mới'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Lưu sách ────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final fields = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'author': _authorCtrl.text.trim(),
        'publisher': _publisherCtrl.text.trim(),
        'year': _yearCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        if (_categoryId != null) 'category_id': _categoryId.toString(),
        if (_isEdit) 'id': '${widget.book!['id']}',
      };
      final data = FormData.fromMap(fields);

      // Gắn ảnh nếu user đã chọn ảnh mới
      if (_imageChanged && _pickedImage != null) {
        final filename = _pickedImage!.name;
        if (kIsWeb) {
          final bytes = await _pickedImage!.readAsBytes();
          data.files.add(
            MapEntry(
              'image',
              MultipartFile.fromBytes(bytes, filename: filename),
            ),
          );
        } else {
          data.files.add(
            MapEntry(
              'image',
              await MultipartFile.fromFile(
                _pickedImage!.path,
                filename: filename,
              ),
            ),
          );
        }
      }

      if (_isEdit) {
        await widget.dio.post(ApiConstants.updateBook, data: data);
      } else {
        await widget.dio.post(ApiConstants.createBook, data: data);
      }

      if (!mounted) return;
      SnackBarUtils.showSuccess(
        context,
        _isEdit ? '✅ Cập nhật sách thành công!' : '✅ Thêm sách thành công!',
      );
      widget.onSaved();
    } on DioException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.response?.data?['error'] ?? 'Lỗi xử lý');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEdit ? 'Chỉnh sửa Sách' : 'Thêm Sách Mới',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // ── Ảnh bìa ──────────────────────────────────────────
              _buildImagePicker(),
              const SizedBox(height: 16),

              _label('Tên sách *'),
              _field(
                _titleCtrl,
                'Nhập tên sách...',
                Icons.book_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              _label('Tác giả *'),
              _field(
                _authorCtrl,
                'Nhập tác giả...',
                Icons.person_outline,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 12),
              _label('Thể loại'),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _categoryId,
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    hint: const Text('Chọn thể loại', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.blueAccent),
                    style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
                    items: widget.categories
                        .map((c) => DropdownMenuItem<int>(
                              value: int.tryParse('${c['id']}'),
                              child: Text(c['name'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('NXB'),
                        _field(
                          _publisherCtrl,
                          'Nhà xuất bản',
                          Icons.business_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Năm'),
                        _field(
                          _yearCtrl,
                          'VD: 2023',
                          Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _label('Mô tả'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: _dec(
                  Icons.description_outlined,
                ).copyWith(hintText: 'Mô tả sách...'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit ? 'Lưu thay đổi' : 'Thêm sách',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget ảnh bìa + nút chọn ────────────────────────────────
  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Ảnh bìa sách'),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail 80×110
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(width: 80, height: 110, child: _buildPreview()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showImageSourceSheet,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 16,
                        ),
                        label: Text(
                          _imageChanged
                              ? 'Đổi ảnh khác'
                              : (_existingImageUrl.isNotEmpty
                                    ? 'Thay ảnh mới'
                                    : 'Chọn ảnh'),
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1565C0),
                          side: const BorderSide(color: Color(0xFF1565C0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    if (_imageChanged)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _pickedImage = null;
                              _imageChanged = false;
                            }),
                            icon: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Hủy chọn ảnh',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'JPG, PNG, WEBP · Tối đa 5MB\nẢnh sẽ được nén tự động',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
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

  Widget _buildPreview() {
    // Ảnh mới đã chọn
    if (_imageChanged && _pickedImage != null) {
      if (kIsWeb) {
        return FutureBuilder<List<int>>(
          future: _pickedImage!.readAsBytes().then((b) => b.toList()),
          builder: (context, snap) {
            if (snap.hasData) {
              return Image.memory(snap.data as dynamic, fit: BoxFit.cover);
            }
            return _placeholder(loading: true);
          },
        );
      } else {
        return Image.file(File(_pickedImage!.path), fit: BoxFit.cover);
      }
    }
    // Ảnh cũ từ server (khi chỉnh sửa)
    if (_existingImageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _existingImageUrl,
        fit: BoxFit.cover,
        httpHeaders: kIsWeb
            ? const {'ngrok-skip-browser-warning': 'true'}
            : const {},
        placeholder: (context, url) => _placeholder(loading: true),
        errorWidget: (context, url, error) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool loading = false}) => Container(
    color: Colors.grey[200],
    child: Center(
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 28,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 4),
                Text(
                  'Chưa\ncó ảnh',
                  style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      t,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: _dec(icon).copyWith(hintText: hint),
    );
  }

  InputDecoration _dec(IconData icon) => InputDecoration(
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
    filled: true,
    fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1565C0)),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );
}
