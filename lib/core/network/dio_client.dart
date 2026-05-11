import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../viewmodels/auth_provider.dart';
import '../constants/api_constants.dart';
import '../utils/snackbar_utils.dart';

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
        onError: (DioException e, handler) async {
          debugPrint('Lỗi gọi API: ${e.message}');
          
          // Xử lý tự động đăng xuất hoặc làm mới token khi token hết hạn/không hợp lệ (401)
          if (e.response?.statusCode == 401) {
            String? refreshToken = await _storage.read(key: 'refresh_token');
            
            if (refreshToken != null) {
              try {
                // Sử dụng Dio mới để không bị loop interceptor
                final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
                final refreshRes = await refreshDio.post(
                  ApiConstants.refreshToken,
                  data: {'refresh_token': refreshToken},
                  options: Options(
                    headers: {'ngrok-skip-browser-warning': 'true'},
                  ),
                );

                if (refreshRes.statusCode == 200 && refreshRes.data['token'] != null) {
                  // Lưu token mới
                  final newToken = refreshRes.data['token'];
                  final newRefreshToken = refreshRes.data['refresh_token'];
                  
                  await _storage.write(key: 'jwt_token', value: newToken);
                  if (newRefreshToken != null) {
                    await _storage.write(key: 'refresh_token', value: newRefreshToken);
                  }

                  // Retry request cũ với token mới
                  final retryOptions = e.requestOptions;
                  retryOptions.headers['Authorization'] = 'Bearer $newToken';
                  
                  final retryDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
                  final retryResponse = await retryDio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (refreshErr) {
                debugPrint('Lỗi làm mới token: $refreshErr');
              }
            }

            // Nếu không có refresh token hoặc làm mới thất bại -> Đăng xuất
            final context = navigatorKey.currentContext;
            if (context != null) {
              // Gọi hàm logout
              Provider.of<AuthProvider>(context, listen: false).logout();
              
              // Hiển thị thông báo (ẩn các thông báo cũ để tránh spam)
              SnackBarUtils.showError(context, 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.');
            }
          }
          
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}

