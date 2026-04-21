import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
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
        _unreadCount = int.tryParse(data['unread_count']?.toString() ?? '0') ?? 0;
        final list = data['data'] as List<dynamic>;
        _notifications =
            list.map((j) => AppNotification.fromJson(j)).toList();
      } else {
        _errorMessage = 'Lỗi server: ${res.statusCode}';
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

  // ── 2. Đánh dấu 1 thông báo đã đọc ──────────────────────────────
  Future<void> markAsRead(int notificationId) async {
    // Cập nhật local ngay lập tức (optimistic update)
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx == -1 || _notifications[idx].isRead) return;

    _notifications[idx] = AppNotification(
      id: _notifications[idx].id,
      title: _notifications[idx].title,
      message: _notifications[idx].message,
      type: _notifications[idx].type,
      refId: _notifications[idx].refId,
      isRead: true,
      createdAt: _notifications[idx].createdAt,
    );
    _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    notifyListeners();

    // Gửi lên server (silent — không hiện lỗi nếu thất bại)
    try {
      await _dioClient.dio.post(
        ApiConstants.markNotificationRead,
        data: {'notification_id': notificationId},
      );
    } catch (_) {}
  }

  // ── 3. Đánh dấu TẤT CẢ đã đọc ───────────────────────────────────
  Future<void> markAllAsRead() async {
    // Optimistic update
    _notifications = _notifications
        .map((n) => AppNotification(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              refId: n.refId,
              isRead: true,
              createdAt: n.createdAt,
            ))
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

  // ── 4. Reset khi logout ───────────────────────────────────────────
  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _errorMessage = '';
    notifyListeners();
  }
}
