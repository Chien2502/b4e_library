import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../data/models/book_model.dart';

class BookProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();

  List<Book> _books = [];
  List<Book> _filteredBooks = [];

  bool _isLoading = false;
  String _errorMessage = '';

  List<Book> get books => _filteredBooks;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // --- Dùng cho HomeScreen: Lấy 12 cuốn mới nhất (sắp xếp DESC theo id) ---
  Future<void> fetchLatestBooks() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Gọi đúng endpoint tương đối, Dio tự ghép với baseUrl
      // API PHP nhận ?limit=12&page=1 và trả về ORDER BY b.id DESC
      final Response response = await _dioClient.dio.get(
        ApiConstants.readBooks,
        queryParameters: {'limit': 12, 'page': 1},
        // options: Options(
        //   headers: {
        //     // Bỏ qua cảnh báo browser của Ngrok
        //     'ngrok-skip-browser-warning': 'true',
        //   },
        // ),
      );

      if (response.statusCode == 200) {
        _parseAndStore(response.data);
      } else {
        _errorMessage = 'Lỗi server: Code ${response.statusCode}';
      }
    } on DioException catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.message ?? e.type.name}';
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Dùng cho màn hình tìm kiếm (gửi sau): Lấy toàn bộ có filter ---
  Future<void> fetchBooks({
    String? search,
    String? category,
    String? status,
    String? sort,
    int page = 1,
    int limit = 20,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {'limit': limit, 'page': page};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (category != null && category != 'Tất cả')
        queryParams['category'] = category;
      if (status != null && status != 'all') queryParams['status'] = status;
      if (sort != null) queryParams['sort'] = sort;

      final Response response = await _dioClient.dio.get(
        ApiConstants.readBooks,
        queryParameters: queryParams,
        options: Options(headers: {'ngrok-skip-browser-warning': 'true'}),
      );

      if (response.statusCode == 200) {
        _parseAndStore(response.data);
      } else {
        _errorMessage = 'Lỗi server: Code ${response.statusCode}';
      }
    } on DioException catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.message ?? e.type.name}';
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Hàm tìm kiếm client-side (dùng khi không muốn gọi lại API) ---
  void searchBooks(String query) {
    if (query.isEmpty) {
      _filteredBooks = List.from(_books);
    } else {
      final q = query.toLowerCase();
      _filteredBooks = _books.where((b) {
        return b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  // --- Parse JSON response (dùng chung cho cả 2 hàm fetch) ---
  void _parseAndStore(dynamic responseData) {
    List<dynamic> bookListJson = [];

    if (responseData is Map && responseData['data'] != null) {
      // Response có dạng: { "data": [...], "pagination": {...} }
      bookListJson = responseData['data'] as List<dynamic>;
    } else if (responseData is List) {
      bookListJson = responseData;
    }

    _books = bookListJson.map((json) => Book.fromJson(json)).toList();
    _filteredBooks = List.from(_books);
  }
}
