import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/network_error_handler.dart';
import '../../core/network/connectivity_service.dart';

/// Trạng thái của một nguồn dữ liệu admin.
class AdminDataState<T> {
  final T? data;
  final bool isLoading;
  final String? error;
  final DateTime? fetchedAt;

  const AdminDataState({
    this.data,
    this.isLoading = false,
    this.error,
    this.fetchedAt,
  });

  bool get hasData => data != null;

  /// Kiểm tra xem data còn "tươi" không (mặc định TTL = 5 phút).
  bool isStale({Duration ttl = const Duration(minutes: 5)}) {
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt!) > ttl;
  }

  AdminDataState<T> copyWith({
    T? data,
    bool? isLoading,
    String? error,
    DateTime? fetchedAt,
  }) {
    return AdminDataState<T>(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

/// Provider lưu trữ cache dữ liệu cho toàn bộ màn hình Admin.
///
/// Được đặt ở cấp cao (MyApp hoặc cha của AdminScreen) để
/// tồn tại suốt session — dữ liệu không bị mất khi pop AdminScreen.
///
/// Mỗi tab kiểm tra isStale() và chỉ fetch lại khi cần.
class AdminDataProvider with ChangeNotifier {
  final _dio = DioClient().dio;

  // ── Stats (Dashboard) ────────────────────────────────────────────
  AdminDataState<Map<String, dynamic>> _stats = const AdminDataState();
  AdminDataState<Map<String, dynamic>> get stats => _stats;

  // ── Books (Sách) ─────────────────────────────────────────────────
  AdminDataState<Map<String, dynamic>> _books = const AdminDataState();
  AdminDataState<Map<String, dynamic>> get books => _books;

  // ── Categories (Thể loại) ────────────────────────────────────────
  AdminDataState<List<Map<String, dynamic>>> _categories =
      const AdminDataState();
  AdminDataState<List<Map<String, dynamic>>> get categories => _categories;

  // ── Donations (Quyên góp) ────────────────────────────────────────
  AdminDataState<List<Map<String, dynamic>>> _donations =
      const AdminDataState();
  AdminDataState<List<Map<String, dynamic>>> get donations => _donations;

  // ── Borrowings (Mượn/Trả) ───────────────────────────────────────
  AdminDataState<List<Map<String, dynamic>>> _borrowings =
      const AdminDataState();
  AdminDataState<List<Map<String, dynamic>>> get borrowings => _borrowings;

  // ── Users (Người dùng) ──────────────────────────────────────────
  AdminDataState<List<Map<String, dynamic>>> _users = const AdminDataState();
  AdminDataState<List<Map<String, dynamic>>> get users => _users;

  // ── Fetch Stats ──────────────────────────────────────────────────
  Future<void> fetchStats({bool forceRefresh = false}) async {
    if (!forceRefresh && _stats.hasData && !_stats.isStale()) return;
    _stats = _stats.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final res = await _dio.get(ApiConstants.adminStats);
      _stats = AdminDataState(
        data: Map<String, dynamic>.from(res.data),
        isLoading: false,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      _stats = _stats.copyWith(
        isLoading: false,
        error: NetworkErrorHandler.getFriendlyMessage(e),
      );
    }
    notifyListeners();
  }

  // ── Fetch Books ──────────────────────────────────────────────────
  Future<void> fetchBooks({
    bool forceRefresh = false,
    int page = 1,
    String search = '',
    String? status,
    int? categoryId,
  }) async {
    // Books có filter → luôn fetch khi filter thay đổi
    final isFiltered =
        search.isNotEmpty || status != null || categoryId != null;
    if (!forceRefresh && !isFiltered && _books.hasData && !_books.isStale()) {
      return;
    }
    _books = _books.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': 10,
        if (search.isNotEmpty) 'search': search,
        'status': status,
        'category_id': categoryId,
      }..removeWhere((_, v) => v == null);
      final res =
          await _dio.get(ApiConstants.readBooks, queryParameters: queryParams);
      _books = AdminDataState(
        data: Map<String, dynamic>.from(
          res.data is Map ? res.data : {'records': res.data, 'total': 0},
        ),
        isLoading: false,
        fetchedAt: isFiltered ? null : DateTime.now(),
      );
    } catch (e) {
      _books = _books.copyWith(
        isLoading: false,
        error: NetworkErrorHandler.getFriendlyMessage(e),
      );
    }
    notifyListeners();
  }

  // ── Fetch Categories ─────────────────────────────────────────────
  Future<void> fetchCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _categories.hasData && !_categories.isStale()) return;
    _categories = _categories.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final res = await _dio.get(ApiConstants.readCategories);
      final raw = res.data;
      List<Map<String, dynamic>> list = [];
      if (raw is List) {
        list = List<Map<String, dynamic>>.from(raw);
      } else if (raw is Map && raw.containsKey('data')) {
        list = List<Map<String, dynamic>>.from(raw['data']);
      } else if (raw is Map && raw.containsKey('records')) {
        list = List<Map<String, dynamic>>.from(raw['records']);
      }
      _categories = AdminDataState(
        data: list,
        isLoading: false,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      _categories = _categories.copyWith(
        isLoading: false,
        error: NetworkErrorHandler.getFriendlyMessage(e),
      );
    }
    notifyListeners();
  }

  // ── Fetch Donations ──────────────────────────────────────────────
  Future<void> fetchDonations({bool forceRefresh = false}) async {
    if (!forceRefresh && _donations.hasData && !_donations.isStale()) return;
    _donations = _donations.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final res = await _dio.get(ApiConstants.adminDonations);
      final list = List<Map<String, dynamic>>.from(
        res.data is List ? res.data : (res.data['data'] ?? []),
      );
      _donations = AdminDataState(
        data: list,
        isLoading: false,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      _donations = _donations.copyWith(
        isLoading: false,
        error: NetworkErrorHandler.getFriendlyMessage(e),
      );
    }
    notifyListeners();
  }

  // ── Fetch Borrowings ─────────────────────────────────────────────
  Future<void> fetchBorrowings({bool forceRefresh = false}) async {
    if (!forceRefresh && _borrowings.hasData && !_borrowings.isStale()) return;
    _borrowings = _borrowings.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final res = await _dio.get(ApiConstants.adminBorrowings);
      final list = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
      _borrowings = AdminDataState(
        data: list,
        isLoading: false,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      _borrowings = _borrowings.copyWith(
        isLoading: false,
        error: NetworkErrorHandler.getFriendlyMessage(e),
      );
    }
    notifyListeners();
  }

  // ── Handle Renewal ───────────────────────────────────────────────
  Future<String?> handleRenewal(int borrowId, String action) async {
    if (!ConnectivityService().isOnline) return 'Tính năng này cần kết nối internet. Vui lòng kiểm tra lại mạng!';
    try {
      final res = await _dio.post(
        ApiConstants.adminHandleRenewal,
        data: {
          'borrow_id': borrowId,
          'action': action, // 'approve' or 'reject'
        },
      );
      if (res.statusCode == 200) {
        // Invalidate để tự fetch lại khi Admin load lại tab mượn trả
        invalidateBorrowings();
        return null; // success
      }
      return res.data?['error'] ?? 'Lỗi không xác định';
    } catch (e) {
      return NetworkErrorHandler.getFriendlyMessage(e);
    }
  }

  // ── Fetch Users ──────────────────────────────────────────────────
  Future<void> fetchUsers({bool forceRefresh = false}) async {
    if (!forceRefresh && _users.hasData && !_users.isStale()) return;
    _users = _users.copyWith(isLoading: true, error: null);
    notifyListeners();
    try {
      final res = await _dio.get(ApiConstants.adminUsers);
      final raw = res.data;
      final list = List<Map<String, dynamic>>.from(
        raw is List ? raw : (raw['data'] ?? raw['records'] ?? []),
      );
      _users = AdminDataState(
        data: list,
        isLoading: false,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      _users = _users.copyWith(
        isLoading: false,
        error: NetworkErrorHandler.getFriendlyMessage(e),
      );
    }
    notifyListeners();
  }

  // ── Invalidate (sau khi CRUD) ────────────────────────────────────
  void invalidateBooks() {
    _books = const AdminDataState();
    notifyListeners();
  }

  void invalidateCategories() {
    _categories = const AdminDataState();
    notifyListeners();
  }

  void invalidateDonations() {
    _donations = const AdminDataState();
    notifyListeners();
  }

  void invalidateBorrowings() {
    _borrowings = const AdminDataState();
    notifyListeners();
  }

  void invalidateUsers() {
    _users = const AdminDataState();
    notifyListeners();
  }

  void invalidateStats() {
    _stats = const AdminDataState();
    notifyListeners();
  }

  /// Invalidate tất cả — dùng khi logout hoặc cần refresh toàn bộ.
  void invalidateAll() {
    _stats = const AdminDataState();
    _books = const AdminDataState();
    _categories = const AdminDataState();
    _donations = const AdminDataState();
    _borrowings = const AdminDataState();
    _users = const AdminDataState();
    notifyListeners();
  }
}
