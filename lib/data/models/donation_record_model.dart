/// Model cho 1 bản ghi quyên góp — từ /api/users/donations.php
/// SELECT * FROM donations WHERE user_id = ?
/// Fields: id, user_id, book_title, book_author, book_publisher,
///         book_year, book_condition, donation_type, status, created_at
class DonationRecord {
  final int id;
  final String bookTitle;
  final String bookAuthor;
  final String bookPublisher;
  final String bookYear;
  final String bookCondition;
  final String donationType;
  final String status;     // 'pending' | 'approved' | 'rejected'
  final String createdAt;

  DonationRecord({
    required this.id,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookPublisher,
    required this.bookYear,
    required this.bookCondition,
    required this.donationType,
    required this.status,
    required this.createdAt,
  });

  // ── Label hiển thị trạng thái (giống web) ─────────────────────
  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
        return 'Đã tiếp nhận';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  // ── Label hình thức (raw từ DB → tiếng Việt) ──────────────────
  String get donationTypeLabel {
    switch (donationType) {
      case 'direct':
        return 'Trực tiếp';
      case 'pickup':
        return 'Đến nhận tại nhà';
      case 'delivery':
        return 'Chuyển phát';
      default:
        // Fallback nếu DB lưu dạng khác (vd: directDelivery)
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
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

