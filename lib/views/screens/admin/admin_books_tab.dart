import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final futures = await Future.wait([
        _dio.get(ApiConstants.readBooks),
        _dio.get(ApiConstants.readCategories),
      ]);
      // Books
      final bookRaw = futures[0].data;
      List<Map<String, dynamic>> books = [];
      if (bookRaw is List) {
        books = List<Map<String, dynamic>>.from(bookRaw);
      } else if (bookRaw is Map) {
        books = List<Map<String, dynamic>>.from(
          bookRaw['data'] ?? bookRaw['records'] ?? []);
      }
      // Categories
      final catRaw = futures[1].data;
      List<Map<String, dynamic>> cats = [];
      if (catRaw is List) {
        cats = List<Map<String, dynamic>>.from(catRaw);
      } else if (catRaw is Map) {
        cats = List<Map<String, dynamic>>.from(
          catRaw['data'] ?? catRaw['records'] ?? []);
      }
      setState(() { _books = books; _categories = cats; });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteBook(int id, String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa sách'),
        content: Text('Xóa cuốn "$title"?\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookFormSheet(
        book: book,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _books;
    final q = _search.toLowerCase();
    return _books.where((b) {
      final title = (b['title'] ?? '').toLowerCase();
      final author = (b['author'] ?? '').toLowerCase();
      return title.contains(q) || author.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTitleBar(),
        _buildSearchBar(),
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
            child: Text('Quản lý Sách',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: () => _openForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Thêm sách', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 4),
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _loadAll),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
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
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _loadAll, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
    ]));
    }

    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Text(_search.isEmpty ? 'Chưa có sách nào' : 'Không tìm thấy kết quả',
            style: const TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, a) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildCard(list[i]),
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
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Cover
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            child: SizedBox(
              width: 64, height: 84,
              child: (book['image_url'] ?? '').toString().isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      headers: kIsWeb ? const {'ngrok-skip-browser-warning': 'true'} : const {},
                      errorBuilder: (_, err, stack) => _placeholder())
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
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(author, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(catName,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0))),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  ]),
                ],
              ),
            ),
          ),
          // Actions
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1565C0)),
                  onPressed: () => _openForm(book: book),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[600]),
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
  final List<Map<String, dynamic>> categories;
  final Dio dio;
  final VoidCallback onSaved;

  const _BookFormSheet({
    this.book,
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
    _titleCtrl = TextEditingController(text: (b?['title'] ?? '').toString());
    _authorCtrl = TextEditingController(text: (b?['author'] ?? '').toString());
    _publisherCtrl = TextEditingController(text: (b?['publisher'] ?? '').toString());
    _yearCtrl = TextEditingController(
        text: b?['year'] != null ? b!['year'].toString() : '');
    _descCtrl = TextEditingController(text: (b?['description'] ?? '').toString());
    _categoryId = b != null ? int.tryParse('${b['category_id']}') : null;
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Chọn ảnh bìa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(Icons.photo_library_outlined, color: Color(0xFF1565C0)),
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
                    child: Icon(Icons.camera_alt_outlined, color: Colors.purple),
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
          data.files.add(MapEntry(
            'image',
            MultipartFile.fromBytes(bytes, filename: filename),
          ));
        } else {
          data.files.add(MapEntry(
            'image',
            await MultipartFile.fromFile(_pickedImage!.path, filename: filename),
          ));
        }
      }

      if (_isEdit) {
        await widget.dio.post(ApiConstants.updateBook, data: data);
      } else {
        await widget.dio.post(ApiConstants.createBook, data: data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? '✅ Cập nhật sách thành công!' : '✅ Thêm sách thành công!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      widget.onSaved();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.response?.data?['error'] ?? 'Lỗi xử lý'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
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
              Center(child: Container(
                width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              )),
              Text(_isEdit ? 'Chỉnh sửa Sách' : 'Thêm Sách Mới',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // ── Ảnh bìa ──────────────────────────────────────────
              _buildImagePicker(),
              const SizedBox(height: 16),

              _label('Tên sách *'),
              _field(_titleCtrl, 'Nhập tên sách...', Icons.book_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null),
              const SizedBox(height: 12),
              _label('Tác giả *'),
              _field(_authorCtrl, 'Nhập tác giả...', Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null),
              const SizedBox(height: 12),
              _label('Thể loại'),
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                hint: const Text('Chọn thể loại', style: TextStyle(fontSize: 13)),
                onChanged: (v) => setState(() => _categoryId = v),
                decoration: _dec(Icons.category_outlined),
                items: widget.categories.map((c) => DropdownMenuItem<int>(
                  value: int.tryParse('${c['id']}'),
                  child: Text(c['name'] ?? '', style: const TextStyle(fontSize: 13)),
                )).toList(),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('NXB'),
                  _field(_publisherCtrl, 'Nhà xuất bản', Icons.business_outlined),
                ])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Năm'),
                  _field(_yearCtrl, 'VD: 2023', Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number),
                ])),
              ]),
              const SizedBox(height: 12),
              _label('Mô tả'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: _dec(Icons.description_outlined).copyWith(hintText: 'Mô tả sách...'),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Hủy'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Lưu thay đổi' : 'Thêm sách',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ]),
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
          child: Row(children: [
            // Thumbnail 80×110
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(width: 80, height: 110, child: _buildPreview()),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: const Icon(Icons.photo_library_outlined, size: 16),
                    label: Text(
                      _imageChanged ? 'Đổi ảnh khác'
                          : (_existingImageUrl.isNotEmpty ? 'Thay ảnh mới' : 'Chọn ảnh'),
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        icon: const Icon(Icons.close, size: 14, color: Colors.red),
                        label: const Text('Hủy chọn ảnh',
                            style: TextStyle(fontSize: 12, color: Colors.red)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Text('JPG, PNG, WEBP · Tối đa 5MB\nẢnh sẽ được nén tự động',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            )),
          ]),
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
      return Image.network(
        _existingImageUrl,
        fit: BoxFit.cover,
        headers: kIsWeb ? const {'ngrok-skip-browser-warning': 'true'} : const {},
        errorBuilder: (_, err, stack) => _placeholder(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _placeholder(loading: true),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool loading = false}) => Container(
    color: Colors.grey[200],
    child: Center(
      child: loading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_photo_alternate_outlined, size: 28, color: Colors.grey[400]),
              const SizedBox(height: 4),
              Text('Chưa\ncó ảnh',
                  style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                  textAlign: TextAlign.center),
            ]),
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {String? Function(String?)? validator, TextInputType? keyboardType}) {
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
        borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1565C0))),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
  );
}





