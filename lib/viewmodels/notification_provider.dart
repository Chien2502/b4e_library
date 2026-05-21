import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/database/database_service.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_error_handler.dart';
import '../data/models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String _errorMessage = '';

  // ── Getters ─────────────────────────────────────────────────────
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasUnread => _unreadCount > 0;

  // ── 1. Fetch danh sách thông báo ─────────────────────────────────
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Response res =
          await _dioClient.dio.get(ApiConstants.getNotifications);

      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        
        // Đọc danh sách ID thông báo hệ thống đã đọc từ SQLite
        final List<int> readSysIds = await _getReadSystemBroadcastIds();
        
        final list = data['data'] as List<dynamic>;
        
        // Map thông báo, gán trạng thái read dựa trên local cache cho thông báo hệ thống
        _notifications = list.map((j) {
          final notif = AppNotification.fromJson(j);
          if (notif.isSystem) {
            final isRead = readSysIds.contains(notif.id);
            return notif.copyWith(isRead: isRead);
          }
          return notif;
        }).toList();

        // Đếm số lượng chưa đọc cá nhân
        final personalUnread = int.tryParse(data['unread_count']?.toString() ?? '0') ?? 0;
        // Đếm số lượng chưa đọc hệ thống
        final systemUnread = _notifications.where((n) => n.isSystem && !n.isRead).length;
        
        _unreadCount = personalUnread + systemUnread;
      } else {
        _errorMessage = 'Lỗi server: ${res.statusCode}';
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

  // ── 2. Đánh dấu 1 thông báo đã đọc ──────────────────────────────
  Future<void> markAsRead(int notificationId) async {
    // Cập nhật local ngay lập tức (optimistic update)
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx == -1 || _notifications[idx].isRead) return;

    final notif = _notifications[idx];
    _notifications[idx] = notif.copyWith(isRead: true);
    _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    notifyListeners();

    if (notif.isSystem) {
      // Nếu là thông báo hệ thống, lưu ID đã đọc cục bộ vào SQLite
      await _saveReadSystemBroadcastId(notif.id);
    } else {
      // Gửi lên server (silent — không hiện lỗi nếu thất bại) cho thông báo cá nhân
      try {
        await _dioClient.dio.post(
          ApiConstants.markNotificationRead,
          data: {'notification_id': notificationId},
        );
      } catch (_) {}
    }
  }

  // ── 3. Đánh dấu TẤT CẢ đã đọc ───────────────────────────────────
  Future<void> markAllAsRead() async {
    // Thu thập toàn bộ ID thông báo hệ thống hiện có để lưu đã đọc
    final List<int> currentSysIds = _notifications
        .where((n) => n.isSystem)
        .map((n) => n.id)
        .toList();

    for (final id in currentSysIds) {
      await _saveReadSystemBroadcastId(id);
    }

    // Optimistic update
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _dioClient.dio.post(
        ApiConstants.markNotificationRead,
        data: {'all': true},
      );
    } catch (_) {}
  }

  // ── 4. Các hàm hỗ trợ lưu trữ cục bộ SQLite ───────────────────────
  Future<List<int>> _getReadSystemBroadcastIds() async {
    final list = await DatabaseService.instance.readCache<List<dynamic>>(
      'read_broadcasts',
      (json) => json as List<dynamic>,
    );
    if (list == null) return [];
    return list.map((e) => int.tryParse(e.toString()) ?? 0).where((id) => id > 0).toList();
  }

  Future<void> _saveReadSystemBroadcastId(int id) async {
    final ids = await _getReadSystemBroadcastIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await DatabaseService.instance.writeCache(
        'read_broadcasts',
        ids,
        ttlSeconds: 315360000, // 10 năm
      );
    }
  }

  // ── 5. Reset khi logout ───────────────────────────────────────────
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _errorMessage = '';
    notifyListeners();
  }
}
