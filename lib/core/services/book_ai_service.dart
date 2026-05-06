import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';

/// Dữ liệu sách được trả về từ ISBN lookup hoặc AI cover analysis.
class BookLookupResult {
  final String? title;
  final String? author;
  final String? description;
  final String? category;
  final int? publishYear;
  final String? isbn;
  final String? coverUrl;
  final int? pageCount;
  final String? publisher;
  final String? source; // 'openlibrary' | 'google_books' | 'gemini_vision'
  final String? error;

  const BookLookupResult({
    this.title,
    this.author,
    this.description,
    this.category,
    this.publishYear,
    this.isbn,
    this.coverUrl,
    this.pageCount,
    this.publisher,
    this.source,
    this.error,
  });

  bool get isSuccess => error == null;
  bool get isNotABook => error == 'not_a_book';

  factory BookLookupResult.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return BookLookupResult(error: json['error']?.toString());
    }
    return BookLookupResult(
      title:       json['title']?.toString(),
      author:      json['author']?.toString(),
      description: json['description']?.toString(),
      category:    json['category']?.toString(),
      publishYear: json['publish_year'] is int
          ? json['publish_year'] as int
          : int.tryParse(json['publish_year']?.toString() ?? ''),
      isbn:        json['isbn']?.toString(),
      coverUrl:    json['cover_url']?.toString(),
      pageCount:   json['page_count'] is int
          ? json['page_count'] as int
          : int.tryParse(json['page_count']?.toString() ?? ''),
      publisher:   json['publisher']?.toString(),
      source:      json['source']?.toString(),
    );
  }
}

/// Service gọi các API tra cứu sách (ISBN + AI cover).
class BookAiService {
  BookAiService._();
  static final BookAiService instance = BookAiService._();

  final _dio = DioClient().dio;

  // ── ISBN Lookup ───────────────────────────────────────────────────────────

  /// Tra cứu thông tin sách từ ISBN qua PHP proxy (OpenLibrary / Google Books).
  Future<BookLookupResult> lookupByIsbn(String isbn) async {
    try {
      final res = await _dio.get(
        ApiConstants.isbnLookup,
        queryParameters: {'isbn': isbn},
      );
      if (res.statusCode == 200 && res.data is Map) {
        return BookLookupResult.fromJson(
            res.data as Map<String, dynamic>);
      }
      return const BookLookupResult(error: 'Phản hồi không hợp lệ từ server.');
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?.toString()
          ?? e.message
          ?? 'Lỗi kết nối khi tra cứu ISBN.';
      return BookLookupResult(error: msg);
    } catch (e) {
      return BookLookupResult(error: 'Lỗi: $e');
    }
  }

  // ── AI Cover Analysis ─────────────────────────────────────────────────────

  /// Gửi ảnh bìa sách đến PHP proxy → Gemini Vision → trả về thông tin sách.
  /// [imageFile] là file ảnh đã chọn từ ImagePicker (chỉ hỗ trợ mobile).
  Future<BookLookupResult> analyzeBookCover(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'cover.jpg',
        ),
      });

      final res = await _dio.post(
        ApiConstants.analyzeCover,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (res.statusCode == 200 && res.data is Map) {
        return BookLookupResult.fromJson(
            res.data as Map<String, dynamic>);
      }
      return const BookLookupResult(error: 'Phân tích ảnh thất bại.');
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?.toString()
          ?? e.message
          ?? 'Lỗi kết nối khi phân tích ảnh bìa.';
      return BookLookupResult(error: msg);
    } catch (e) {
      return BookLookupResult(error: 'Lỗi: $e');
    }
  }
}
