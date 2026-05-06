import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../viewmodels/auth_provider.dart';
import '../constants/api_constants.dart';

class DioClient {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Gắn JWT token vào header nếu đã đăng nhập
          String? token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Header này bỏ qua trang cảnh báo của Ngrok (free tier).
          // Ngrok có thể trả HTML thay vì JSON cho BẤT KỲ client nào
          // kể cả native mobile — gây lỗi parse im lặng.
          // Gửi header này cho cả web lẫn mobile là an toàn.
          options.headers['ngrok-skip-browser-warning'] = 'true';

          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint('Lỗi gọi API: ${e.message}');
          
          // Xử lý tự động đăng xuất khi token hết hạn hoặc không hợp lệ (401)
          if (e.response?.statusCode == 401) {
            final context = navigatorKey.currentContext;
            if (context != null) {
              // Gọi hàm logout
              Provider.of<AuthProvider>(context, listen: false).logout();
              
              // Hiển thị thông báo (ẩn các thông báo cũ để tránh spam)
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

