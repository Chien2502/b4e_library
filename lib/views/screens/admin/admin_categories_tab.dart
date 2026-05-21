import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_error_handler.dart';
import '../../widgets/custom_dialog.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/theme/theme_extensions.dart';


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
      setState(() => _error = NetworkErrorHandler.getFriendlyMessage(e));
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
      builder: (ctx) => CustomDialog(
        title: 'Xóa thể loại',
        message: 'Bạn có chắc muốn xóa thể loại "$name"? Hành động này có thể ảnh hưởng đến các sách thuộc thể loại này.',
        icon: Icons.delete_outline_rounded,
        iconColor: context.colors.error,
        confirmLabel: 'Xóa',
        confirmColor: context.colors.error,
        onConfirm: () => Navigator.pop(ctx, true),
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
      builder: (ctx) => CustomDialog(
        title: 'Thêm thể loại mới',
        message: 'Nhập tên thể loại sách bạn muốn thêm vào hệ thống.',
        icon: Icons.add_circle_outline_rounded,
        confirmLabel: 'Thêm mới',
        onConfirm: () {
          if (ctrl.text.trim().isEmpty) return;
          Navigator.pop(ctx);
          _addCategory(ctrl.text.trim());
        },
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tên thể loại...',
            hintStyle: TextStyle(color: context.textSecondary),
            filled: true,
            fillColor: context.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.divider, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.divider, width: 0.5),
            ),
            prefixIcon: Icon(Icons.category_rounded, color: context.colors.primary),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> cat) {
    final ctrl = TextEditingController(text: cat['name'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Sửa thể loại',
        message: 'Cập nhật tên cho thể loại này.',
        icon: Icons.edit_note_rounded,
        confirmLabel: 'Lưu thay đổi',
        onConfirm: () {
          if (ctrl.text.trim().isEmpty) return;
          Navigator.pop(ctx);
          _updateCategory(int.tryParse('${cat['id']}') ?? 0, ctrl.text.trim());
        },
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tên mới...',
            hintStyle: TextStyle(color: context.textSecondary),
            filled: true,
            fillColor: context.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.divider, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: context.divider, width: 0.5),
            ),
            prefixIcon: Icon(Icons.category_rounded, color: context.colors.primary),
          ),
        ),
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
      color: context.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(Icons.category, color: context.colors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Quản lý Thể loại sách',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary)),
          ),
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            label: const Text('Thêm', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.refresh, size: 20, color: context.textPrimary),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, color: context.colors.error, size: 48),
      const SizedBox(height: 12),
      Text(_error!, style: TextStyle(color: context.colors.error)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
    ]));
    }
    if (_items.isEmpty) {
      return Center(
        child: Text('Chưa có thể loại nào.', style: TextStyle(color: context.textSecondary)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, kBottomNavigationBarHeight + 12),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final cat = _items[i];
          final id = int.tryParse('${cat['id']}') ?? 0;
          final name = cat['name'] ?? '---';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow: context.isDarkMode ? null : [
                BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 5,
                    offset: const Offset(0, 2))
              ],
              border: context.isDarkMode ? Border.all(color: context.divider, width: 0.5) : null,
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                child: Text('#$id',
                    style: TextStyle(
                        fontSize: 10,
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(name,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sửa
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 16, color: context.colors.primary),
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
                      color: context.colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 16, color: context.colors.error),
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

