import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

class BorrowingGuideScreen extends StatelessWidget {
  const BorrowingGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hướng dẫn mượn sách',
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner ──────────────────────────────────────────
            _buildBanner(),
            const SizedBox(height: 20),

            // ── Điều kiện ───────────────────────────────────────
            _buildSection(
              context,
              icon: Icons.checklist_outlined,
              color: context.colors.primary,
              title: 'Điều kiện mượn sách',
              children: [
                _buildBullet(context, 'Là thành viên đã đăng ký tài khoản trên hệ thống B4E.'),
                _buildBullet(context, 'Mỗi tài khoản được mượn tối đa 3 quyển sách cùng lúc.'),
                _buildBullet(context, 'Thời hạn mượn tối đa là 15 ngày kể từ ngày nhận sách.'),
                _buildBullet(context, 'Sách phải được trả về trong tình trạng nguyên vẹn, không bị rách, ướt hoặc mất trang.'),
              ],
            ),

            // ── Các bước ────────────────────────────────────────
            _buildSection(
              context,
              icon: Icons.format_list_numbered_outlined,
              color: context.isDarkMode ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
              title: 'Các bước mượn sách',
              children: [
                _buildStep(context, 1, 'Tìm sách', 'Vào tab "Tìm kiếm", lọc theo thể loại hoặc tên sách bạn muốn mượn.'),
                _buildStep(context, 2, 'Xem chi tiết', 'Nhấn vào thẻ sách để xem đầy đủ thông tin, tác giả, mô tả và trạng thái còn sẵn.'),
                _buildStep(context, 3, 'Nhấn Mượn sách', 'Ở màn hình chi tiết, nhấn nút "Mượn sách" ở cuối trang và xác nhận yêu cầu.'),
                _buildStep(context, 4, 'Chờ xác nhận', 'Hệ thống sẽ ghi nhận yêu cầu. Ban quản lý sẽ liên hệ để sắp xếp giao nhận.'),
                _buildStep(context, 5, 'Nhận sách', 'Đến thư viện hoặc nhận tại địa điểm đã hẹn. Sách sẽ chuyển sang trạng thái "Đang mượn".'),
              ],
            ),

            // ── Trả sách ────────────────────────────────────────
            _buildSection(
              context,
              icon: Icons.assignment_return_outlined,
              color: context.isDarkMode ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00),
              title: 'Quy trình trả sách',
              children: [
                _buildBullet(context, 'Vào tab "Sách của tôi" → chọn sách muốn trả → nhấn nút "Trả sách".'),
                _buildBullet(context, 'Hệ thống sẽ cập nhật trạng thái "Đang xử lý".'),
                _buildBullet(context, 'Mang sách đến thư viện hoặc liên hệ để sắp xếp trả qua dịch vụ chuyển phát.'),
                _buildBullet(context, 'Sau khi ban quản lý xác nhận, sách sẽ chuyển sang "Đã trả".'),
              ],
            ),

            // ── Phí & Phạt ───────────────────────────────────────
            _buildSection(
              context,
              icon: Icons.attach_money_outlined,
              color: context.error,
              title: 'Phí & Quy định phạt',
              children: [
                _buildKeyValue(context, 'Phí mượn sách:', 'Miễn phí hoàn toàn'),
                _buildKeyValue(context, 'Phí trễ hạn:', '2.000đ / ngày / cuốn sau ngày hết hạn'),
                _buildKeyValue(context, 'Sách hư hỏng nặng:', 'Bồi thường 50% giá bìa sách'),
                _buildKeyValue(context, 'Mất sách:', 'Bồi thường 100% giá bìa sách'),
              ],
            ),

            // ── Lưu ý ────────────────────────────────────────────
            _buildNoteBox(
              context,
              '📌 Lưu ý quan trọng',
              'Trong quá trình mượn sách, nếu có vấn đề xảy ra (hư hỏng, thất lạc,...), '
              'vui lòng liên hệ ngay với thư viện qua email hotroB4E@gmail.com hoặc '
              'số điện thoại 0989 676 555 để được hỗ trợ kịp thời.',
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mượn sách dễ dàng',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                SizedBox(height: 4),
                Text(
                  'Đọc bất cứ cuốn sách nào bạn muốn,\nmiễn phí 100% từ thư viện cộng đồng B4E.',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: context.isDarkMode
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isDarkMode ? 0.15 : 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color)),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ',
              style: TextStyle(
                  color: context.colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13, color: context.textSecondary, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, int num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(top: 1, right: 10),
            decoration: BoxDecoration(
                color: context.colors.primary, shape: BoxShape.circle),
            child: Center(
              child: Text('$num',
                  style: TextStyle(
                      color: context.colors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimary)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(
                        fontSize: 12, color: context.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValue(BuildContext context, String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(key,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: context.textPrimary)),
          ),
          Expanded(
              child: Text(value,
                  style: TextStyle(fontSize: 13, color: context.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildNoteBox(BuildContext context, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.amber.withValues(alpha: 0.15)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: context.isDarkMode
                ? Colors.amber.withValues(alpha: 0.3)
                : Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: context.textPrimary)),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                  fontSize: 13, color: context.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}

