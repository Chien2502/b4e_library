import 'dart:convert';
import 'package:flutter/services.dart';
import 'cache_keys.dart';
import 'database_service.dart';

/// Seed dữ liệu tĩnh từ file JSON assets vào SQLite.
///
/// Hoạt động âm thầm:
/// - Lần đầu: load JSON → cache vào SQLite với TTL 30 ngày
/// - Các lần sau: chỉ update nếu version trong JSON tăng lên
class StaticContentSeeder {
  StaticContentSeeder._();

  /// Map từ cache_key → đường dẫn asset
  static const Map<String, String> _assetMap = {
    CacheKeys.pageGuide:   'assets/content/page_guide.json',
    CacheKeys.pagePolicy:  'assets/content/page_policy.json',
    CacheKeys.pageSupport: 'assets/content/page_support.json',
    CacheKeys.pageAbout:   'assets/content/page_about.json',
  };

  /// Gọi sau khi [DatabaseService.init()] hoàn tất.
  /// Hoàn toàn không throw — lỗi chỉ được print trong debug mode.
  static Future<void> seed() async {
    final db = DatabaseService.instance;
    if (!db.isReady) return;

    for (final entry in _assetMap.entries) {
      await _seedPage(db, cacheKey: entry.key, assetPath: entry.value);
    }
  }

  static Future<void> _seedPage(
    DatabaseService db, {
    required String cacheKey,
    required String assetPath,
  }) async {
    try {
      // Load JSON từ asset
      final String raw = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      final int newVersion = (json['version'] as num? ?? 1).toInt();

      // Đọc version hiện tại trong cache
      final cached = await db.readCache<Map<String, dynamic>>(
        cacheKey,
        (data) => data as Map<String, dynamic>,
      );

      final int cachedVersion =
          (cached?['version'] as num? ?? 0).toInt();

      if (cached == null || newVersion > cachedVersion) {
        // Chưa có hoặc có version mới → ghi vào cache
        await db.writeCache(
          cacheKey,
          json,
          ttlSeconds: CacheKeys.ttlStatic,
        );
        assert(() {
          // ignore: avoid_print
          print('[StaticContentSeeder] seeded $cacheKey v$newVersion');
          return true;
        }());
      }
    } catch (e) {
      // Không crash app nếu asset lỗi
      assert(() {
        // ignore: avoid_print
        print('[StaticContentSeeder] error seeding $cacheKey: $e');
        return true;
      }());
    }
  }
}
