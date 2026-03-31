import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

    // Thêm Interceptor (Người gác cổng)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Tự động lấy Token từ két sắt (nếu có) và nhét vào Header trước khi gửi đi
          String? token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Dữ liệu trả về thành công thì cho đi tiếp
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Xử lý lỗi tập trung ở đây (VD: Mất mạng, Lỗi 401 hết hạn Token, Lỗi 500 từ PHP)
          print('Lỗi gọi API: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  // Cung cấp instance của Dio ra ngoài để các nơi khác dùng
  Dio get dio => _dio;
}
