import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/notification_model.dart';
import '../../viewmodels/notification_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  // ── Icon theo type ────────────────────────────────────────────────
  IconData _iconFor(String type) {
    switch (type) {
      case 'borrow_approved':
        return Icons.check_circle_rounded;
      case 'borrow_rejected':
        return Icons.cancel_rounded;
      case 'return_overdue':
        return Icons.alarm_rounded;
      case 'return_reminder':
        return Icons.schedule_rounded;
      case 'donation_approved':
        return Icons.favorite_rounded;
      case 'donation_rejected':
        return Icons.heart_broken_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // ── Màu theo type ─────────────────────────────────────────────────
  Color _colorFor(String type) {
    switch (type) {
      case 'borrow_approved':
      case 'donation_approved':
        return Colors.green;
      case 'borrow_rejected':
      case 'donation_rejected':
        return Colors.red;
      case 'return_overdue':
        return Colors.deepOrange;
      case 'return_reminder':
        return Colors.orange;
      default:
        return const Color(0xFF1565C0);
    }
  }

  // ── Format thời gian ─────────────────────────────────────────────
  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // Nút "Đọc tất cả"
          Consumer<NotificationProvider>(
            builder: (context, prov, child) {
              if (!prov.hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: prov.markAllAsRead,
                child: const Text(
                  'Đọc tất cả',
                  style: TextStyle(
                    color: Color(0xFF1565C0),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, prov, child) {
          // Loading
          if (prov.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            );
          }

          // Lỗi
          if (prov.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(prov.errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: prov.fetchNotifications,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            );
          }

          // Trống
          if (prov.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Chưa có thông báo nào',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey[500])),
                ],
              ),
            );
          }

          // Danh sách
          return RefreshIndicator(
            onRefresh: prov.fetchNotifications,
            color: const Color(0xFF1565C0),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: prov.notifications.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72, endIndent: 16),
              itemBuilder: (_, i) => _buildItem(prov.notifications[i], prov),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItem(AppNotification n, NotificationProvider prov) {
    final color = _colorFor(n.type);

    return InkWell(
      onTap: () => prov.markAsRead(n.id),
      child: Container(
        color: n.isRead ? Colors.transparent : color.withAlpha(15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon vòng tròn
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconFor(n.type), color: color, size: 22),
            ),
            const SizedBox(width: 12),

            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Chấm xanh nếu chưa đọc
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(n.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
