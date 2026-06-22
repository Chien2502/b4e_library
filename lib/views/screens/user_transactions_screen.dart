import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_error_handler.dart';
import '../../../core/theme/theme_extensions.dart';
import 'viet_qr_payment_screen.dart';

class UserTransactionsScreen extends StatefulWidget {
  const UserTransactionsScreen({super.key});

  @override
  State<UserTransactionsScreen> createState() => _UserTransactionsScreenState();
}

class _UserTransactionsScreenState extends State<UserTransactionsScreen> {
  final _dio = DioClient().dio;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _dio.get(ApiConstants.userBorrowings);
      final List<Map<String, dynamic>> allBorrowings =
          List<Map<String, dynamic>>.from(res.data ?? []);

      if (mounted) {
        setState(() {
          // Lọc các giao dịch: VietQR, chờ thanh toán và chưa bị hủy/quá hạn
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: const Text('Giao dịch chờ thanh toán'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: context.isDarkMode ? Colors.grey[600] : Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Không có giao dịch dang dở nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Các đơn hàng thanh toán VietQR đang chờ duyệt sẽ xuất hiện tại đây.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Quay về trang chủ
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.search_outlined, color: Colors.white),
                label: const Text(
                  'Đi khám phá sách',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildTransactionCard(_transactions[index]),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final borrowId = int.tryParse('${item['id']}') ?? 0;
    final imageUrl = '${ApiConstants.uploadsUrl}/${item['image_url'] ?? ''}';
    final fee = int.tryParse('${item['shipping_fee'] ?? 0}') ?? 0;

    // Tính mốc thời gian hết hạn tĩnh (created_at + 1 tiếng)
    final createdAtStr = item['created_at']?.toString() ?? '';
    String expiryText = '—';
    if (createdAtStr.isNotEmpty) {
      final parsed = DateTime.tryParse(createdAtStr);
      if (parsed != null) {
        final expiryTime = parsed.toLocal().add(const Duration(hours: 1));
        expiryText = _formatTime(expiryTime);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: context.isDarkMode
            ? Border.all(color: context.divider, width: 0.5)
            : null,
        boxShadow: context.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(14),
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
                      item['title'] ?? '---',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['author'] ?? '---',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Phí ship: ',
                          style: TextStyle(fontSize: 12, color: context.textSecondary),
                        ),
                        Text(
                          _fmtMoney(fee),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Thông tin hạn thanh toán tĩnh
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hạn thanh toán trước:',
                      style: TextStyle(fontSize: 10, color: context.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expiryText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Nút thanh toán ngay
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VietQRPaymentScreen(borrowingId: borrowId),
                    ),
                  ).then((_) => _load()); // Reload khi quay lại
                },
                icon: const Icon(Icons.qr_code_scanner, size: 16, color: Colors.white),
                label: const Text(
                  'Thanh toán ngay',
                  style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  elevation: 0,
                ),
              ),
            ],
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

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$hour:$minute ($day/$month/$year)';
  }
}
