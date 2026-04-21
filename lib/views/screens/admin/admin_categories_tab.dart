import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class AdminCategoriesTab extends StatefulWidget {
  const AdminCategoriesTab({super.key});
  @override
  State<AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends State<AdminCategoriesTab> {
  final _dio = DioClient().dio;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get(ApiConstants.readCategories);
      final raw = res.data;
      List<Map<String, dynamic>> list = [];
      if (raw is List) {
        list = List<Map<String, dynamic>>.from(raw);
      } else if (raw is Map && raw.containsKey('data')) {
        list = List<Map<String, dynamic>>.from(raw['data']);
      } else if (raw is Map && raw.containsKey('records')) {
        list = List<Map<String, dynamic>>.from(raw['records']);
      }
      setState(() => _items = list);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addCategory(String name) async {
    try {
      await _dio.post(ApiConstants.createCategory, data: {'name': name});
      if (!mounted) return;
      _showSnack('✅ Đã thêm thể loại "$name"!', false);
      _load();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['error'] ?? 'Lỗi thêm thể loại', true);
    }
  }

  Future<void> _updateCategory(int id, String newName) async {
    try {
      await _dio.post(ApiConstants.updateCategory, data: {'id': id, 'name': newName});
      if (!mounted) return;
      _showSnack('✅ Đã cập nhật thể loại!', false);
      _load();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['error'] ?? 'Lỗi cập nhật', true);
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa thể loại'),
        content: Text('Bạn có chắc muốn xóa thể loại "$name"?'),
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
      await _dio.post(ApiConstants.deleteCategory, data: {'id': id});
      if (!mounted) return;
      _showSnack('Đã xóa thể loại "$name".', false);
      _load();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['error'] ?? 'Lỗi xóa thể loại', true);
    }
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Thêm thể loại mới'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tên thể loại...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.category_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _addCategory(ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> cat) {
    final ctrl = TextEditingController(text: cat['name'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sửa thể loại'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tên mới...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            prefixIcon: const Icon(Icons.edit_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _updateCategory(
                  int.tryParse('${cat['id']}') ?? 0, ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
            child: const Text('Lưu'),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTitleBar(),
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
          const Icon(Icons.category, color: Color(0xFF1565C0), size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Quản lý Thể loại sách',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Thêm', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 4),
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _load),
        ],
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
      ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
    ]));
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('Chưa có thể loại nào.', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final cat = _items[i];
          final id = int.tryParse('${cat['id']}') ?? 0;
          final name = cat['name'] ?? '---';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE3F2FD),
                child: Text('#$id',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sửa
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: Color(0xFF1565C0)),
                      onPressed: () => _showEditDialog(cat),
                      padding: EdgeInsets.zero,
                      tooltip: 'Chỉnh sửa',
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Xóa
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 16, color: Colors.red[600]),
                      onPressed: () => _deleteCategory(id, name),
                      padding: EdgeInsets.zero,
                      tooltip: 'Xóa',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

