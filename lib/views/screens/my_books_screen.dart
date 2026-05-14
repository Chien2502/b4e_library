import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/my_books_provider.dart';
import '../../viewmodels/notification_provider.dart';
import '../../data/models/borrowing_model.dart';
import '../widgets/custom_dialog.dart';
import '../../core/utils/snackbar_utils.dart';

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
                      color: Colors.blueAccent.withValues(alpha: 0.15),
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
        separatorBuilder: (_, a) =>
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
            ? CachedNetworkImage(
                imageUrl: b.displayImageUrl,
                fit: BoxFit.cover,
                httpHeaders:
                    kIsWeb ? const {'ngrok-skip-browser-warning': 'true'} : const {},
                placeholder: (context, url) => _placeholder(),
                errorWidget: (context, url, error) => _placeholder(),
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

    // Đang mượn / quá hạn → nút "Gửi trả sách" và "Gia hạn"
    if (b.canReturn) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (b.renewStatus == 'pending')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Đang chờ gia hạn',
                style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            )
          else if (b.renewStatus == 'none' || b.renewStatus == 'rejected')
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                side: const BorderSide(color: Color(0xFF1565C0)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _handleRenew(context, b, provider),
              child: const Text(
                'Gia hạn',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 6),
          ElevatedButton(
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
              'Gửi trả',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // ── Xử lý gia hạn sách ──
  Future<void> _handleRenew(
    BuildContext context,
    Borrowing b,
    MyBooksProvider provider,
  ) async {
    final selectedDays = await showDialog<int>(
      context: context,
      builder: (ctx) => _RenewConfirmDialog(bookTitle: b.title),
    );

    if (selectedDays == null) return;
    if (!context.mounted) return;

    final error = await provider.renewBorrowing(b.id, selectedDays);

    if (!context.mounted) return;

    if (error == null) {
      SnackBarUtils.showSuccess(context, 'Đã gửi yêu cầu gia hạn $selectedDays ngày! Thủ thư sẽ phê duyệt sớm. ⏳');
    } else {
      SnackBarUtils.showError(context, error);
    }
  }

  // ── Xử lý trả sách — tương tự handleReturn trong borrowings.js ──
  Future<void> _handleReturn(
    BuildContext context,
    Borrowing b,
    MyBooksProvider provider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Xác nhận trả sách',
        message: 'Bạn muốn gửi yêu cầu trả cuốn "${b.title}"? Thủ thư sẽ xác nhận sau khi nhận được sách.',
        icon: Icons.assignment_return_rounded,
        iconColor: Colors.orange,
        confirmLabel: 'Gửi yêu cầu',
        confirmColor: Colors.orange,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    final error = await provider.returnBook(b.id);

    if (!context.mounted) return;

    if (error == null) {
      // Fetch thông báo ngay sau khi gửi trả thành công
      context.read<NotificationProvider>().fetchNotifications();
    }

    if (error == null) {
      SnackBarUtils.showSuccess(context, 'Đã gửi yêu cầu trả sách! Thủ thư sẽ xác nhận sớm. 📬');
    } else {
      SnackBarUtils.showError(context, error);
    }
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

class _RenewConfirmDialog extends StatefulWidget {
  final String bookTitle;

  const _RenewConfirmDialog({required this.bookTitle});

  @override
  State<_RenewConfirmDialog> createState() => _RenewConfirmDialogState();
}

class _RenewConfirmDialogState extends State<_RenewConfirmDialog> {
  int _renewDays = 7;

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Gia hạn mượn sách',
      message: 'Bạn muốn xin gia hạn cuốn "${widget.bookTitle}" thêm bao nhiêu ngày?',
      icon: Icons.more_time_rounded,
      iconColor: Colors.blueAccent,
      confirmLabel: 'Gửi yêu cầu',
      onConfirm: () => Navigator.pop(context, _renewDays),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Số ngày gia hạn:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$_renewDays ngày', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _renewDays.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            activeColor: const Color(0xFF1565C0),
            label: '$_renewDays ngày',
            onChanged: (val) => setState(() => _renewDays = val.toInt()),
          ),
        ],
      ),
    );
  }
}

