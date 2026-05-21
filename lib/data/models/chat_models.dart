/// Model cho tin nhắn chat.
class ChatMessage {
  final int id;
  final String senderType; // 'user' | 'system'
  final String message;
  final String createdAt;
  final bool isRead;
  final String? adminName; // Chỉ có trong admin view

  ChatMessage({
    required this.id,
    required this.senderType,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.adminName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: int.tryParse(json['id'].toString()) ?? 0,
      senderType: json['sender_type'] ?? 'user',
      message: json['message'] ?? '',
      createdAt: json['created_at'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == '1' || json['is_read'] == true,
      adminName: json['admin_name'],
    );
  }

  bool get isFromUser => senderType == 'user';
  bool get isFromSystem => senderType == 'system';
}

/// Model cho thread chat (admin side).
class ChatThread {
  final int threadId;
  final int userId;
  final String username;
  final String? avatar;
  final String? lastMessage;
  final String? lastMessageAt;
  final String lastSender;
  final int unreadByAdmin;
  final bool isActive;

  ChatThread({
    required this.threadId,
    required this.userId,
    required this.username,
    this.avatar,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSender = 'user',
    this.unreadByAdmin = 0,
    this.isActive = true,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      threadId: int.tryParse(json['thread_id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      username: json['username'] ?? '',
      avatar: json['avatar'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'],
      lastSender: json['last_sender'] ?? 'user',
      unreadByAdmin: int.tryParse(json['unread_by_admin'].toString()) ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == '1' || json['is_active'] == true,
    );
  }

  bool get hasUnread => unreadByAdmin > 0;
}
