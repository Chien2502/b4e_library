import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chat_provider.dart';
import '../../data/models/chat_models.dart';
import '../../core/theme/theme_extensions.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      provider.loadMessages().then((_) {
        _scrollToBottom();
        provider.markRead();
      });
      provider.startPolling();
    });
  }

  @override
  void dispose() {
    context.read<ChatProvider>().stopPolling();
    _msgController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    final error = await context.read<ChatProvider>().sendMessage(text);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      _scrollToBottom();
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
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.support_agent, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat với Hệ thống',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Hỗ trợ mượn trả sách',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Messages area ────────────────────────────────────────
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (ctx, chat, _) {
                if (chat.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chat.errorMessage.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(chat.errorMessage, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: chat.refresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (chat.messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  itemCount: chat.messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = chat.messages[i];
                    final showDate = i == 0 ||
                        _differentDay(chat.messages[i - 1].createdAt, msg.createdAt);
                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(msg.createdAt),
                        _buildMessageBubble(msg),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Chào mừng bạn! 👋',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gửi tin nhắn để được hỗ trợ về mượn sách, trả sách, hoặc bất kỳ vấn đề gì.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('Hỏi về cách mượn sách'),
                _buildSuggestionChip('Gia hạn mượn sách'),
                _buildSuggestionChip('Báo lỗi ứng dụng'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: context.isDarkMode ? context.card : Colors.grey[100],
      side: BorderSide(color: context.divider),
      onPressed: () {
        _msgController.text = text;
        _sendMessage();
      },
    );
  }

  // ── Date separator ───────────────────────────────────────────────
  Widget _buildDateSeparator(String dateStr) {
    final label = _formatDateLabel(dateStr);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
          Expanded(child: Divider(color: context.divider)),
        ],
      ),
    );
  }

  // ── Message bubble ───────────────────────────────────────────────
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isUser ? 48 : 0,
          right: isUser ? 0 : 48,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Sender label (chỉ hiện cho system)
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.support_agent,
                        size: 12,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hệ thống',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

            // Bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF1565C0)
                    : (context.isDarkMode
                        ? context.colors.surfaceContainerHighest
                        : Colors.grey[100]),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.message,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : context.textPrimary,
                  height: 1.4,
                ),
              ),
            ),

            // Timestamp
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

  // ── Input bar ────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
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
                    color: context.isDarkMode
                        ? context.colors.surfaceContainerHighest
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _msgController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: TextStyle(fontSize: 14, color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Consumer<ChatProvider>(
                builder: (ctx, chat, _) {
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1565C0),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: chat.isSending ? null : _sendMessage,
                      icon: chat.isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
  bool _differentDay(String a, String b) {
    try {
      final da = DateTime.parse(a);
      final db = DateTime.parse(b);
      return da.day != db.day || da.month != db.month || da.year != db.year;
    } catch (_) {
      return false;
    }
  }

  String _formatDateLabel(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (d.day == now.day && d.month == now.month && d.year == now.year) {
        return 'Hôm nay';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (d.day == yesterday.day && d.month == yesterday.month && d.year == yesterday.year) {
        return 'Hôm qua';
      }
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
