import 'package:dio/dio.dart';

class NetworkErrorHandler {
  /// Chuyển đổi các Exception/Error từ hệ thống thành thông báo thân thiện với người dùng.
  /// Ẩn đi các chi tiết kỹ thuật phức tạp (SQLSTATE, Connection Refused, Exception stack trace...).
  static String getFriendlyMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Kết nối đến máy chủ bị quá hạn. Vui lòng thử lại sau.';
          
        case DioExceptionType.connectionError:
          return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet.';
          
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final responseData = error.response?.data;
          
          // Kiểm tra xem phản hồi có chứa lỗi cơ sở dữ liệu (MySQL, SQLSTATE, v.v...) không
          if (responseData != null) {
            final responseStr = responseData.toString().toLowerCase();
            if (responseStr.contains('mysql') || 
                responseStr.contains('database') || 
                responseStr.contains('sqlstate') ||
                responseStr.contains('connection refused') ||
                responseStr.contains('query error') ||
                responseStr.contains('mariadb') ||
                responseStr.contains('pdoexception')) {
              return 'Hệ thống đang gặp sự cố kết nối cơ sở dữ liệu. Vui lòng quay lại sau!';
            }
            
            // Nếu response là Map (JSON) và chứa 'message' hoặc 'error'
            if (responseData is Map) {
              if (responseData.containsKey('message') && responseData['message'] != null) {
                final msg = responseData['message'].toString();
                // Ẩn nếu là SQL error rò rỉ trong message JSON
                if (_isTechnicalError(msg)) {
                  return 'Máy chủ gặp sự cố xử lý dữ liệu. Vui lòng liên hệ quản trị viên.';
                }
                return msg;
              } else if (responseData.containsKey('error') && responseData['error'] != null) {
                final err = responseData['error'].toString();
                if (_isTechnicalError(err)) {
                  return 'Máy chủ gặp sự cố xử lý dữ liệu. Vui lòng liên hệ quản trị viên.';
                }
                return err;
              }
            }
          }
          
          if (statusCode != null) {
            if (statusCode >= 500) {
              return 'Máy chủ đang gặp sự cố hệ thống (Lỗi $statusCode). Vui lòng thử lại sau.';
            } else if (statusCode == 404) {
              return 'Không tìm thấy thông tin yêu cầu (Lỗi 404).';
            } else if (statusCode == 403) {
              return 'Bạn không có quyền truy cập tính năng này.';
            } else if (statusCode == 401) {
              return 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.';
            } else if (statusCode == 400) {
              return 'Yêu cầu không hợp lệ. Vui lòng thử lại.';
            }
          }
          return 'Phản hồi từ máy chủ không hợp lệ.';
          
        case DioExceptionType.cancel:
          return 'Yêu cầu đã bị hủy bỏ.';
          
        case DioExceptionType.badCertificate:
          return 'Kết nối không an toàn (Lỗi chứng chỉ bảo mật).';
          
        case DioExceptionType.unknown:
          final errorMessage = error.message ?? '';
          if (errorMessage.contains('SocketException') || errorMessage.contains('NetworkIsUnreachable')) {
            return 'Không có kết nối mạng. Vui lòng kiểm tra Wi-Fi hoặc dữ liệu di động.';
          }
          return 'Đã xảy ra lỗi kết nối không xác định. Vui lòng thử lại.';
      }
    } else {
      // Các lỗi không phải DioException (Lỗi logic, Exception tự định nghĩa, null pointer,...)
      final errorStr = error.toString().toLowerCase();
      if (errorStr.contains('socketexception') || errorStr.contains('network')) {
        return 'Mất kết nối mạng hoặc đường truyền không ổn định.';
      } else if (errorStr.contains('mysql') || errorStr.contains('database') || errorStr.contains('sqlstate')) {
        return 'Hệ thống đang gặp sự cố cơ sở dữ liệu. Vui lòng quay lại sau!';
      }
      return 'Đã xảy ra lỗi hệ thống không mong muốn.';
    }
  }

  /// Trả về true nếu chuỗi thông báo chứa các chi tiết kỹ thuật rò rỉ (không thân thiện với user).
  static bool _isTechnicalError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('sql') || 
           lower.contains('mysql') || 
           lower.contains('database') || 
           lower.contains('exception') || 
           lower.contains('syntax error') || 
           lower.contains('query') || 
           lower.contains('nullpointer') ||
           lower.contains('fatal') ||
           lower.contains('stack trace');
  }
}
