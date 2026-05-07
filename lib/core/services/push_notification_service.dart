import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Hàm này chạy độc lập dưới background
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  // Stream để phát ra các sự kiện đồng bộ sách
  // Payload: { "book_id": 123, "is_available": true/false }
  final StreamController<Map<String, dynamic>> _bookStatusStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get bookStatusStream => _bookStatusStreamController.stream;

  Future<void> init() async {
    // 1. Xin quyền hiển thị thông báo (Cần thiết cho iOS & Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Đăng ký nhận Background Messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Đăng ký Topic để nhận tín hiệu cập nhật sách
    await _fcm.subscribeToTopic('book_updates');
    debugPrint('Subscribed to topic: book_updates');

    // 4. Lắng nghe Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      // Xử lý payload Data
      _handleMessageData(message.data);
    });
  }

  void _handleMessageData(Map<String, dynamic> data) {
    if (data['action'] == 'status_changed') {
      try {
        final int bookId = int.parse(data['book_id'].toString());
        // is_available có thể gửi dưới dạng '0' / '1' hoặc 'true' / 'false'
        final String rawIsAvailable = data['is_available'].toString();
        final bool isAvailable = rawIsAvailable == '1' || rawIsAvailable == 'true';

        _bookStatusStreamController.add({
          'book_id': bookId,
          'is_available': isAvailable,
        });
      } catch (e) {
        debugPrint("Error parsing FCM data: $e");
      }
    }
  }

  void dispose() {
    _bookStatusStreamController.close();
  }
}
