import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../data/models/borrowing_model.dart';

class MyBooksProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();

  List<Borrowing> _borrowings = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Tập ID đang trong quá trình gửi trả (hiển thị "Đang xử lý...")
  final Set<int> _returningIds = {};

  // ── Getters ────────────────────────────────────────────────────
  List<Borrowing> get borrowings => _borrowings;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool isReturning(int borrowId) => _returningIds.contains(borrowId);

  // ────────────────────────────────────────────────────────────────
  // 1. Lấy danh sách sách đã/đang mượn của user hiện tại
  //    → GET /api/users/borrowings.php (có JWT trong header)
  // ────────────────────────────────────────────────────────────────
  Future<void> fetchMyBorrowings() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Response response =
          await _dioClient.dio.get(ApiConstants.userBorrowings);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        _borrowings =
            data.map((json) => Borrowing.fromJson(json)).toList();
      } else {
        _errorMessage = 'Lỗi server: ${response.statusCode}';
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

  // ────────────────────────────────────────────────────────────────
  // 2. Gửi yêu cầu trả sách
  //    → POST /api/users/return.php  { borrow_id: id }
  //    → Backend đổi status sang 'returning', Admin xác nhận sau
  // ────────────────────────────────────────────────────────────────
  Future<String?> returnBook(int borrowId) async {
    _returningIds.add(borrowId);
    notifyListeners();

    try {
      final Response res = await _dioClient.dio.post(
        ApiConstants.userReturn,
        data: {'borrow_id': borrowId},
      );

      if (res.statusCode == 200) {
        // Cập nhật local: đổi status của borrowing này thành 'returning'
        _borrowings = _borrowings.map((b) {
          if (b.id == borrowId) {
            return Borrowing(
              id: b.id,
              bookId: b.bookId,
              title: b.title,
              author: b.author,
              imageUrl: b.imageUrl,
              webImageUrl: b.webImageUrl,
              status: 'returning',
              borrowDate: b.borrowDate,
              dueDate: b.dueDate,
              returnDate: b.returnDate,
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
      final serverMsg = e.response?.data?['error'];
      return serverMsg ?? 'Lỗi kết nối: ${e.message}';
    } finally {
      _returningIds.remove(borrowId);
      notifyListeners();
    }
  }

  void clear() {
    _borrowings = [];
    _errorMessage = '';
    notifyListeners();
  }
}
