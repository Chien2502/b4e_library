import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/my_books_provider.dart';
import '../../data/models/borrowing_model.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _tabs = ['Tất cả', 'Đang mượn', 'Chờ xác nhận', 'Đã trả'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyBooksProvider>().fetchMyBorrowings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Lọc danh sách theo tab
  List<Borrowing> _filtered(List<Borrowing> all, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return all.where((b) => b.status == 'borrowed' || b.status == 'overdue').toList();
      case 2:
        return all.where((b) => b.status == 'returning').toList();
      case 3:
        return all.where((b) => b.status == 'returned').toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyBooksProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // ── Tab bar ─────────────────────────────────────────
            _buildTabBar(provider.borrowings),

            // ── Nội dung ────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_tabs.length, (i) {
                  return _buildTabContent(
                    provider: provider,
                    items: _filtered(provider.borrowings, i),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Tab bar với badge đếm ─────────────────────────────────────
  Widget _buildTabBar(List<Borrowing> all) {
    final counts = [
      all.length,
      all.where((b) => b.status == 'borrowed' || b.status == 'overdue').length,
      all.where((b) => b.status == 'returning').length,
      all.where((b) => b.status == 'returned').length,
    ];

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Colors.blueAccent,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.blueAccent,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: List.generate(_tabs.length, (i) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_tabs[i]),
                if (counts[i] > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${counts[i]}',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Nội dung từng tab ─────────────────────────────────────────
  Widget _buildTabContent({
    required MyBooksProvider provider,
    required List<Borrowing> items,
  }) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(provider.errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: provider.fetchMyBorrowings,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu',
              style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchMyBorrowings,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 76, endIndent: 16),
        itemBuilder: (context, index) {
          return _buildBorrowingRow(context, items[index], provider);
        },
      ),
    );
  }

  // ── 1 dòng sách (giống table row trong web) ───────────────────
  Widget _buildBorrowingRow(
    BuildContext context,
    Borrowing b,
    MyBooksProvider provider,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ảnh bìa nhỏ
          _buildThumbnail(b),
          const SizedBox(width: 12),

          // Tên + tác giả
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (b.author.isNotEmpty)
                  Text(
                    b.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 4),

                // Ngày mượn & hạn trả (compact cho mobile)
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      _formatDate(b.borrowDate),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.event_outlined,
                        size: 11, color: _isOverdue(b) ? Colors.red : Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      _formatDate(b.dueDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: _isOverdue(b) ? Colors.red : Colors.grey[600],
                        fontWeight: _isOverdue(b)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Cột: Badge trạng thái + Nút hành động
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(b),
              const SizedBox(height: 8),
              _buildActionWidget(context, b, provider),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ảnh bìa nhỏ 50×68 ─────────────────────────────────────────
  Widget _buildThumbnail(Borrowing b) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 50,
        height: 68,
        child: b.displayImageUrl.isNotEmpty
            ? Image.network(
                b.displayImageUrl,
                fit: BoxFit.cover,
                headers:
                    kIsWeb ? const {'ngrok-skip-browser-warning': 'true'} : const {},
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.menu_book_outlined,
            size: 24, color: Colors.grey),
      );

  // ── Badge trạng thái (màu theo từng trạng thái) ───────────────
  Widget _buildStatusBadge(Borrowing b) {
    Color bgColor;
    Color textColor;

    switch (b.status) {
      case 'borrowed':
        bgColor = const Color(0xFFFFF3E0);
        textColor = Colors.orange[800]!;
        break;
      case 'overdue':
        bgColor = const Color(0xFFFFEBEE);
        textColor = Colors.red[700]!;
        break;
      case 'returning':
        bgColor = const Color(0xFFE3F2FD);
        textColor = Colors.blue[700]!;
        break;
      case 'returned':
        bgColor = const Color(0xFFE8F5E9);
        textColor = Colors.green[700]!;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        b.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // ── Widget hành động (Nút trả / icon check / "Đang xử lý...") ─
  Widget _buildActionWidget(
    BuildContext context,
    Borrowing b,
    MyBooksProvider provider,
  ) {
    // Đang trong quá trình gửi request
    if (provider.isReturning(b.id)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Colors.grey[500]),
          ),
          const SizedBox(width: 4),
          Text('Đang xử lý...',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      );
    }

    // Đã hoàn tất → icon check xanh
    if (b.status == 'returned') {
      return const Icon(Icons.check_circle, color: Colors.green, size: 24);
    }

    // Chờ xác nhận → text mô tả
    if (b.status == 'returning') {
      return Text(
        'Đang xử lý...',
        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
      );
    }

    // Đang mượn / quá hạn → nút "Gửi trả sách"
    if (b.canReturn) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: () => _handleReturn(context, b, provider),
        child: const Text(
          'Gửi trả sách',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Xử lý trả sách — tương tự handleReturn trong borrowings.js ──
  Future<void> _handleReturn(
    BuildContext context,
    Borrowing b,
    MyBooksProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận gửi trả sách'),
        content: Text(
          'Bạn muốn gửi yêu cầu trả cuốn "${b.title}"?\n\n'
          'Thủ thư sẽ xác nhận sau khi nhận được sách.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
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
    if (!context.mounted) return;

    final error = await provider.returnBook(b.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Đã gửi yêu cầu trả sách! Thủ thư sẽ xác nhận sớm. 📬'
              : error,
        ),
        backgroundColor: error == null ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ── Helper: Rút gọn ngày "2026-04-02" → "02/04/2026" ──────────
  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final parts = raw.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return raw;
  }

  bool _isOverdue(Borrowing b) => b.status == 'overdue';
}
