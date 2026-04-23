import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Singleton service quản lý SQLite local cache.
///
/// Gọi [DatabaseService.init()] một lần trong main() trước runApp().
/// Sau đó sử dụng qua [DatabaseService.instance].
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  bool _initialized = false;

  /// Chỉ có giá trị sau khi [init()] được gọi thành công.
  bool get isReady => _initialized && !kIsWeb;

  // ─────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────

  /// Khởi tạo database. Bỏ qua nếu chạy trên Web.
  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final String path = p.join(dir.path, 'b4e_cache.db');

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: _createSchema,
      );

      _initialized = true;
    } catch (e) {
      // Không crash app nếu SQLite lỗi — chỉ log
      assert(() {
        // ignore: avoid_print
        print('[CacheDB] init error: $e');
        return true;
      }());
    }
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cache_entries (
        cache_key   TEXT PRIMARY KEY,
        data        TEXT NOT NULL,
        cached_at   INTEGER NOT NULL,
        ttl_seconds INTEGER NOT NULL
      )
    ''');
  }

  // ─────────────────────────────────────────────────────────────────
  // Read
  // ─────────────────────────────────────────────────────────────────

  /// Đọc cache. Trả về `null` nếu:
  /// - Web platform
  /// - DB chưa init
  /// - Không tìm thấy key
  /// - Cache đã hết TTL
  Future<T?> readCache<T>(
    String key,
    T Function(dynamic json) fromJson,
  ) async {
    if (!isReady) return null;

    try {
      final rows = await _db!.query(
        'cache_entries',
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (rows.isEmpty) return null;

      final row = rows.first;
      final cachedAt  = row['cached_at'] as int;
      final ttl       = row['ttl_seconds'] as int;
      final now       = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = cachedAt + (ttl * 1000);

      if (now > expiresAt) {
        // Hết hạn — xóa entry cũ
        await invalidateCache(key);
        return null;
      }

      final decoded = jsonDecode(row['data'] as String);
      return fromJson(decoded);
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[CacheDB] read error ($key): $e');
        return true;
      }());
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Write
  // ─────────────────────────────────────────────────────────────────

  /// Ghi hoặc cập nhật cache entry.
  Future<void> writeCache(
    String key,
    dynamic data, {
    required int ttlSeconds,
  }) async {
    if (!isReady) return;

    try {
      final String jsonData = jsonEncode(data);
      final int now = DateTime.now().millisecondsSinceEpoch;

      await _db!.insert(
        'cache_entries',
        {
          'cache_key':   key,
          'data':        jsonData,
          'cached_at':   now,
          'ttl_seconds': ttlSeconds,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[CacheDB] write error ($key): $e');
        return true;
      }());
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Invalidate
  // ─────────────────────────────────────────────────────────────────

  /// Xóa một cache entry theo key.
  Future<void> invalidateCache(String key) async {
    if (!isReady) return;
    try {
      await _db!.delete(
        'cache_entries',
        where: 'cache_key = ?',
        whereArgs: [key],
      );
    } catch (_) {}
  }

  /// Xóa một tập các keys (VD: khi logout — chỉ xóa data cá nhân).
  Future<void> invalidateMany(List<String> keys) async {
    if (!isReady || keys.isEmpty) return;
    for (final key in keys) {
      await invalidateCache(key);
    }
  }

  /// Xóa toàn bộ cache.
  Future<void> clearAll() async {
    if (!isReady) return;
    try {
      await _db!.delete('cache_entries');
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────
  // Seed static pages (ghi nội dung tĩnh nếu chưa có)
  // ─────────────────────────────────────────────────────────────────

  /// Ghi dữ liệu chỉ khi cache_key chưa tồn tại (không ghi đè).
  Future<void> seedIfAbsent(
    String key,
    dynamic data, {
    required int ttlSeconds,
  }) async {
    if (!isReady) return;
    try {
      final rows = await _db!.query(
        'cache_entries',
        where: 'cache_key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) {
        await writeCache(key, data, ttlSeconds: ttlSeconds);
      }
    } catch (_) {}
  }
}
