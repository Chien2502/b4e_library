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
  static const String readSingleBook = '/books/read_single.php';
  static const String readCategories = '/categories/read.php';
  static const String createBorrowing = '/borrowings/create.php';
  static const String userBorrowings = '/users/borrowings.php';
  static const String userReturn = '/users/return.php';
  static const String createDonation = '/donations/create.php';
  static const String userDonations = '/users/donations.php';
  static const String login = '/auth/login.php';
  static const String register = '/auth/register.php';
  static const String getProfile = '/auth/get_profile.php';
  static const String updateProfile = '/auth/update_profile.php';

  // ========== NOTIFICATIONS ==========
  static const String getNotifications  = '/notifications/index.php';
  static const String markNotificationRead = '/notifications/mark_read.php';

  // ========== ADMIN — UPDATE STATUS (kèm thông báo tự động) ==========
  static const String adminUpdateBorrowStatus  = '/borrowings/update_status.php';
  static const String adminUpdateDonationStatus = '/donations/update_status.php';

  // ========== ADMIN ENDPOINTS ==========
  static const String adminStats = '/admin/get_stats.php';
  static const String adminUsers = '/admin/users.php';
  static const String adminGetUser = '/admin/get_user.php';
  static const String adminUpdateUser = '/admin/update_user.php';
  static const String adminDeleteUser = '/admin/delete_user.php';
  static const String adminBorrowings = '/admin/borrowings.php';
  static const String adminConfirmReturn = '/admin/confirm_return.php';
  static const String adminDonations = '/admin/donations.php';
  static const String adminApproveDonation = '/admin/approve_donation.php';
  static const String adminRejectDonation = '/admin/reject_donation.php';

  // ========== BOOK CRUD (Admin) ==========
  static const String createBook = '/books/create.php';
  static const String updateBook = '/books/update.php';
  static const String deleteBook = '/books/delete.php';

  // ========== CATEGORY CRUD (Admin) ==========
  static const String createCategory = '/categories/create.php';
  static const String updateCategory = '/categories/update.php';
  static const String deleteCategory = '/categories/delete.php';

  // ========== URL ẢNH ==========
  // URL file tĩnh (dùng cho mobile - không bị CORS)
  static const String uploadsUrl = '$host/api/uploads';

  // PHP proxy để phục vụ ảnh qua PHP (dùng cho Web - tránh CORS từ static file)
  // PHP xử lý header CORS giống các endpoint khác
  static const String imageProxy = '/books/image_proxy.php';
}

