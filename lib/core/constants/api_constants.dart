import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // ========== CẤU HÌNH CHÍNH ==========
  // Thay đổi dòng này mỗi khi bật lại Ngrok (chỉ cần đổi 1 chỗ duy nhất)
  static String get host => dotenv.env['API_HOST'] ?? 'http://10.0.2.2/b4eproject';

  // Base URL cho Dio client (không có dấu / cuối)
  static String get baseUrl => '$host/api';

  // ========== CÁC ENDPOINT ==========
  // Dio dùng đường dẫn tương đối (bỏ baseUrl phía trước)
  static const String readBooks = '/books/read.php';
  static const String readSingleBook = '/books/read_single.php';
  static const String relatedBooks   = '/books/related.php';
  static const String readCategories = '/categories/read.php';
  static const String createBorrowing = '/borrowings/create.php';
  static const String userBorrowings = '/users/borrowings.php';
  static const String userReturn = '/users/return.php';
  static const String userConfirmAction = '/users/confirm_action.php';
  static const String userRenewBorrowing = '/borrowings/renew.php';
  static const String createDonation = '/donations/create.php';
  static const String userDonations = '/users/donations.php';
  static const String login = '/auth/login.php';
  static const String register = '/auth/register.php';
  static const String getProfile = '/auth/get_profile.php';
  static const String updateProfile = '/auth/update_profile.php';
  static const String uploadAvatar  = '/auth/upload_avatar.php';
  static const String refreshToken  = '/auth/refresh.php';
  static const String saveFcmToken  = '/auth/save_fcm_token.php';

  // ========== NOTIFICATIONS ==========
  static const String getNotifications     = '/notifications/index.php';
  static const String markNotificationRead = '/notifications/mark_read.php';

  // ========== RECOMMENDATIONS ==========
  static const String popularBooks    = '/books/popular.php';
  static const String recommendations = '/recommendations/index.php';


  // ========== ADMIN — UPDATE STATUS (kèm thông báo tự động) ==========
  static const String adminUpdateBorrowStatus  = '/borrowings/update_status.php';
  static const String adminUpdateDonationStatus = '/donations/update_status.php';

  // ========== DELIVERY & PAYMENT ==========
  static const String calculateShipping = '/borrowings/calculate_shipping.php';
  static const String getVietQR         = '/borrowings/get_vietqr.php';
  static const String confirmPayment    = '/borrowings/confirm_payment.php';


  // ========== ADMIN ENDPOINTS ==========
  static const String adminStats = '/admin/get_stats.php';
  static const String adminUsers = '/admin/users.php';
  static const String adminGetUser = '/admin/get_user.php';
  static const String adminUpdateUser = '/admin/update_user.php';
  static const String adminDeleteUser = '/admin/delete_user.php';
  static const String adminBorrowings = '/admin/borrowings.php';
  static const String adminConfirmReturn = '/admin/confirm_return.php';
  static const String adminHandleRenewal = '/admin/handle_renewal.php';
  static const String adminDonations = '/admin/donations.php';
  static const String adminApproveDonation = '/admin/approve_donation.php';
  static const String adminRejectDonation = '/admin/reject_donation.php';

  // Alias tường minh dùng trong admin borrowings tab
  static const String updateBorrowingStatus = '/borrowings/update_status.php';
  static const String broadcastNotification = '/admin/send_broadcast.php';

  // ========== BOOK CRUD (Admin) ==========
  static const String createBook = '/books/create.php';
  static const String updateBook = '/books/update.php';
  static const String deleteBook = '/books/delete.php';

  // ========== CATEGORY CRUD (Admin) ==========
  static const String createCategory = '/categories/create.php';
  static const String updateCategory = '/categories/update.php';
  static const String deleteCategory = '/categories/delete.php';

  // ========== AI & BOOK RECOGNITION ==========
  /// Tra cứu thông tin sách theo ISBN (proxy đến OpenLibrary / Google Books)
  static const String isbnLookup    = '/books/lookup.php';
  /// Phân tích bìa sách bằng Gemini Vision (yêu cầu Auth Admin)
  static const String analyzeCover  = '/ai/analyze_cover.php';

  // ========== CHAT (User ↔ Admin) ==========
  static const String chatSend     = '/chat/send.php';
  static const String chatMessages = '/chat/messages.php';
  static const String chatThreads  = '/chat/threads.php';
  static const String chatReply    = '/chat/reply.php';
  static const String chatMarkRead = '/chat/mark_read.php';

  // ========== URL ẢNH ==========
  // URL file tĩnh (dùng cho mobile - không bị CORS)
  static String get uploadsUrl => '$host/api/uploads';

  // PHP proxy để phục vụ ảnh qua PHP (dùng cho Web - tránh CORS từ static file)
  // PHP xử lý header CORS giống các endpoint khác
  static const String imageProxy = '/books/image_proxy.php';
}

