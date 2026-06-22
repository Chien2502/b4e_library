import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/constants/api_constants.dart';

/// Model chi tiết sách — map với response của /api/books/read_single.php
/// API trả về: b.* JOIN categories c → category_name
class BookDetail {
  final int id;
  final int? categoryId;
  final String title;
  final String author;
  final String categoryName;
  final String publisher;
  final String year;
  final String description;
  final String imageUrl;      // Mobile: file tĩnh
  final String webImageUrl;   // Web: qua proxy
  String status;

  BookDetail({
    required this.id,
    this.categoryId,
    required this.title,
    required this.author,
    required this.categoryName,
    required this.publisher,
    required this.year,
    required this.description,
    required this.imageUrl,
    required this.webImageUrl,
    required this.status,
  });

  /// Tự chọn URL phù hợp theo platform
  String get displayImageUrl => kIsWeb ? webImageUrl : imageUrl;

  bool get isAvailable => status == 'available';
  set isAvailable(bool value) => status = value ? 'available' : 'borrowed';
  bool get isBusy => status == 'busy';

  factory BookDetail.fromJson(Map<String, dynamic> json) {
    final String rawImage = json['image_url']?.toString() ?? '';

    final String mobileUrl = rawImage.isNotEmpty
        ? '${ApiConstants.uploadsUrl}/$rawImage'
        : '';

    final String webUrl = rawImage.isNotEmpty
        ? '${ApiConstants.baseUrl}${ApiConstants.imageProxy}?file=$rawImage'
        : '';

    return BookDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      categoryId: json['category_id'] != null
          ? int.tryParse(json['category_id'].toString())
          : null,
      title: json['title']?.toString() ?? 'Chưa có tên',
      author: json['author']?.toString() ?? 'Chưa rõ tác giả',
      categoryName: json['category_name']?.toString() ?? 'Chưa phân loại',
      publisher: json['publisher']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: mobileUrl,
      webImageUrl: webUrl,
      status: json['status']?.toString() ?? 'unavailable',
    );
  }
}

