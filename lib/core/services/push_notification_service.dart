import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/api_constants.dart';
import '../network/dio_client.dart';

// ── Background handler: phải là top-level function (không phải method) ────────
// Flutter chạy hàm này trong isolate riêng khi app bị tắt hoàn toàn.
//
// Phân loại message theo nguồn:
//   • Từ sendFcmToUser() (cá nhân): có cả notification + data field
//     → OS tự hiển thị notification popup, handler chỉ cần log
//   • Từ topic book_updates (broadcast): chỉ có data field (data-only)
//     → OS KHÔNG hiển thị popup, handler nhận nhưng không thể emit stream
//     → Book status sync chỉ có ý nghĩa khi user ĐANG mở app (foreground)
//     → Khi mở lại app, fetchLatestBooks() sẽ tự refresh từ API
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM Background] data: ${message.data}, hasNotif: ${message.notification != null}');
  // Data-only message (book_updates topic) — không cần xử lý thêm ở đây.
  // Khi user mở lại app, foreground listener sẽ tiếp tục hoạt động bình thường.
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

  // ── Stream 1: Đồng bộ trạng thái tồn kho sách (giữ nguyên logic cũ) ───────
  // Payload: { "book_id": 123, "is_available": true/false }
  final StreamController<Map<String, dynamic>> _bookStatusStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get bookStatusStream => _bookStatusStreamController.stream;

  // ── Stream 2: Điều hướng màn hình khi user tap notification ────────────────
  // Payload: { "type": "borrow_approved", "ref_id": 5 }
  final StreamController<Map<String, dynamic>> _notifTapStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationTapStream => _notifTapStreamController.stream;

  /// Set `true` khi admin đang mở màn hình chi tiết chat của 1 user.
  /// Khi flag này bật, foreground notification loại 'new_chat_message'
  /// sẽ được bỏ qua — tránh làm phiền admin đang tích cực trả lời.
  static bool isAdminInChatView = false;

  /// Khởi tạo toàn bộ FCM + local notifications.
  /// Gọi 1 lần duy nhất trong MainWrapper sau khi Firebase.initializeApp() hoàn tất.
  Future<void> init() async {
    // 1. Xin quyền hiển thị thông báo (iOS & Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    // 2. Đăng ký background handler (phải gọi trước khi lắng nghe foreground)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Subscribe topic book_updates (giữ tính năng đồng bộ tồn kho)
    try {
      await _fcm.subscribeToTopic('book_updates');
      debugPrint('[FCM] Subscribed to topic: book_updates');
    } catch (e) {
      debugPrint('[FCM] Failed to subscribe to topic book_updates: $e');
    }

    // 4. Khởi tạo flutter_local_notifications (để hiện popup khi foreground)
    await _initLocalNotifications();

    // 5. [TERMINATED] Kiểm tra nếu app được mở bằng cách tap notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from terminated via notification: ${initialMessage.data}');
      // Delay nhỏ để đảm bảo widget tree đã build xong trước khi điều hướng
      Future.delayed(const Duration(milliseconds: 800), () {
        _handleNotificationTap(initialMessage.data);
      });
    }

    // 6. [BACKGROUND → FOREGROUND] User tap notification khi app ở background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] App opened from background via notification: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // 7. [FOREGROUND] App đang mở → FCM không tự hiển thị popup, phải dùng local notif
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground message: ${message.data}');

      // Giữ logic cũ: đồng bộ trạng thái tồn kho sách
      _handleBookStatusData(message.data);

      // Hiển thị popup local notification (chỉ khi có notification payload)
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }

  // ── Khởi tạo flutter_local_notifications ─────────────────────────────────
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Đã xin quyền qua FCM ở trên
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tap local notification khi foreground
        if (response.payload != null) {
          try {
            final data = json.decode(response.payload!) as Map<String, dynamic>;
            _handleNotificationTap(data);
          } catch (e) {
            debugPrint('[FCM] Error parsing tap payload: $e');
          }
        }
      },
    );

    // Tạo Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'b4e_channel',
      'B4E Thông báo',
      description: 'Thông báo từ Thư viện B4E',
      importance: Importance.high,
      playSound: true,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    debugPrint('[FCM] Local notifications initialized');
  }

  // ── Hiển thị popup khi app đang foreground ─────────────────────────────────
  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Bỏ qua chat notification khi admin đang mở màn hình chat
    final msgType = message.data['type']?.toString() ?? '';
    if (msgType == 'new_chat_message' && isAdminInChatView) {
      debugPrint('[FCM] Suppressed chat notification — admin is in chat view');
      return;
    }

    final notif = message.notification!;

    final androidDetails = AndroidNotificationDetails(
      'b4e_channel',
      'B4E Thông báo',
      channelDescription: 'Thông báo từ Thư viện B4E',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      color: const Color(0xFF1565C0),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotif.show(
      message.hashCode,
      notif.title,
      notif.body,
      details,
      payload: json.encode(message.data), // Dùng để điều hướng khi tap
    );
  }

  // ── Điều hướng màn hình khi user tap notification ──────────────────────────
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type  = data['type']?.toString() ?? '';
    final refId = int.tryParse(data['ref_id']?.toString() ?? '');
    debugPrint('[FCM] Notification tapped: type=$type, ref_id=$refId');
    _notifTapStreamController.add({'type': type, 'ref_id': refId});
  }

  // ── Logic cũ: đồng bộ trạng thái tồn kho sách ─────────────────────────────
  void _handleBookStatusData(Map<String, dynamic> data) {
    if (data['action'] == 'status_changed') {
      try {
        final int bookId = int.parse(data['book_id'].toString());
        final String rawIsAvailable = data['is_available'].toString();
        final bool isAvailable = rawIsAvailable == '1' || rawIsAvailable == 'true';

        _bookStatusStreamController.add({
          'book_id': bookId,
          'is_available': isAvailable,
        });
      } catch (e) {
        debugPrint('[FCM] Error parsing book status data: $e');
      }
    }
  }

  // ── Lưu FCM token lên server sau khi đăng nhập ────────────────────────────
  /// Gọi hàm này sau khi user đăng nhập thành công hoặc khi checkAuthStatus() xác nhận đã đăng nhập.
  /// [role] dùng để đăng ký topic admin_chat nếu user là admin.
  Future<void> saveFcmTokenToServer({String? role}) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) {
        debugPrint('[FCM] No device token available');
        return;
      }
      debugPrint('[FCM] Device token: ${token.substring(0, 20)}...');

      // Gửi token lên server (DioClient tự gắn JWT Authorization header)
      final dio = DioClient().dio;
      await dio.post(ApiConstants.saveFcmToken, data: {'fcm_token': token});
      debugPrint('[FCM] Token saved to server successfully');

      // Tự động subscribe nhận thông báo toàn hệ thống (Superadmin Broadcast)
      try {
        await _fcm.subscribeToTopic('all_users');
        debugPrint('[FCM] Subscribed to topic: all_users');
      } catch (topicEx) {
        debugPrint('[FCM] Failed to subscribe to topic all_users: $topicEx');
      }

      // Admin: subscribe topic admin_chat để nhận thông báo chat mới
      if (role == 'admin' || role == 'super-admin') {
        try {
          await _fcm.subscribeToTopic('admin_chat');
          debugPrint('[FCM] Subscribed to topic: admin_chat');
        } catch (e) {
          debugPrint('[FCM] Failed to subscribe to topic admin_chat: $e');
        }
      }

      // Lắng nghe token refresh (xảy ra khi reinstall app hoặc clear data)
      _fcm.onTokenRefresh.listen((newToken) async {
        try {
          await dio.post(ApiConstants.saveFcmToken, data: {'fcm_token': newToken});
          debugPrint('[FCM] Refreshed token saved to server');
        } catch (e) {
          debugPrint('[FCM] Failed to save refreshed token: $e');
        }
      });
    } catch (e) {
      // Lỗi FCM không nên ảnh hưởng đến luồng đăng nhập
      debugPrint('[FCM] saveFcmTokenToServer error: $e');
    }
  }

  /// Hủy đăng ký nhận thông báo chung khi đăng xuất
  Future<void> unsubscribeFromTopics() async {
    try {
      await _fcm.unsubscribeFromTopic('all_users');
      debugPrint('[FCM] Unsubscribed from topic: all_users');
    } catch (e) {
      debugPrint('[FCM] Failed to unsubscribe from topic all_users: $e');
    }
    try {
      await _fcm.unsubscribeFromTopic('admin_chat');
      debugPrint('[FCM] Unsubscribed from topic: admin_chat');
    } catch (e) {
      debugPrint('[FCM] Failed to unsubscribe from topic admin_chat: $e');
    }
  }

  void dispose() {
    _bookStatusStreamController.close();
    _notifTapStreamController.close();
  }
}
