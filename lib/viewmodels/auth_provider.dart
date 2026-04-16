import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';

// ── User data model (fields từ SELECT id, username, email, phone, address, role) ──
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String phone;
  final String address;
  final String role; // 'user' | 'admin' | 'super-admin'

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.address,
    required this.role,
  });

  bool get isAdmin => role == 'admin' || role == 'super-admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        role: json['role']?.toString() ?? 'user',
      );

  UserProfile copyWith({
    String? username,
    String? phone,
    String? address,
  }) =>
      UserProfile(
        id: id,
        username: username ?? this.username,
        email: email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
        role: role,
      );
}

enum AuthStatus { uninitialized, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final DioClient _dioClient = DioClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthStatus _status = AuthStatus.uninitialized;
  AuthStatus get status => _status;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  // ── Khởi động: kiểm tra JWT còn hạn không ────────────────────
  Future<void> checkAuthStatus() async {
    final String? token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      _status = AuthStatus.authenticated;
      // Tải profile ngầm sau khi restore session
      fetchProfile();
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  // ── Lấy profile từ server ──────────────────────────────────────
  Future<void> fetchProfile() async {
    try {
      final Response res =
          await _dioClient.dio.get(ApiConstants.getProfile);
      if (res.statusCode == 200) {
        _userProfile = UserProfile.fromJson(res.data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchProfile error: $e');
    }
  }

  // ── Cập nhật profile (username, phone, address) ───────────────
  /// Trả về null nếu thành công, chuỗi lỗi nếu thất bại
  Future<String?> updateProfile({
    required String username,
    required String phone,
    required String address,
  }) async {
    try {
      final Response res = await _dioClient.dio.post(
        ApiConstants.updateProfile,
        data: {
          'username': username,
          'phone': phone,
          'address': address,
        },
      );

      if (res.statusCode == 200) {
        // Cập nhật local ngay mà không cần gọi lại server
        _userProfile = _userProfile?.copyWith(
          username: username,
          phone: phone,
          address: address,
        );
        notifyListeners();
        return null; // success
      }
      return res.data?['error'] ?? 'Cập nhật thất bại.';
    } on DioException catch (e) {
      return e.response?.data?['error'] ??
          'Lỗi kết nối: ${e.message ?? e.type.name}';
    }
  }

  // ── Đăng nhập ─────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Response response = await _dioClient.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final String token = response.data['token'];
        await _storage.write(key: 'jwt_token', value: token);
        _status = AuthStatus.authenticated;
        _isLoading = false;
        notifyListeners();
        // Tải profile ngay sau login
        fetchProfile();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Lỗi đăng nhập: $e');
      return false;
    }
  }

  // ── Đăng ký ──────────────────────────────────────────────────
  Future<bool> register(
      String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final Response response = await _dioClient.dio.post(
        ApiConstants.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Lỗi đăng ký: $e');
      return false;
    }
  }

  // ── Đăng xuất ─────────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    _userProfile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
