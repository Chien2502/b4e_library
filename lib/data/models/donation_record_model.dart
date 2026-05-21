/// Model cho 1 bản ghi quyên góp — từ /api/users/donations.php
///
/// status mới đầy đủ:
///   pending → approved → in_transit → received → processed | rejected
class DonationRecord {
  final int id;
  final String bookTitle;
  final String bookAuthor;
  final String bookPublisher;
  final String bookYear;
  final String bookCondition;
  final String donationType;
  final String pickupType;  // 'self_deliver' | 'user_ship'
  final String status;
  final String createdAt;

  const DonationRecord({
    required this.id,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookPublisher,
    required this.bookYear,
    required this.bookCondition,
    required this.donationType,
    this.pickupType = 'self_deliver',
    required this.status,
    required this.createdAt,
  });

  // ── Label trạng thái ───────────────────────────────────────────
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã tiếp nhận';
      case 'in_transit':
        return 'Đang vận chuyển';
      case 'received':
        return 'Đã nhận sách';
      case 'processed':
        return 'Đã xử lý';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  // ── Label hình thức gửi sách ───────────────────────────────────
  String get pickupTypeLabel {
    switch (pickupType) {
      case 'self_deliver':
        return 'Mang trực tiếp';
      case 'user_ship':
        return 'Gửi qua bưu điện';
      default:
        return donationType;
    }
  }

  // ── Label hình thức quyên góp (legacy) ────────────────────────
  String get donationTypeLabel {
    switch (donationType) {
      case 'direct':
        return 'Trực tiếp';
      case 'pickup':
        return 'Đến nhận tại nhà';
      case 'delivery':
        return 'Chuyển phát';
      default:
        return donationType;
    }
  }

  factory DonationRecord.fromJson(Map<String, dynamic> json) {
    return DonationRecord(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bookTitle: json['book_title']?.toString() ?? '',
      bookAuthor: json['book_author']?.toString() ?? '',
      bookPublisher: json['book_publisher']?.toString() ?? '',
      bookYear: json['book_year']?.toString() ?? '',
      bookCondition: json['book_condition']?.toString() ?? '',
      donationType: json['donation_type']?.toString() ?? '',
      pickupType: json['pickup_type']?.toString() ?? 'self_deliver',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
