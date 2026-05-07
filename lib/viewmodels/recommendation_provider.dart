import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/database/cache_keys.dart';
import '../core/database/database_service.dart';
import '../core/network/dio_client.dart';
import '../data/models/book_model.dart';
import '../data/models/recommendation_model.dart';
import '../core/services/push_notification_service.dart';

class RecommendationProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();
  final _cache = DatabaseService.instance;

  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;

  RecommendationProvider() {
    _fcmSubscription = PushNotificationService().bookStatusStream.listen((data) {
      final int bookId = data['book_id'];
      final bool isAvail = data['is_available'];
      _updateBookStatus(bookId, isAvail);
    });
  }

  void _updateBookStatus(int bookId, bool isAvail) {
    bool changed = false;
    for (var book in _popular) {
      if (book.id == bookId && book.isAvailable != isAvail) {
        book.isAvailable = isAvail;
        changed = true;
      }
    }
    if (_result != null) {
      for (var book in _result!.recommendations) {
        if (book.id == bookId && book.isAvailable != isAvail) {
          book.isAvailable = isAvail;
          changed = true;
        }
      }
    }
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  // ── Popular books (public) ─────────────────────────────────────
  List<Book> _popular = [];
  bool _isPopularLoading = false;
  String _popularError = '';

  List<Book> get popular        => _popular;
  bool get isPopularLoading     => _isPopularLoading;
  String get popularError       => _popularError;

  // ── Personalized recommendations ──────────────────────────────
  RecommendationResult? _result;
  bool _isRecLoading = false;
  String _recError = '';

  RecommendationResult? get result  => _result;
  bool get isRecLoading             => _isRecLoading;
  String get recError               => _recError;

  /// Trả về true nếu user có lịch sử mượn
  bool get hasHistory => _result?.hasHistory ?? false;

  /// Danh sách sách được gợi ý
  List<Book> get recommendations => _result?.recommendations ?? [];

  // ── Fetch popular (không cần JWT) ─────────────────────────────
  Future<void> fetchPopular({int limit = 10, bool forceRefresh = false}) async {
    if (_isPopularLoading) return;

    // 1. Đọc cache trước nếu không force refresh
    if (!forceRefresh) {
      final cached = await _cache.readCache<List<Book>>(
        CacheKeys.homePopular,
        (json) => (json as List<dynamic>)
            .map((j) => Book.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
      if (cached != null && cached.isNotEmpty) {
        _popular = cached;
        notifyListeners();
        return;
      }
    }

    _isPopularLoading = true;
    _popularError = '';
    notifyListeners();

    try {
      final Response res = await _dioClient.dio.get(
        ApiConstants.popularBooks,
        queryParameters: {'limit': limit},
      );
      if (res.statusCode == 200) {
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        _popular = (data as List<dynamic>)
            .map((j) => Book.fromJson(j as Map<String, dynamic>))
            .toList();

        // 2. Ghi vào cache
        await _cache.writeCache(
          CacheKeys.homePopular,
          data,
          ttlSeconds: CacheKeys.ttlMedium,
        );
      }
    } on DioException catch (e) {
      _popularError =
          e.response?.data?['error'] ?? 'Không tải được sách phổ biến.';
    } finally {
      _isPopularLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch recommendations (cần JWT) ───────────────────────────
  Future<void> fetchRecommendations(
      {int limit = 8, bool forceRefresh = false}) async {
    if (_isRecLoading) return;

    // 1. Đọc cache trước nếu không force refresh
    if (!forceRefresh) {
      final cached = await _cache.readCache<RecommendationResult>(
        CacheKeys.homeRecommendations,
        (json) =>
            RecommendationResult.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) {
        _result = cached;
        notifyListeners();
        return;
      }
    }

    _isRecLoading = true;
    _recError = '';
    notifyListeners();

    try {
      final Response res = await _dioClient.dio.get(
        ApiConstants.recommendations,
        queryParameters: {'limit': limit},
      );
      if (res.statusCode == 200) {
        final data = res.data is String ? jsonDecode(res.data) : res.data;
        final map = data as Map<String, dynamic>;
        _result = RecommendationResult.fromJson(map);

        // 2. Ghi vào cache (chỉ khi có history để tránh cache "rỗng")
        if (_result!.hasHistory) {
          await _cache.writeCache(
            CacheKeys.homeRecommendations,
            map,
            ttlSeconds: CacheKeys.ttlShort,
          );
        }
      }
    } on DioException catch (e) {
      _recError = e.response?.data?['error'] ?? 'Không tải được gợi ý.';
      _result = null;
    } finally {
      _isRecLoading = false;
      notifyListeners();
    }
  }

  // ── Xóa dữ liệu cá nhân khi đăng xuất ────────────────────────
  void clearPersonalized() {
    _result = null;
    _recError = '';
    // Xóa cache cá nhân (không xóa popular)
    _cache.invalidateCache(CacheKeys.homeRecommendations);
    notifyListeners();
  }

  // ── Reset toàn bộ (dùng khi cần refresh cứng) ─────────────────
  Future<void> reset() async {
    _popular = [];
    _popularError = '';
    _result = null;
    _recError = '';
    await _cache.invalidateMany([
      CacheKeys.homePopular,
      CacheKeys.homeRecommendations,
    ]);
    notifyListeners();
  }
}
