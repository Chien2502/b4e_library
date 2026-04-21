/// Model cho 1 thông báo — từ GET /api/notifications/index.php
class AppNotification {
  final int id;
  final String title;
  final String message;
  final String type; // borrow_approved | borrow_rejected | return_overdue | donation_approved | donation_rejected | system
  final int? refId;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.refId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      refId: json['ref_id'] != null
          ? int.tryParse(json['ref_id'].toString())
          : null,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
