import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../data/models/book_model.dart';
import '../data/models/category_model.dart';

class SearchProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();

  // ── Trạng thái tải ──────────────────────────────────────────────
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  String _errorMessage = '';

  // ── Dữ liệu ────────────────────────────────────────────────────
  List<Book> _books = [];
  List<Category> _categories = [];

  // ── Phân trang ─────────────────────────────────────────────────
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  static const int _limit = 12;

  // ── Bộ lọc hiện tại ────────────────────────────────────────────
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả'; // 'Tất cả' = không lọc
  String _selectedStatus = 'all';      // 'all' | 'available' | 'borrowed'

  // ── Getters ────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  String get errorMessage => _errorMessage;
  List<Book> get books => _books;
  List<Category> get categories => _categories;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;

  // ────────────────────────────────────────────────────────────────
  // 1. Tải danh sách thể loại (chỉ gọi 1 lần khi vào màn hình)
  // ────────────────────────────────────────────────────────────────
  Future<void> fetchCategories() async {
    if (_categories.isNotEmpty) return; // Đã có rồi, không gọi lại

    _isCategoriesLoading = true;
    notifyListeners();

    try {
      final Response response =
          await _dioClient.dio.get(ApiConstants.readCategories);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        _categories = data.map((json) => Category.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      debugPrint('Lỗi tải thể loại: ${e.message}');
    } catch (e) {
      debugPrint('Lỗi không xác định: $e');
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 2. Tải sách theo bộ lọc + phân trang
  // ────────────────────────────────────────────────────────────────
  Future<void> fetchBooks({int page = 1}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> params = {
        'page': page,
        'limit': _limit,
      };

      if (_searchQuery.isNotEmpty) params['search'] = _searchQuery;
      if (_selectedCategory != 'Tất cả') params['category'] = _selectedCategory;
      if (_selectedStatus != 'all') params['status'] = _selectedStatus;

      final Response response = await _dioClient.dio.get(
        ApiConstants.readBooks,
        queryParameters: params,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> bookListJson = [];

        if (responseData is Map && responseData['data'] != null) {
          bookListJson = responseData['data'] as List<dynamic>;

          // Xử lý phân trang
          final pagination = responseData['pagination'];
          if (pagination != null) {
            _currentPage = pagination['current_page'] ?? 1;
            _totalPages = pagination['total_pages'] ?? 1;
            _totalItems = pagination['total_items'] ?? 0;
          }
        } else if (responseData is List) {
          bookListJson = responseData;
          _currentPage = page;
          _totalPages = 1;
        }

        _books = bookListJson.map((json) => Book.fromJson(json)).toList();
      } else {
        _errorMessage = 'Lỗi server: ${response.statusCode}';
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

  // ────────────────────────────────────────────────────────────────
  // 3. Cập nhật các bộ lọc (reset về trang 1)
  // ────────────────────────────────────────────────────────────────

  /// Gọi khi người dùng gõ vào search bar (debounced ở UI layer)
  void onSearchChanged(String query) {
    _searchQuery = query;
    fetchBooks(page: 1);
  }

  /// Gọi khi chọn thể loại
  void onCategorySelected(String categoryName) {
    if (_selectedCategory == categoryName) return;
    _selectedCategory = categoryName;
    fetchBooks(page: 1);
  }

  /// Gọi khi chọn trạng thái
  void onStatusChanged(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    fetchBooks(page: 1);
  }

  /// Gọi khi chuyển trang
  void onPageChanged(int page) {
    if (page < 1 || page > _totalPages) return;
    fetchBooks(page: page);
  }

  /// Reset toàn bộ bộ lọc
  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'Tất cả';
    _selectedStatus = 'all';
    fetchBooks(page: 1);
  }
}

