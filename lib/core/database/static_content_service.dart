import 'dart:convert';
import 'package:flutter/services.dart';
import 'cache_keys.dart';
import 'database_service.dart';

/// Service đọc nội dung trang tĩnh — ưu tiên SQLite cache, fallback sang asset.
///
/// Dùng trong các screen: BorrowingGuideScreen, PrivacyPolicyScreen,
/// SupportScreen, AboutScreen.
class StaticContentService {
  StaticContentService._();
  static final StaticContentService instance = StaticContentService._();

  static const Map<String, String> _assetMap = {
    CacheKeys.pageGuide:   'assets/content/page_guide.json',
    CacheKeys.pagePolicy:  'assets/content/page_policy.json',
    CacheKeys.pageSupport: 'assets/content/page_support.json',
    CacheKeys.pageAbout:   'assets/content/page_about.json',
  };

  /// Trả về nội dung JSON của trang tĩnh.
  /// Thứ tự ưu tiên: SQLite cache → Asset file
  Future<Map<String, dynamic>> getPage(String cacheKey) async {
    // 1. Thử đọc từ SQLite cache
    final cached = await DatabaseService.instance.readCache<Map<String, dynamic>>(
      cacheKey,
      (data) => data as Map<String, dynamic>,
    );
    if (cached != null) return cached;

    // 2. Fallback: đọc trực tiếp từ asset
    final assetPath = _assetMap[cacheKey];
    if (assetPath == null) return {};

    try {
      final raw = await rootBundle.loadString(assetPath);
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
