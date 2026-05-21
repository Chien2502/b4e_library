import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_error_handler.dart';
import '../data/models/chat_models.dart';

/// Provider quản lý chat cho phía User.
///
/// Hỗ trợ polling mỗi 5 giây khi màn hình chat đang mở.
class ChatProvider with ChangeNotifier {
  final _dio = DioClient().dio;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String _errorMessage = '';
  int? _threadId;
  Timer? _pollTimer;
  int _unreadCount = 0;

  // ── Getters ──────────────────────────────────────────────────────
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String get errorMessage => _errorMessage;
  int? get threadId => _threadId;
  int get unreadCount => _unreadCount;

  // ── Load tin nhắn ────────────────────────────────────────────────
  Future<void> loadMessages({bool isPolling = false}) async {
    if (!isPolling) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      final params = <String, dynamic>{'limit': 100};

      // Polling: chỉ lấy tin mới sau lastId
      if (isPolling && _messages.isNotEmpty) {
        params['after'] = _messages.last.id;
      }

      final res = await _dio.get(
        ApiConstants.chatMessages,
        queryParameters: params,
      );

      if (res.statusCode == 200) {
        final data = res.data;
        _threadId = data['thread_id'];

        if (isPolling && _messages.isNotEmpty) {
          // Append tin mới
          final newMessages = (data['data'] as List)
              .map((j) => ChatMessage.fromJson(j))
              .toList();
          if (newMessages.isNotEmpty) {
            _messages.addAll(newMessages);
            notifyListeners();
          }
        } else {
          // Load lần đầu
          _messages = (data['data'] as List)
              .map((j) => ChatMessage.fromJson(j))
              .toList();
        }
      }
    } on DioException catch (e) {
      if (!isPolling) {
        _errorMessage = NetworkErrorHandler.getFriendlyMessage(e);
      }
    } catch (e) {
      if (!isPolling) {
        _errorMessage = 'Lỗi tải tin nhắn: $e';
      }
    } finally {
      if (!isPolling) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // ── Gửi tin nhắn ────────────────────────────────────────────────
  Future<String?> sendMessage(String text) async {
    if (text.trim().isEmpty) return 'Tin nhắn không được để trống.';

    _isSending = true;
    notifyListeners();

    try {
      final res = await _dio.post(
        ApiConstants.chatSend,
        data: {'message': text.trim()},
      );

      if (res.statusCode == 200) {
        _threadId = res.data['thread_id'];
        // Thêm tin nhắn vào local ngay (optimistic update)
        _messages.add(ChatMessage(
          id: res.data['message_id'] ?? 0,
          senderType: 'user',
          message: text.trim(),
          createdAt: DateTime.now().toIso8601String(),
          isRead: false,
        ));
        _isSending = false;
        notifyListeners();
        return null; // Success
      }

      _isSending = false;
      notifyListeners();
      return res.data?['error'] ?? 'Lỗi không xác định.';
    } on DioException catch (e) {
      _isSending = false;
      notifyListeners();
      return NetworkErrorHandler.getFriendlyMessage(e);
    } catch (e) {
      _isSending = false;
      notifyListeners();
      return 'Lỗi: $e';
    }
  }

  // ── Mark read ────────────────────────────────────────────────────
  Future<void> markRead() async {
    try {
      await _dio.post(ApiConstants.chatMarkRead, data: {
        'thread_id': _threadId,
      });
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  // ── Polling control ──────────────────────────────────────────────
  void startPolling() {
    stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      loadMessages(isPolling: true);
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ── Kiểm tra unread (gọi từ profile) ────────────────────────────
  Future<void> checkUnread() async {
    try {
      final res = await _dio.get(ApiConstants.chatMessages, queryParameters: {'limit': 1});
      if (res.statusCode == 200 && res.data['thread_id'] != null) {
        // Đếm tin chưa đọc từ system
        final allRes = await _dio.get(ApiConstants.chatMessages, queryParameters: {'limit': 100});
        if (allRes.statusCode == 200) {
          final msgs = (allRes.data['data'] as List)
              .map((j) => ChatMessage.fromJson(j))
              .toList();
          _unreadCount = msgs.where((m) => m.isFromSystem && !m.isRead).length;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // ── Refresh toàn bộ ──────────────────────────────────────────────
  Future<void> refresh() async {
    _messages = [];
    await loadMessages();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
