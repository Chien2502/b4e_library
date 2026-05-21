import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/database/cache_keys.dart';
import '../core/database/database_service.dart';
import '../core/network/connectivity_service.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_error_handler.dart';
import '../data/models/book_model.dart';
import '../core/services/push_notification_service.dart';

class BookProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();
  final _cache = DatabaseService.instance;

  List<Book> _books = [];
  List<Book> _filteredBooks = [];

  bool _isLoading = false;
  String _errorMessage = '';

  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;

  List<Book> get books => _filteredBooks;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  BookProvider() {
    _fcmSubscription = PushNotificationService().bookStatusStream.listen((data) {
      final int bookId = data['book_id'];
      final bool isAvail = data['is_available'];
      _updateBookStatus(bookId, isAvail);
    });
  }

  void _updateBookStatus(int bookId, bool isAvail) {
    bool changed = false;
    for (var book in _books) {
      if (book.id == bookId && book.isAvailable != isAvail) {
        book.isAvailable = isAvail;
        changed = true;
      }
    }
    for (var book in _filteredBooks) {
      if (book.id == bookId && book.isAvailable != isAvail) {
        book.isAvailable = isAvail;
        changed = true;
      }
    }
    if (changed) {
      _cache.updateBookStatusInCache(bookId, isAvail);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  /// Trả về Map (thể loại, danh sách sách) với:
  /// - Số thể loại = 1/4 tổng số thể loại hiện có, tối đa 8.
  /// - Sắp xếp thể loại theo số sách giảm dần (thể loại nhiều sách đứng đầu).
  Map<String, List<Book>> get booksByCategory {
    // Gom nhóm
    final Map<String, List<Book>> grouped = {};
    for (final book in _books) {
      grouped.putIfAbsent(book.category, () => []).add(book);
    }

    // Sắp xếp thể loại theo số sách giảm dần
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => grouped[b]!.length.compareTo(grouped[a]!.length));

    // Số thể loại cần hiển thị = 1/4 tổng, tối thiểu 1, tối đa 8
    final int totalCategories = sortedKeys.length;
    final int showCount = (totalCategories / 4).ceil().clamp(1, 8);

    final Map<String, List<Book>> result = {};
    for (int i = 0; i < showCount && i < sortedKeys.length; i++) {
      result[sortedKeys[i]] = grouped[sortedKeys[i]]!;
    }
    return result;
  }

  // --- Dùng cho HomeScreen: Lấy 12 cuốn mới nhất (sắp xếp DESC theo id) ---
  Future<void> fetchLatestBooks({bool forceRefresh = false}) async {
    // 1. Đọc cache trước — luôn hoạt động dù online hay offline
    if (!forceRefresh) {
      final cached = await _cache.readCache<List<Book>>(
        CacheKeys.homeLatest,
        (json) {
          final raw = json is String ? jsonDecode(json) : json;
          final list = raw is Map ? (raw['data'] as List? ?? []) : (raw as List);
          return list.map((j) => Book.fromJson(j as Map<String, dynamic>)).toList();
        },
      );
      if (cached != null && cached.isNotEmpty) {
        _books = cached;
        _filteredBooks = List.from(_books);
        notifyListeners();
        return; // có cache → dùng ngay, không cần network
      }
    }

    // 2. Không có cache → kiểm tra mạng trước khi gọi API
    // ignore: import_of_legacy_library_into_null_safe
    final isOnline = ConnectivityService().isOnline;
    if (!isOnline) {
      _isLoading = false;
      _errorMessage = 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Response response = await _dioClient.dio.get(
        ApiConstants.readBooks,
        queryParameters: {'limit': 50, 'page': 1},
      );

      if (response.statusCode == 200) {
        _parseAndStore(response.data);
        // 3. Ghi vào cache để dùng khi offline lần sau
        await _cache.writeCache(
          CacheKeys.homeLatest,
          response.data,
          ttlSeconds: CacheKeys.ttlMedium,
        );
      } else {
        _errorMessage = 'Lỗi server: Code ${response.statusCode}';
      }
    } on DioException catch (e) {
      _errorMessage = NetworkErrorHandler.getFriendlyMessage(e);
    } catch (e) {
      _errorMessage = NetworkErrorHandler.getFriendlyMessage(e);
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
      if (category != null && category != 'Tất cả') {
        queryParams['category'] = category;
      }
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
      _errorMessage = NetworkErrorHandler.getFriendlyMessage(e);
    } catch (e) {
      _errorMessage = NetworkErrorHandler.getFriendlyMessage(e);
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
