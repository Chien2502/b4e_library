class ApiConstants {
  // Thay đổi dòng này mỗi khi bật lại Ngrok
  static const String baseUrl = 'https://arlette-irascible-containedly.ngrok-free.dev/api';

  // Các đường dẫn API cụ thể sẽ tự động nối vào baseUrl
  static const String readBooks = '$baseUrl/books/read.php';
  static const String login = '$baseUrl/auth/login.php'; // Ví dụ thêm
  static const String register = '$baseUrl/auth/register.php';
}




