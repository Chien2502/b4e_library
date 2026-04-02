class ApiConstants {
  // ========== CẤU HÌNH CHÍNH ==========
  // Thay đổi dòng này mỗi khi bật lại Ngrok (chỉ cần đổi 1 chỗ duy nhất)
  static const String host =
      'https://arlette-irascible-containedly.ngrok-free.dev';

  // Base URL cho Dio client (không có dấu / cuối)
  static const String baseUrl = '$host/api';

  // ========== CÁC ENDPOINT ==========
  // Dio dùng đường dẫn tương đối (bỏ baseUrl phía trước)
  static const String readBooks = '/books/read.php';
  static const String login = '/auth/login.php';
  static const String register = '/auth/register.php';

  // ========== URL ẢNH ==========
  // URL file tĩnh (dùng cho mobile - không bị CORS)
  static const String uploadsUrl = '$host/api/uploads';

  // PHP proxy để phục vụ ảnh qua PHP (dùng cho Web - tránh CORS từ static file)
  // PHP xử lý header CORS giống các endpoint khác
  static const String imageProxy = '/books/image_proxy.php';
}
