import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_error_handler.dart';
import '../data/models/borrowing_model.dart';
import '../core/services/push_notification_service.dart';
import '../core/network/connectivity_service.dart';
import '../core/database/database_service.dart';

/// Kết quả tính phí ship
class ShippingQuote {
  final bool available;
  final double distanceKm;
  final int shippingFee;
  final String message;

  const ShippingQuote({
    required this.available,
    required this.distanceKm,
    required this.shippingFee,
    required this.message,
  });
}

class MyBooksProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();

  List<Borrowing> _borrowings = [];
  bool _isLoading = false;
  String _errorMessage = '';

  final Set<int> _returningIds = {};

  StreamSubscription<Map<String, dynamic>>? _fcmSubscription;

  MyBooksProvider() {
    _fcmSubscription = PushNotificationService().bookStatusStream.listen((
      data,
    ) {
      // Re-fetch borrowings when any book status changes
      fetchMyBorrowings();
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  // ── Getters ────────────────────────────────────────────────────
  List<Borrowing> get borrowings => _borrowings;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool isReturning(int borrowId) => _returningIds.contains(borrowId);

  // ────────────────────────────────────────────────────────────────
  // 1. Lấy danh sách sách đã/đang mượn của user hiện tại
  //    → GET /api/users/borrowings.php (có JWT trong header)
  // ────────────────────────────────────────────────────────────────
  Future<void> fetchMyBorrowings({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = await DatabaseService.instance.readCache<List<Borrowing>>(
        'my_borrowings_cache',
        (json) {
          final list = json is List
              ? json
              : (json as Map)['data'] as List? ?? [];
          return list
              .map((j) => Borrowing.fromJson(j as Map<String, dynamic>))
              .toList();
        },
      );
      if (cached != null && cached.isNotEmpty) {
        _borrowings = cached;
        notifyListeners();
        // Cố gắng gọi API ngầm nếu mạng online để cập nhật
        if (!ConnectivityService().isOnline) return;
      }
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Response response = await _dioClient.dio.get(
        ApiConstants.userBorrowings,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        _borrowings = data.map((json) => Borrowing.fromJson(json)).toList();

        // Cache response
        await DatabaseService.instance.writeCache(
          'my_borrowings_cache',
          response.data,
          ttlSeconds: 86400, // 1 day
        );
      } else {
        _errorMessage = 'Lỗi server: ${response.statusCode}';
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

  // ────────────────────────────────────────────────────────────────
  // 2. Gửi yêu cầu trả sách
  //    → POST /api/borrowings/return.php { borrow_id }
  // ────────────────────────────────────────────────────────────────
  Future<String?> returnBook(int borrowId, {required String returnMethod}) async {
    if (!ConnectivityService().isOnline) {
      return 'Tính năng này cần kết nối internet. Vui lòng kiểm tra lại mạng!';
    }
    _returningIds.add(borrowId);
    notifyListeners();

    try {
      final Response res = await _dioClient.dio.post(
        ApiConstants.userReturn,
        data: {'borrow_id': borrowId, 'return_method': returnMethod},
      );

      if (res.statusCode == 200) {
        // Cập nhật local: status -> 'return_requested'
        _borrowings = _borrowings.map((b) {
          if (b.id == borrowId) {
            return Borrowing(
              id: b.id,
              bookId: b.bookId,
              title: b.title,
              author: b.author,
              imageUrl: b.imageUrl,
              webImageUrl: b.webImageUrl,
              status: 'return_requested',
              borrowDate: b.borrowDate,
              dueDate: b.dueDate,
              returnDate: b.returnDate,
              renewStatus: b.renewStatus,
              renewDays: b.renewDays,
              deliveryType: b.deliveryType,
              deliveryAddress: b.deliveryAddress,
              distanceKm: b.distanceKm,
              shippingFee: b.shippingFee,
              paymentMethod: b.paymentMethod,
              paymentStatus: b.paymentStatus,
              returnMethod: returnMethod,
            );
          }
          return b;
        }).toList();
        return null; // null = thành công
      } else {
        final msg = res.data?['error'] ?? 'Không thể gửi trả sách.';
        return msg;
      }
    } on DioException catch (e) {
      return NetworkErrorHandler.getFriendlyMessage(e);
    } finally {
      _returningIds.remove(borrowId);
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 2b. User xác nhận đã nhận sách hoặc xác nhận gửi shipper
  //    → POST /api/users/confirm_action.php { borrow_id, action }
  // ────────────────────────────────────────────────────────────────
  Future<String?> confirmUserAction(int borrowId, String action) async {
    if (!ConnectivityService().isOnline) {
      return 'Tính năng này cần kết nối internet. Vui lòng kiểm tra lại mạng!';
    }
    _isLoading = true;
    notifyListeners();

    try {
      final Response res = await _dioClient.dio.post(
        ApiConstants.userConfirmAction,
        data: {'borrow_id': borrowId, 'action': action},
      );

      if (res.statusCode == 200) {
        final newStatus = (action == 'confirm_receipt') ? 'borrowed' : 'return_shipping';
        // Cập nhật local status
        _borrowings = _borrowings.map((b) {
          if (b.id == borrowId) {
            return Borrowing(
              id: b.id,
              bookId: b.bookId,
              title: b.title,
              author: b.author,
              imageUrl: b.imageUrl,
              webImageUrl: b.webImageUrl,
              status: newStatus,
              borrowDate: b.borrowDate,
              dueDate: b.dueDate,
              returnDate: b.returnDate,
              renewStatus: b.renewStatus,
              renewDays: b.renewDays,
              deliveryType: b.deliveryType,
              deliveryAddress: b.deliveryAddress,
              distanceKm: b.distanceKm,
              shippingFee: b.shippingFee,
              paymentMethod: b.paymentMethod,
              paymentStatus: b.paymentStatus,
              returnMethod: b.returnMethod,
            );
          }
          return b;
        }).toList();
        notifyListeners();
        return null; // Thành công
      } else {
        return res.data?['error'] ?? 'Thao tác thất bại.';
      }
    } on DioException catch (e) {
      return NetworkErrorHandler.getFriendlyMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 3. Tính phí vận chuyển trước khi mượn ship
  // ────────────────────────────────────────────────────────────────
  Future<ShippingQuote?> calculateShipping({
    required double lat,
    required double lng,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        ApiConstants.calculateShipping,
        data: {'lat': lat, 'lng': lng},
      );
      final d = res.data as Map<String, dynamic>;
      return ShippingQuote(
        available: d['available'] == true,
        distanceKm: double.tryParse(d['distance_km']?.toString() ?? '0') ?? 0,
        shippingFee: int.tryParse(d['shipping_fee']?.toString() ?? '0') ?? 0,
        message: d['message']?.toString() ?? d['note']?.toString() ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 4. Tạo yêu cầu mượn sách (pickup hoặc delivery)
  // ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> createBorrowing({
    required int bookId,
    int borrowDays = 14,
    String deliveryType = 'pickup',
    String? deliveryAddress,
    double? deliveryLat,
    double? deliveryLng,
    String? paymentMethod,
  }) async {
    try {
      final body = <String, dynamic>{
        'book_id': bookId,
        'borrow_days': borrowDays,
        'delivery_type': deliveryType,
      };
      if (deliveryType == 'delivery') {
        body['delivery_address']  = deliveryAddress;
        body['delivery_lat']      = deliveryLat;
        body['delivery_lng']      = deliveryLng;
        body['payment_method']    = paymentMethod;
      }

      final res = await _dioClient.dio.post(ApiConstants.createBorrowing, data: body);
      if (res.statusCode == 201) {
        await fetchMyBorrowings(forceRefresh: true);
        return res.data as Map<String, dynamic>;
      }
      return {'error': res.data?['error'] ?? 'Lỗi không xác định'};
    } on DioException catch (e) {
      return {'error': NetworkErrorHandler.getFriendlyMessage(e)};
    }
  }

  // ────────────────────────────────────────────────────────────────
  // 5. Lấy thông tin VietQR để hiển thị màn hình thanh toán
  // ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchVietQR(int borrowingId) async {
    try {
      final res = await _dioClient.dio.get(
        ApiConstants.getVietQR,
        queryParameters: {'borrowing_id': borrowingId},
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }



  // ────────────────────────────────────────────────────────────────
  // 3. Xin gia hạn mượn sách
  //    → POST /api/borrowings/renew.php { borrow_id, renew_days }
  // ────────────────────────────────────────────────────────────────
  Future<String?> renewBorrowing(int borrowId, int days) async {
    if (!ConnectivityService().isOnline) {
      return 'Tính năng này cần kết nối internet. Vui lòng kiểm tra lại mạng!';
    }
    try {
      final Response res = await _dioClient.dio.post(
        ApiConstants.userRenewBorrowing,
        data: {'borrow_id': borrowId, 'renew_days': days},
      );

      if (res.statusCode == 200) {
        // Cập nhật local: renew_status -> 'pending'
        _borrowings = _borrowings.map((b) {
          if (b.id == borrowId) {
            return Borrowing(
              id: b.id,
              bookId: b.bookId,
              title: b.title,
              author: b.author,
              imageUrl: b.imageUrl,
              webImageUrl: b.webImageUrl,
              status: b.status,
              borrowDate: b.borrowDate,
              dueDate: b.dueDate,
              returnDate: b.returnDate,
              renewStatus: 'pending',
              renewDays: days,
            );
          }
          return b;
        }).toList();
        notifyListeners();
        return null;
      } else {
        return res.data?['error'] ?? 'Không thể gia hạn.';
      }
    } on DioException catch (e) {
      return NetworkErrorHandler.getFriendlyMessage(e);
    }
  }

  void clear() {
    _borrowings = [];
    _errorMessage = '';
    notifyListeners();
  }
}
