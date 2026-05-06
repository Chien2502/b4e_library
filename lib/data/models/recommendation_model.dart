import 'book_model.dart';

/// Kết quả trả về từ CBF recommendation engine
class RecommendationResult {
  final bool hasHistory;
  final List<String> topCategories; // VD: ["Khoa học", "Tiểu thuyết"]
  final List<Book> recommendations;

  const RecommendationResult({
    required this.hasHistory,
    required this.topCategories,
    required this.recommendations,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    final cats = (json['top_categories'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final books = (json['recommendations'] as List<dynamic>? ?? [])
        .map((e) => Book.fromJson(e as Map<String, dynamic>))
        .toList();

    return RecommendationResult(
      hasHistory: (json['has_history'] as bool?) ?? false,
      topCategories: cats,
      recommendations: books,
    );
  }

  /// Mô tả ngắn cho banner, VD: "Vì bạn hay đọc Khoa học, Tiểu thuyết"
  String get subtitle {
    if (topCategories.isEmpty) return '';
    return 'Vì bạn hay đọc ${topCategories.join(', ')}';
  }
}
