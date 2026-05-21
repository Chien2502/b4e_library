import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/constants/api_constants.dart';

/// Model cho 1 bản ghi mượn sách — từ /api/users/borrowings.php
///
/// status mới đầy đủ:
///   pickup:   pending_approval → approved → borrowed → return_requested → returned
///   delivery: pending_approval → approved → preparing → shipped → borrowed
///             → return_requested → return_shipping → returned
///   Khác: overdue | cancelled
class Borrowing {
  final int id;
  final int bookId;
  final String title;
  final String author;
  final String imageUrl;
  final String webImageUrl;
  final String status;
  final String borrowDate;
  final String dueDate;
  final String? returnDate;
  final String renewStatus; // 'none' | 'pending' | 'approved' | 'rejected'
  final int renewDays;

  // ── Thông tin giao hàng (mới) ────────────────────────────────────
  final String deliveryType;     // 'pickup' | 'delivery'
  final String? deliveryAddress;
  final double? distanceKm;
  final int shippingFee;
  final String? paymentMethod;   // 'cod' | 'vietqr' | null
  final String paymentStatus;    // 'pending' | 'paid' | 'not_required'
  final String? returnMethod;    // 'direct' | 'shipping' | null

  const Borrowing({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.webImageUrl,
    required this.status,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.renewStatus = 'none',
    this.renewDays = 0,
    this.deliveryType = 'pickup',
    this.deliveryAddress,
    this.distanceKm,
    this.shippingFee = 0,
    this.paymentMethod,
    this.paymentStatus = 'not_required',
    this.returnMethod,
  });

  String get displayImageUrl => kIsWeb ? webImageUrl : imageUrl;

  /// Sách đang mượn, có thể gửi trả (chỉ khi status = borrowed/overdue)
  bool get canReturn => status == 'borrowed' || status == 'overdue';

  /// Là đơn giao hàng
  bool get isDelivery => deliveryType == 'delivery';

  /// Cần thanh toán VietQR trước
  bool get needsPayment =>
      isDelivery &&
      paymentMethod == 'vietqr' &&
      paymentStatus == 'pending';

  /// Nhãn hiển thị trạng thái
  String get statusLabel {
    switch (status) {
      case 'pending_approval':
        return 'Chờ duyệt';
      case 'approved':
        return isDelivery ? 'Đã duyệt' : 'Đã duyệt — Đến lấy';
      case 'preparing':
        return 'Đang chuẩn bị';
      case 'shipped':
        return 'Đang vận chuyển';
      case 'borrowed':
        return 'Đang đọc';
      case 'return_requested':
        return 'Đã gửi yêu cầu trả';
      case 'return_approved':
        return 'Đã duyệt trả';
      case 'return_shipping':
        return 'Sách đang về TViện';
      case 'returned':
        return 'Đã hoàn tất';
      case 'overdue':
        return 'Quá hạn';
      case 'cancelled':
        return 'Đã hủy';
      // Legacy — dữ liệu cũ trước khi migration
      case 'returning':
        return 'Chờ xác nhận trả';
      default:
        return status;
    }
  }

  /// Nhóm tab để lọc
  String get tabGroup {
    switch (status) {
      case 'pending_approval':
      case 'approved':
        return 'pending';
      case 'preparing':
      case 'shipped':
        return 'shipping';
      case 'borrowed':
      case 'overdue':
        return 'active';
      case 'return_requested':
      case 'return_approved':
      case 'return_shipping':
      case 'returning': // legacy
        return 'returning';
      case 'returned':
        return 'returned';
      default:
        return 'other';
    }
  }

  factory Borrowing.fromJson(Map<String, dynamic> json) {
    final String rawImage = json['image_url']?.toString() ?? '';

    final String mobileUrl = rawImage.isNotEmpty
        ? '${ApiConstants.uploadsUrl}/$rawImage'
        : '';
    final String webUrl = rawImage.isNotEmpty
        ? '${ApiConstants.baseUrl}${ApiConstants.imageProxy}?file=$rawImage'
        : '';

    return Borrowing(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bookId: int.tryParse(json['book_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Chưa có tên',
      author: json['author']?.toString() ?? '',
      imageUrl: mobileUrl,
      webImageUrl: webUrl,
      status: json['status']?.toString() ?? 'pending_approval',
      borrowDate: json['borrow_date']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      returnDate: json['return_date']?.toString(),
      renewStatus: json['renew_status']?.toString() ?? 'none',
      renewDays: int.tryParse(json['renew_days']?.toString() ?? '0') ?? 0,
      deliveryType: json['delivery_type']?.toString() ?? 'pickup',
      deliveryAddress: json['delivery_address']?.toString(),
      distanceKm: double.tryParse(json['delivery_distance_km']?.toString() ?? ''),
      shippingFee: int.tryParse(json['shipping_fee']?.toString() ?? '0') ?? 0,
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString() ?? 'not_required',
      returnMethod: json['return_method']?.toString(),
    );
  }
}
