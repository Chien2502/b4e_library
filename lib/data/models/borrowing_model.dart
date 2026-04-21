import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/constants/api_constants.dart';

/// Model cho 1 bản ghi mượn sách — từ /api/users/borrowings.php
/// status: 'borrowed' | 'returning' | 'returned' | 'overdue'
class Borrowing {
  final int id;         // borrow_id
  final int bookId;
  final String title;
  final String author;
  final String imageUrl;
  final String webImageUrl;
  final String status;
  final String borrowDate;
  final String dueDate;
  final String? returnDate;

  Borrowing({
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
  });

  String get displayImageUrl => kIsWeb ? webImageUrl : imageUrl;

  /// Sách đang mượn, có thể gửi trả
  bool get canReturn => status == 'borrowed' || status == 'overdue';

  /// Nhãn hiển thị trạng thái
  String get statusLabel {
    switch (status) {
      case 'borrowed':
        return 'Đang đọc';
      case 'returning':
        return 'Chờ xác nhận trả';
      case 'returned':
        return 'Đã hoàn tất';
      case 'overdue':
        return 'Quá hạn';
      default:
        return status;
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
      status: json['status']?.toString() ?? 'borrowed',
      borrowDate: json['borrow_date']?.toString() ?? '',
      dueDate: json['due_date']?.toString() ?? '',
      returnDate: json['return_date']?.toString(),
    );
  }
}

