import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_error_handler.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../data/models/chat_models.dart';

class AdminChatTab extends StatefulWidget {
  const AdminChatTab({super.key});

  @override
  State<AdminChatTab> createState() => _AdminChatTabState();
}

class _AdminChatTabState extends State<AdminChatTab> {
  final _dio = DioClient().dio;
  List<ChatThread> _threads = [];
  bool _isLoading = false;
  String _error = '';
  String _filter = 'all'; // 'all' | 'unread'
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadThreads();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadThreads(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadThreads({bool silent = false}) async {
    if (!silent) {
      setState(() { _isLoading = true; _error = ''; });
    }
    try {
      final res = await _dio.get(ApiConstants.chatThreads);
      if (res.statusCode == 200) {
        final data = res.data['data'] as List;
        setState(() {
          _threads = data.map((j) => ChatThread.fromJson(j)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!silent) {
        setState(() {
          _error = NetworkErrorHandler.getFriendlyMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  List<ChatThread> get _filteredThreads {
    if (_filter == 'unread') {
      return _threads.where((t) => t.hasUnread).toList();
    }
    return _threads;
  }

  int get _totalUnread => _threads.fold(0, (sum, t) => sum + t.unreadByAdmin);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header + Filter ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.chat_outlined, color: context.colors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Chat hỗ trợ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  if (_totalUnread > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_totalUnread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    onPressed: _loadThreads,
                    icon: Icon(Icons.refresh, color: context.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFilterChip('Tất cả', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Chưa đọc ($_totalUnread)', 'unread'),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Thread list ────────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error, style: TextStyle(color: Colors.grey[600])),
                          TextButton(onPressed: _loadThreads, child: const Text('Thử lại')),
                        ],
                      ),
                    )
                  : _filteredThreads.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadThreads,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _filteredThreads.length,
                            separatorBuilder: (_, _a) => Divider(height: 1, indent: 72, color: context.divider),
                            itemBuilder: (ctx, i) => _buildThreadTile(_filteredThreads[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : context.textPrimary)),
      selected: selected,
      selectedColor: const Color(0xFF1565C0),
      backgroundColor: context.isDarkMode ? context.card : Colors.grey[100],
      side: BorderSide.none,
      onSelected: (_) => setState(() => _filter = value),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _filter == 'unread' ? 'Không có tin nhắn chưa đọc' : 'Chưa có cuộc trò chuyện nào',
            style: TextStyle(fontSize: 15, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildThreadTile(ChatThread thread) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFF1565C0).withValues(alpha: 0.15),
        backgroundImage: thread.avatar != null && thread.avatar!.isNotEmpty
            ? NetworkImage('${ApiConstants.uploadsUrl}/${thread.avatar}')
            : null,
        child: thread.avatar == null || thread.avatar!.isEmpty
            ? Text(
                thread.username.isNotEmpty ? thread.username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              thread.username,
              style: TextStyle(
                fontWeight: thread.hasUnread ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: context.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (thread.lastMessageAt != null)
            Text(
              _formatThreadTime(thread.lastMessageAt!),
              style: TextStyle(
                fontSize: 11,
                color: thread.hasUnread ? const Color(0xFF1565C0) : Colors.grey[500],
                fontWeight: thread.hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (thread.lastSender == 'system')
            Text(
              '✓ Đã trả lời: ',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          Expanded(
            child: Text(
              thread.lastMessage ?? 'Chưa có tin nhắn',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: thread.hasUnread ? context.textPrimary : Colors.grey[500],
                fontWeight: thread.hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (thread.hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${thread.unreadByAdmin}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _AdminChatDetailScreen(thread: thread),
          ),
        );
        _loadThreads();
      },
    );
  }

  String _formatThreadTime(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (d.day == now.day && d.month == now.month && d.year == now.year) {
        return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (d.day == yesterday.day && d.month == yesterday.month && d.year == yesterday.year) {
        return 'Hôm qua';
      }
      return '${d.day}/${d.month}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// Admin Chat Detail Screen (nằm chung file để đơn giản)
// ════════════════════════════════════════════════════════════════════
class _AdminChatDetailScreen extends StatefulWidget {
  final ChatThread thread;
  const _AdminChatDetailScreen({required this.thread});

  @override
  State<_AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<_AdminChatDetailScreen> {
  final _dio = DioClient().dio;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Báo cho FCM biết admin đang xem chat — suppress foreground popup
    PushNotificationService.isAdminInChatView = true;
    _loadMessages();
    _markRead();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  @override
  void dispose() {
    // Khôi phục lại khi rời khỏi màn hình
    PushNotificationService.isAdminInChatView = false;
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final res = await _dio.get(ApiConstants.chatMessages, queryParameters: {
        'thread_id': widget.thread.threadId,
        'limit': 100,
      });
      if (res.statusCode == 200) {
        setState(() {
          _messages = (res.data['data'] as List)
              .map((j) => ChatMessage.fromJson(j))
              .toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _poll() async {
    if (_messages.isEmpty) return;
    try {
      final res = await _dio.get(ApiConstants.chatMessages, queryParameters: {
        'thread_id': widget.thread.threadId,
        'after': _messages.last.id,
        'limit': 50,
      });
      if (res.statusCode == 200) {
        final newMsgs = (res.data['data'] as List)
            .map((j) => ChatMessage.fromJson(j))
            .toList();
        if (newMsgs.isNotEmpty) {
          setState(() => _messages.addAll(newMsgs));
          _scrollToBottom();
          _markRead();
        }
      }
    } catch (_) {}
  }

  Future<void> _markRead() async {
    try {
      await _dio.post(ApiConstants.chatMarkRead, data: {
        'thread_id': widget.thread.threadId,
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    setState(() => _isSending = true);

    try {
      final res = await _dio.post(ApiConstants.chatReply, data: {
        'thread_id': widget.thread.threadId,
        'message': text,
      });
      if (res.statusCode == 200) {
        _messages.add(ChatMessage(
          id: res.data['message_id'] ?? 0,
          senderType: 'system',
          message: text,
          createdAt: DateTime.now().toIso8601String(),
          isRead: false,
          adminName: 'Bạn',
        ));
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(NetworkErrorHandler.getFriendlyMessage(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Text(
                widget.thread.username.isNotEmpty
                    ? widget.thread.username[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.thread.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'ID: ${widget.thread.userId}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có tin nhắn',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final showDate = i == 0 || _differentDay(_messages[i - 1].createdAt, msg.createdAt);
                          return Column(
                            children: [
                              if (showDate) _buildDateSeparator(msg.createdAt),
                              _buildBubble(msg),
                            ],
                          );
                        },
                      ),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    // Admin view: user ở trái, system (admin) ở phải
    final isSystem = msg.isFromSystem;
    return Align(
      alignment: isSystem ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: EdgeInsets.only(
          top: 4, bottom: 4,
          left: isSystem ? 48 : 0,
          right: isSystem ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment: isSystem ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isSystem)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  widget.thread.username,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                ),
              ),
            if (isSystem && msg.adminName != null)
              Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 4),
                child: Text(
                  'Trả lời bởi ${msg.adminName}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSystem
                    ? const Color(0xFF1565C0)
                    : (context.isDarkMode ? context.colors.surfaceContainerHighest : Colors.grey[100]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isSystem ? 16 : 4),
                  bottomRight: Radius.circular(isSystem ? 4 : 16),
                ),
              ),
              child: Text(
                msg.message,
                style: TextStyle(
                  fontSize: 14,
                  color: isSystem ? Colors.white : context.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text(
                _formatTime(msg.createdAt),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(String dateStr) {
    final label = _formatDateLabel(dateStr);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ),
          Expanded(child: Divider(color: context.divider)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.card,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? context.colors.surfaceContainerHighest : Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _msgController,
                    maxLines: null,
                    style: TextStyle(fontSize: 14, color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Trả lời ${widget.thread.username}...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: Color(0xFF1565C0), shape: BoxShape.circle),
                child: IconButton(
                  onPressed: _isSending ? null : _sendReply,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _differentDay(String a, String b) {
    try {
      final da = DateTime.parse(a);
      final db = DateTime.parse(b);
      return da.day != db.day || da.month != db.month || da.year != db.year;
    } catch (_) { return false; }
  }

  String _formatDateLabel(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (d.day == now.day && d.month == now.month && d.year == now.year) return 'Hôm nay';
      final y = now.subtract(const Duration(days: 1));
      if (d.day == y.day && d.month == y.month && d.year == y.year) return 'Hôm qua';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return dateStr; }
  }

  String _formatTime(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }
}
