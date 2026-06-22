import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_error_handler.dart';
import '../../widgets/custom_dialog.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/theme/theme_extensions.dart';

class AdminTransactionsTab extends StatefulWidget {
  const AdminTransactionsTab({super.key});

  @override
  State<AdminTransactionsTab> createState() => _AdminTransactionsTabState();
}

class _AdminTransactionsTabState extends State<AdminTransactionsTab> {
  final _dio = DioClient().dio;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _error;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Khởi tạo timer cập nhật giao diện mỗi giây để đếm ngược
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _transactions.isNotEmpty) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _dio.get(ApiConstants.adminBorrowings);
      final List<Map<String, dynamic>> allBorrowings =
          List<Map<String, dynamic>>.from(res.data['data'] ?? []);

      // Lọc các giao dịch: thanh toán VietQR, đang chờ thanh toán/duyệt
      if (mounted) {
        setState(() {
          _transactions = allBorrowings.where((item) {
            final method = item['payment_method']?.toString() ?? '';
            final payStatus = item['payment_status']?.toString() ?? '';
            final status = item['status']?.toString() ?? '';
            return method == 'vietqr' &&
                payStatus == 'pending' &&
                status == 'pending_approval';
          }).toList();
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() => _error = NetworkErrorHandler.getFriendlyMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmPayment(int borrowId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Xác nhận thanh toán',
        message: 'Bạn có chắc chắn đã nhận được tiền phí ship cho giao dịch này?',
        icon: Icons.check_circle_outline,
        iconColor: Colors.teal,
        confirmLabel: 'Xác nhận',
        confirmColor: Colors.teal,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _dio.post(ApiConstants.confirmPayment, data: {'borrowing_id': borrowId});
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, '✅ Đã xác nhận thanh toán thành công!');
      _load();
    } on DioException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.response?.data?['error'] ?? 'Lỗi xử lý');
    }
  }

  Future<void> _cancelTransaction(int borrowId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Từ chối giao dịch',
        message: 'Từ chối và hủy giao dịch chuyển tiền này?',
        icon: Icons.cancel_outlined,
        iconColor: Colors.red,
        confirmLabel: 'Xác nhận hủy',
        confirmColor: Colors.red,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _dio.post(
        ApiConstants.adminUpdateBorrowStatus,
        data: {'borrowing_id': borrowId, 'status': 'cancelled'},
        options: Options(contentType: Headers.jsonContentType),
      );
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, '✅ Đã từ chối và hủy đơn mượn!');
      _load();
    } on DioException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.response?.data?['error'] ?? 'Lỗi xử lý');
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(Icons.currency_exchange, color: context.colors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý Trạng thái Chuyển tiền',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  'Đang hoạt động: ${_transactions.length} giao dịch còn hạn',
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: context.textPrimary),
            onPressed: _load,
          ),
        ],
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
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Không có giao dịch chuyển tiền nào cần duyệt',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, kBottomNavigationBarHeight + 12),
        itemCount: _transactions.length,
        separatorBuilder: (_, idx) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildTransactionCard(_transactions[i]),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final borrowId = int.tryParse('${item['id']}') ?? 0;
    final imageUrl = '${ApiConstants.uploadsUrl}/${item['image_url'] ?? ''}';
    final fee = int.tryParse('${item['shipping_fee'] ?? 0}') ?? 0;
    
    // Đếm ngược thời gian
    final createdAtStr = item['created_at']?.toString() ?? '';
    DateTime? createdAt;
    if (createdAtStr.isNotEmpty) {
      createdAt = DateTime.tryParse(createdAtStr);
    }
    
    int remainingSeconds = 0;
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt.toLocal());
      remainingSeconds = 3600 - diff.inSeconds;
    }

    final isExpired = remainingSeconds <= 0;
    final String timerText = _formatRemainingTime(remainingSeconds);

    return Container(
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: context.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
        border: context.isDarkMode
            ? Border.all(color: context.divider, width: 0.5)
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bìa sách
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52,
                  height: 68,
                  child: (item['image_url'] ?? '').toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          httpHeaders: kIsWeb
                              ? const {'ngrok-skip-browser-warning': 'true'}
                              : const {},
                          placeholder: (_, url) => _imgPlaceholder(),
                          errorWidget: (_, url, err) => _imgPlaceholder(),
                        )
                      : _imgPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['book_title'] ?? '---',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _infoRow(
                      Icons.person_outline,
                      '#${item['user_id']} • ${item['username'] ?? ''} • ${item['phone'] ?? ''}',
                    ),
                    _infoRow(
                      Icons.payments_outlined,
                      'Phí ship: ${_fmtMoney(fee)}',
                      color: const Color(0xFF1E88E5),
                    ),
                    _infoRow(
                      Icons.qr_code,
                      'Mã nội dung: B4E-SHIP-${item['id']}',
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
              // Bộ đếm ngược thời gian
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.red.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExpired
                        ? Colors.red.withValues(alpha: 0.4)
                        : Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 11,
                      color: isExpired ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timerText,
                      style: TextStyle(
                        fontSize: 10,
                        color: isExpired ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          // Nút thao tác duyệt / hủy
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _cancelTransaction(borrowId),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Từ chối', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isExpired ? null : () => _confirmPayment(borrowId),
                icon: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                label: const Text('Xác nhận đã TT', style: TextStyle(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color ?? context.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: color ?? context.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: context.background,
        child: Icon(Icons.menu_book_outlined, size: 28, color: context.divider),
      );

  String _fmtMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  String _formatRemainingTime(int seconds) {
    if (seconds <= 0) return 'Hết hạn';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
