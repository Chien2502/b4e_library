import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/constants/api_constants.dart';

class Book {
  final int id;
  final String title;
  final String author;
  final String category;
  final String imageUrl;   // Dùng cho mobile (static file)
  final String webImageUrl; // Dùng cho web (qua PHP proxy)
  final String status;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.imageUrl,
    required this.webImageUrl,
    required this.status,
  });

  // Widget sẽ gọi getter này — tự động chọn URL đúng theo platform
  String get displayImageUrl => kIsWeb ? webImageUrl : imageUrl;

  factory Book.fromJson(Map<String, dynamic> json) {
    final String rawImage = json['image_url']?.toString() ?? '';

    // Mobile: trỏ thẳng vào file tĩnh
    final String mobileUrl = rawImage.isNotEmpty
        ? '${ApiConstants.uploadsUrl}/$rawImage'
        : 'https://via.placeholder.com/150';

    // Web: dùng PHP proxy để tránh CORS từ static file
    // serve_image.php?file=img/Book/xxx.jpg
    final String webUrl = rawImage.isNotEmpty
        ? '${ApiConstants.baseUrl}${ApiConstants.imageProxy}?file=$rawImage'
        : 'https://via.placeholder.com/150';

    return Book(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? 'Chưa có tên',
      author: json['author']?.toString() ?? 'Chưa rõ tác giả',
      category: json['category_name']?.toString() ??
          json['category']?.toString() ??
          'Chưa phân loại',
      imageUrl: mobileUrl,
      webImageUrl: webUrl,
      status: json['status']?.toString() ?? 'unavailable',
    );
  }
}

