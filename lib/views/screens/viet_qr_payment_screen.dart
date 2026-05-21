import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../viewmodels/my_books_provider.dart';

/// Màn hình thanh toán phí ship bằng VietQR
///
/// Hiển thị mã QR + thông tin chuyển khoản.
/// Admin sẽ xác nhận thủ công sau khi nhận được giao dịch.
class VietQRPaymentScreen extends StatefulWidget {
  final int borrowingId;

  const VietQRPaymentScreen({super.key, required this.borrowingId});

  @override
  State<VietQRPaymentScreen> createState() => _VietQRPaymentScreenState();
}

class _VietQRPaymentScreenState extends State<VietQRPaymentScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await context
        .read<MyBooksProvider>()
        .fetchVietQR(widget.borrowingId);
    if (mounted) {
      setState(() {
        _data = d;
        _isLoading = false;
        _error = d == null ? 'Không thể tải thông tin thanh toán.' : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        title: const Text('Thanh toán phí ship'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.textSecondary)),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _data!;

    if (d['paid'] == true) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 72),
            const SizedBox(height: 16),
            Text(
              'Đã thanh toán thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thư viện đang chuẩn bị sách cho bạn.',
              style: TextStyle(color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    final String qrUrl     = d['qr_url'] ?? '';
    final String bankName  = d['bank_name'] ?? '';
    final String bankAcct  = d['bank_account'] ?? '';
    final String bankOwner = d['bank_owner'] ?? '';
    final String amount    = d['amount_fmt'] ?? '';
    final String ref       = d['transfer_ref'] ?? '';
    final String note      = d['note'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Thẻ hướng dẫn ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                const SizedBox(height: 6),
                Text(
                  'Quét mã QR bên dưới để thanh toán phí vận chuyển.\nAdmin sẽ xác nhận và chuẩn bị sách ngay sau đó.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Mã QR ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: qrUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: qrUrl,
                    width: 240,
                    height: 240,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code, size: 60, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Không tải được QR', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox(
                    width: 240,
                    height: 240,
                    child: Center(child: Text('Không có QR')),
                  ),
          ),
          const SizedBox(height: 24),

          // ── Thông tin chuyển khoản ─────────────────────────────
          _InfoCard(
            title: 'Thông tin chuyển khoản',
            rows: [
              _InfoRow(label: 'Ngân hàng', value: bankName),
              _InfoRow(label: 'Số tài khoản', value: bankAcct, copyable: true),
              _InfoRow(label: 'Chủ tài khoản', value: bankOwner),
              _InfoRow(label: 'Số tiền', value: amount, highlight: true),
              _InfoRow(label: 'Nội dung CK', value: ref, copyable: true),
            ],
          ),
          const SizedBox(height: 12),

          // ── Lưu ý ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.isNotEmpty
                        ? note
                        : 'Vui lòng chuyển khoản đúng nội dung để Admin xác nhận nhanh nhất.',
                    style: const TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Nút kiểm tra lại ──────────────────────────────────
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Kiểm tra trạng thái'),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ──────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...rows.map((r) => _buildRow(context, r)),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, _InfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              row.label,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: TextStyle(
                fontSize: row.highlight ? 15 : 13,
                fontWeight:
                    row.highlight ? FontWeight.bold : FontWeight.normal,
                color: row.highlight
                    ? const Color(0xFF1E88E5)
                    : context.textPrimary,
              ),
            ),
          ),
          if (row.copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: row.value));
                SnackBarUtils.showSuccess(context, 'Đã sao chép!');
              },
              child: const Icon(Icons.copy, size: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  final bool copyable;
  final bool highlight;

  const _InfoRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.highlight = false,
  });
}
