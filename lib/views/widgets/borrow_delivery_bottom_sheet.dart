import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../viewmodels/my_books_provider.dart';
import '../../viewmodels/notification_provider.dart';
import '../screens/viet_qr_payment_screen.dart';
import 'package:dio/dio.dart';

/// Bottom sheet chọn hình thức mượn sách:
///   - Mượn trực tiếp tại thư viện (pickup)
///   - Mượn ship tận nơi (delivery) + chọn phương thức thanh toán
class BorrowDeliveryBottomSheet extends StatefulWidget {
  final int bookId;
  final String bookTitle;

  const BorrowDeliveryBottomSheet({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  /// Mở bottom sheet và trả về true nếu đặt mượn thành công
  static Future<bool?> show(
    BuildContext context, {
    required int bookId,
    required String bookTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BorrowDeliveryBottomSheet(
        bookId: bookId,
        bookTitle: bookTitle,
      ),
    );
  }

  @override
  State<BorrowDeliveryBottomSheet> createState() =>
      _BorrowDeliveryBottomSheetState();
}

class _BorrowDeliveryBottomSheetState
    extends State<BorrowDeliveryBottomSheet> {
  // ── Step 1: Chọn hình thức ────────────────────────────────────────
  String _deliveryType = 'pickup'; // 'pickup' | 'delivery'

  // ── Step 2: Địa chỉ giao hàng (chỉ khi delivery) ─────────────────
  final _addressCtrl = TextEditingController();
  String _paymentMethod = 'vietqr'; // 'vietqr' | 'cod'

  // ── State: tính phí ────────────────────────────────────────────────
  ShippingQuote? _quote;
  bool _isCalculating = false;
  bool _isSubmitting = false;

  // ── Toạ độ (sẽ lấy từ địa chỉ user nhập)
  double? _userLat;
  double? _userLng;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, double>?> _getCoordinates(String address) async {
    try {
      final dio = Dio();
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': 1,
        },
        options: Options(
          headers: {'User-Agent': 'B4E Library App'},
        ),
      );
      if (res.statusCode == 200 && res.data is List && res.data.isNotEmpty) {
        final lat = double.tryParse(res.data[0]['lat']?.toString() ?? '');
        final lon = double.tryParse(res.data[0]['lon']?.toString() ?? '');
        if (lat != null && lon != null) {
          return {'lat': lat, 'lng': lon};
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _calcShipping() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      SnackBarUtils.showError(context, 'Vui lòng nhập địa chỉ giao hàng.');
      return;
    }
    setState(() {
      _isCalculating = true;
      _quote = null;
    });

    final coords = await _getCoordinates(address);
    if (!mounted) return;
    if (coords == null) {
      setState(() => _isCalculating = false);
      SnackBarUtils.showError(context, 'Không tìm thấy tọa độ địa chỉ. Vui lòng nhập rõ hơn.');
      return;
    }

    _userLat = coords['lat'];
    _userLng = coords['lng'];

    final q = await context.read<MyBooksProvider>().calculateShipping(
          lat: _userLat!,
          lng: _userLng!,
        );
    setState(() {
      _quote = q;
      _isCalculating = false;
    });
    if (q == null) {
      SnackBarUtils.showError(context, 'Không thể tính phí vận chuyển. Thử lại sau.');
    }
  }

  Future<void> _submit() async {
    if (_deliveryType == 'delivery' && (_userLat == null || _userLng == null || _quote == null)) {
      SnackBarUtils.showError(context, 'Vui lòng tính phí vận chuyển trước khi đặt mượn.');
      return;
    }

    setState(() => _isSubmitting = true);
    final provider = context.read<MyBooksProvider>();

    final result = await provider.createBorrowing(
      bookId: widget.bookId,
      deliveryType: _deliveryType,
      deliveryAddress:
          _deliveryType == 'delivery' ? _addressCtrl.text.trim() : null,
      deliveryLat: _deliveryType == 'delivery' ? _userLat : null,
      deliveryLng: _deliveryType == 'delivery' ? _userLng : null,
      paymentMethod: _deliveryType == 'delivery' ? _paymentMethod : null,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result != null && result['error'] == null) {
      context.read<NotificationProvider>().fetchNotifications();
      final borrowId = result['borrow_id'] as int?;

      Navigator.pop(context, true);

      // Nếu VietQR: chuyển sang màn hình thanh toán
      if (_deliveryType == 'delivery' &&
          _paymentMethod == 'vietqr' &&
          borrowId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VietQRPaymentScreen(borrowingId: borrowId),
          ),
        );
      } else {
        SnackBarUtils.showSuccess(
          context,
          'Yêu cầu mượn sách đã được gửi! Chờ Admin duyệt nhé.',
        );
      }
    } else {
      SnackBarUtils.showError(
          context, result?['error'] ?? 'Không thể gửi yêu cầu mượn sách.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── Handle ────────────────────────────────────────────────
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Tiêu đề ───────────────────────────────────────────────
          Text(
            'Chọn hình thức mượn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.bookTitle,
            style: TextStyle(fontSize: 13, color: context.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // ── Hai lựa chọn ──────────────────────────────────────────
          _DeliveryOption(
            icon: Icons.store_outlined,
            title: 'Mượn trực tiếp',
            subtitle: 'Đến thư viện lấy sách & trả sách',
            badge: 'Miễn phí',
            badgeColor: Colors.green,
            selected: _deliveryType == 'pickup',
            onTap: () => setState(() {
              _deliveryType = 'pickup';
              _quote = null;
            }),
          ),
          const SizedBox(height: 12),
          _DeliveryOption(
            icon: Icons.local_shipping_outlined,
            title: 'Ship tận nơi',
            subtitle: 'Thư viện giao sách đến địa chỉ của bạn',
            badge: 'Phí ship',
            badgeColor: const Color(0xFF1E88E5),
            selected: _deliveryType == 'delivery',
            onTap: () => setState(() {
              _deliveryType = 'delivery';
            }),
          ),

          // ── Form địa chỉ (chỉ khi delivery) ──────────────────────
          if (_deliveryType == 'delivery') ...[
            const SizedBox(height: 20),
            Text(
              'Địa chỉ giao hàng',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ đầy đủ (số nhà, đường, quận/huyện)',
                hintStyle:
                    TextStyle(fontSize: 13, color: context.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  onPressed: _isCalculating ? null : _calcShipping,
                  icon: _isCalculating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate_outlined),
                  tooltip: 'Tính phí ship',
                ),
              ),
            ),

            // ── Kết quả tính phí ──────────────────────────────────
            if (_quote != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _quote!.available
                      ? Colors.green.withOpacity(0.08)
                      : Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _quote!.available
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: _quote!.available
                    ? Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_quote!.distanceKm.toStringAsFixed(1)} km — Phí ship: ${_fmtCurrency(_quote!.shippingFee)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          const Icon(Icons.cancel_outlined,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _quote!.message,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
              ),
            ],

            // ── Chọn phương thức thanh toán ───────────────────────
            if (_quote != null && _quote!.available) ...[
              const SizedBox(height: 16),
              Text(
                'Phương thức thanh toán phí ship',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: context.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PaymentChoice(
                    value: 'vietqr',
                    groupValue: _paymentMethod,
                    label: 'VietQR',
                    icon: Icons.qr_code_2,
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                  const SizedBox(width: 12),
                  _PaymentChoice(
                    value: 'cod',
                    groupValue: _paymentMethod,
                    label: 'Khi nhận hàng',
                    icon: Icons.payments_outlined,
                    onChanged: (v) => setState(() => _paymentMethod = v!),
                  ),
                ],
              ),
              if (_paymentMethod == 'vietqr')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Bạn sẽ được chuyển đến màn hình quét mã QR sau khi đặt mượn.',
                    style: TextStyle(fontSize: 11, color: context.textSecondary),
                  ),
                ),
            ],
          ],

          const SizedBox(height: 24),

          // ── Nút xác nhận ──────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _deliveryType == 'pickup'
                          ? 'Xác nhận mượn trực tiếp'
                          : 'Đặt mượn ship tận nơi',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  bool get _canSubmit {
    if (_isSubmitting || _isCalculating) return false;
    if (_deliveryType == 'pickup') return true;
    // Delivery: phải có địa chỉ, phải đã tính phí và phải available
    return _addressCtrl.text.trim().isNotEmpty &&
        _quote != null &&
        _quote!.available;
  }

  String _fmtCurrency(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }
}

// ── Delivery Option Card ────────────────────────────────────────────
class _DeliveryOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1E88E5).withOpacity(0.08)
              : context.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF1E88E5)
                : context.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFF1E88E5)
                    : context.textSecondary,
                size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.textPrimary,
                          )),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(badge,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: badgeColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF1E88E5), size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Payment Method Choice ───────────────────────────────────────────
class _PaymentChoice extends StatelessWidget {
  final String value;
  final String groupValue;
  final String label;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _PaymentChoice({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1E88E5).withOpacity(0.09)
                : context.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF1E88E5) : context.divider,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF1E88E5)
                      : context.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? const Color(0xFF1E88E5)
                      : context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
