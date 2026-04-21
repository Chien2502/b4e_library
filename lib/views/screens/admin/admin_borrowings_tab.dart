import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class AdminBorrowingsTab extends StatefulWidget {
  const AdminBorrowingsTab({super.key});
  @override
  State<AdminBorrowingsTab> createState() => _AdminBorrowingsTabState();
}

class _AdminBorrowingsTabState extends State<AdminBorrowingsTab> {
  final _dio = DioClient().dio;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'all'; // all | returning | borrowed | returned

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get(ApiConstants.adminBorrowings);
      final list = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      setState(() => _items = list);
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['error'] ?? e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterStatus == 'all') return _items;
    return _items.where((e) => e['status'] == _filterStatus).toList();
  }

  Future<void> _confirmReturn(int borrowId) async {
    try {
      await _dio.post(ApiConstants.adminConfirmReturn, data: {'borrow_id': borrowId});
      if (!mounted) return;
      _showSnack('✅ Xác nhận trả sách thành công!', false);
      _load();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['error'] ?? 'Lỗi xử lý', true);
    }
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
        _buildFilterChips(),
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
          const Icon(Icons.swap_horiz, color: Color(0xFF1565C0), size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quản lý Mượn & Trả Sách',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Danh sách tất cả phiếu mượn',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'Tất cả', Colors.grey),
      ('returning', 'Chờ trả', Colors.orange),
      ('borrowed', 'Đang mượn', Colors.blue),
      ('returned', 'Đã trả', Colors.green),
    ];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final active = _filterStatus == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.$2,
                    style: TextStyle(
                        fontSize: 12,
                        color: active ? Colors.white : f.$3,
                        fontWeight: FontWeight.w600)),
                selected: active,
                onSelected: (_) => setState(() => _filterStatus = f.$1),
                selectedColor: f.$3,
                backgroundColor: f.$3.withAlpha(20),
                side: BorderSide(color: f.$3.withAlpha(80)),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
            );
          }).toList(),
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
      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
    ]));
    }

    final list = _filtered;
    if (list.isEmpty) {
      return const Center(child: Text('Không có dữ liệu', style: TextStyle(color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString();
    final borrowId = int.tryParse('${item['id']}') ?? 0;
    final imageUrl = '${ApiConstants.uploadsUrl}/${(item['image_url'] ?? '').toString()}';
    final dueDate = (item['due_date'] ?? '').toString();

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'returning':
        statusColor = Colors.orange;
        statusLabel = 'User báo đã trả';
        break;
      case 'borrowed':
        statusColor = Colors.blue;
        statusLabel = 'Đang mượn';
        break;
      case 'returned':
        statusColor = Colors.green;
        statusLabel = 'Đã trả';
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusLabel = 'Quá hạn';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh sách
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56, height: 72,
              child: (item['image_url'] ?? '').toString().isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      headers: kIsWeb
                          ? const {'ngrok-skip-browser-warning': 'true'}
                          : const {},
                      errorBuilder: (_, __, ___) => _imgPlaceholder())
                  : _imgPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          // Nội dung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['book_title'] ?? '---',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                  const SizedBox(width: 3),
                  Expanded(child: Text(
                    '#${item['user_id']} • ${item['username'] ?? ''} • ${item['phone'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  )),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text('Mượn: ${item['borrow_date'] ?? '---'}',
                      style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ]),
                if (dueDate.isNotEmpty) Row(children: [
                  const Icon(Icons.timer_outlined, size: 13, color: Colors.red),
                  const SizedBox(width: 3),
                  Text('Hạn: $dueDate',
                      style: const TextStyle(fontSize: 11, color: Colors.red)),
                ]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge trạng thái
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withAlpha(80)),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                    // Nút xác nhận (chỉ hiện với returning/borrowed/overdue)
                    if (status == 'returning' || status == 'borrowed' || status == 'overdue')
                      SizedBox(
                        height: 30,
                        child: ElevatedButton.icon(
                          onPressed: () => _showConfirmDialog(borrowId, item['book_title']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                          label: const Text('Xác nhận đã nhận',
                              style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: Colors.grey[200],
    child: const Icon(Icons.menu_book_outlined, size: 28, color: Colors.grey),
  );

  Future<void> _showConfirmDialog(int borrowId, String? bookTitle) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xác nhận trả sách'),
        content: Text('Xác nhận đã nhận lại cuốn "${bookTitle ?? ''}"?\nSách sẽ được cập nhật trạng thái "Có sẵn" trong kho.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok == true) _confirmReturn(borrowId);
  }
}

