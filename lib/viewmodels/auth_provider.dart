import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';

class AuthProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading =>
      _isLoading; // UI sẽ đọc biến này để hiện vòng xoay loading

  // Hàm Đăng nhập
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners(); // Báo cho UI biết để hiện Loading

    try {
      // Gọi API gửi dữ liệu lên PHP
      Response response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      // Giả sử Backend PHP trả về JSON: {"status": "success", "token": "eyJh..."}
      if (response.statusCode == 200 && response.data['token'] != null) {
        // Lấy Token và cất vào két sắt an toàn của hệ điều hành
        String token = response.data['token'];
        await _storage.write(key: 'jwt_token', value: token);

        _isLoading = false;
        notifyListeners();
        return true; // Đăng nhập thành công
      }

      _isLoading = false;
      notifyListeners();
      return false; // Sai thông tin
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Lỗi đăng nhập: $e');
      return false;
    }
  }

  // Hàm Đăng ký
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Gọi API Đăng ký (đảm bảo các key 'full_name', 'email', 'password' khớp với Backend PHP)
      Response response = await _dioClient.dio.post(
        ApiConstants.register,
        data: {'username': username, 'email': email, 'password': password},
      );

      // Giả sử Backend trả về status 201 (Created) hoặc 200, và có chuỗi 'success'
      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true; // Đăng ký thành công
      }

      _isLoading = false;
      notifyListeners();
      return false; // Thất bại (VD: Email đã tồn tại)
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Lỗi đăng ký: $e');
      return false;
    }
  }

  // Hàm Đăng xuất (Xóa token)
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    notifyListeners();
  }
}
