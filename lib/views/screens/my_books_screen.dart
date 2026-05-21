import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/my_books_provider.dart';
import '../../viewmodels/notification_provider.dart';
import '../../data/models/borrowing_model.dart';
import '../widgets/custom_dialog.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/theme/theme_extensions.dart';

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
        return all.where((b) => b.status == 'returning' || b.status == 'return_requested' || b.status == 'return_approved' || b.status == 'return_shipping').toList();
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
      all.where((b) => b.status == 'returning' || b.status == 'return_requested' || b.status == 'return_approved' || b.status == 'return_shipping').length,
      all.where((b) => b.status == 'returned').length,
    ];

    return Container(
      color: context.card,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: context.colors.primary,
        unselectedLabelColor: context.textSecondary,
        indicatorColor: context.colors.primary,
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
                      color: context.colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${counts[i]}',
                      style: TextStyle(
                          fontSize: 10, color: context.colors.primary),
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
                size: 64, color: context.divider),
            const SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu',
              style: TextStyle(fontSize: 15, color: context.textSecondary),
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
      color: context.card,
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                ),
                if (b.author.isNotEmpty)
                  Text(
                    b.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                const SizedBox(height: 4),

                // Ngày mượn & hạn trả (compact cho mobile)
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 11, color: context.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      _formatDate(b.borrowDate),
                      style: TextStyle(fontSize: 11, color: context.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.event_outlined,
                        size: 11, color: _isOverdue(b) ? Colors.red : context.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      _formatDate(b.dueDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: _isOverdue(b) ? Colors.red : context.textSecondary,
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
                placeholder: (context, url) => _placeholder(context),
                errorWidget: (context, url, error) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
        child: Icon(Icons.menu_book_outlined,
            size: 24, color: context.isDarkMode ? Colors.grey[600] : Colors.grey),
      );

  // ── Badge trạng thái (màu theo từng trạng thái) ───────────────
  Widget _buildStatusBadge(Borrowing b) {
    Color baseColor;
    switch (b.status) {
      case 'borrowed':
        baseColor = Colors.orange;
        break;
      case 'overdue':
        baseColor = Colors.red;
        break;
      case 'returning':
      case 'return_requested':
      case 'return_approved':
      case 'return_shipping':
        baseColor = Colors.blue;
        break;
      case 'returned':
        baseColor = Colors.green;
        break;
      default:
        baseColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        b.statusLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: baseColor,
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
                strokeWidth: 1.5, color: context.textSecondary),
          ),
          const SizedBox(width: 4),
          Text('Đang xử lý...',
              style: TextStyle(fontSize: 11, color: context.textSecondary)),
        ],
      );
    }

    // Trạng thái vận chuyển của đơn mượn (shipped) -> Nút Đã nhận sách
    if (b.status == 'shipped') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => CustomDialog(
              title: 'Xác nhận nhận sách',
              message: 'Bạn xác nhận đã nhận thành công cuốn "${b.title}" từ shipper?',
              icon: Icons.check_circle_outline_rounded,
              iconColor: Colors.green,
              confirmLabel: 'Đã nhận',
              onConfirm: () => Navigator.pop(ctx, true),
            ),
          );
          if (confirm == true) {
            final error = await provider.confirmUserAction(b.id, 'confirm_receipt');
            if (context.mounted) {
              if (error == null) {
                SnackBarUtils.showSuccess(context, 'Xác nhận nhận sách thành công! 📚');
              } else {
                SnackBarUtils.showError(context, error);
              }
            }
          }
        },
        child: const Text(
          'Đã nhận',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Trạng thái đã duyệt trả (return_approved) -> Nút Đang ship sách
    if (b.status == 'return_approved') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => CustomDialog(
              title: 'Xác nhận gửi hàng',
              message: 'Bạn xác nhận đã đóng gói và gửi cuốn "${b.title}" cho đơn vị vận chuyển?',
              icon: Icons.local_shipping_outlined,
              iconColor: Colors.blueAccent,
              confirmLabel: 'Xác nhận',
              onConfirm: () => Navigator.pop(ctx, true),
            ),
          );
          if (confirm == true) {
            final error = await provider.confirmUserAction(b.id, 'confirm_shipping');
            if (context.mounted) {
              if (error == null) {
                SnackBarUtils.showSuccess(context, 'Đã xác nhận đang ship trả sách! 🚚');
              } else {
                SnackBarUtils.showError(context, error);
              }
            }
          }
        },
        child: const Text(
          'Đang ship',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Đã hoàn tất → icon check xanh
    if (b.status == 'returned') {
      return const Icon(Icons.check_circle, color: Colors.green, size: 24);
    }

    // Chờ xác nhận → text mô tả
    if (b.status == 'returning' || b.status == 'return_requested') {
      return Text(
        'Đang xử lý...',
        style: TextStyle(fontSize: 11, color: context.textSecondary),
      );
    }

    if (b.status == 'return_shipping') {
      return Text(
        'Đang ship về...',
        style: TextStyle(fontSize: 11, color: context.textSecondary),
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
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Đang chờ gia hạn',
                style: TextStyle(fontSize: 10, color: context.colors.primary, fontWeight: FontWeight.bold),
              ),
            )
          else if (b.renewStatus == 'none' || b.renewStatus == 'rejected')
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: context.colors.primary,
                side: BorderSide(color: context.colors.primary),
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
    final returnMethod = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReturnMethodDialog(bookTitle: b.title),
    );

    if (returnMethod == null) return;
    if (!context.mounted) return;

    final error = await provider.returnBook(b.id, returnMethod: returnMethod);

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
              Text('$_renewDays ngày', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _renewDays.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            activeColor: context.colors.primary,
            label: '$_renewDays ngày',
            onChanged: (val) => setState(() => _renewDays = val.toInt()),
          ),
        ],
      ),
    );
  }
}

class _ReturnMethodDialog extends StatefulWidget {
  final String bookTitle;

  const _ReturnMethodDialog({required this.bookTitle});

  @override
  State<_ReturnMethodDialog> createState() => _ReturnMethodDialogState();
}

class _ReturnMethodDialogState extends State<_ReturnMethodDialog> {
  String _selectedMethod = 'direct'; // 'direct' or 'shipping'

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Chọn phương thức trả',
      message: 'Bạn muốn gửi yêu cầu trả cuốn "${widget.bookTitle}" bằng phương thức nào?',
      icon: Icons.assignment_return_rounded,
      iconColor: Colors.orange,
      confirmLabel: 'Xác nhận',
      confirmColor: Colors.orange,
      onConfirm: () => Navigator.pop(context, _selectedMethod),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _buildMethodOption(
            method: 'direct',
            title: 'Trả trực tiếp',
            description: 'Mang sách đến trả trực tiếp tại thư viện.',
            icon: Icons.storefront_rounded,
          ),
          const SizedBox(height: 12),
          _buildMethodOption(
            method: 'shipping',
            title: 'Gửi qua bưu điện',
            description: 'Gửi sách trả lại qua shipper / bưu điện.',
            icon: Icons.local_shipping_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodOption({
    required String method,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == method;
    final primaryColor = Colors.orange;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.withValues(alpha: 0.5),
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

