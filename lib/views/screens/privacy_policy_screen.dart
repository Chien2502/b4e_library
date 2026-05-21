import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Ngày cập nhật chính sách
  static const String _lastUpdated = '01/04/2026';

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
          'Chính sách bảo mật',
          style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            _buildHeader(),
            const SizedBox(height: 16),

            // ── Mục lục ─────────────────────────────────────
            _buildTableOfContents(context),
            const SizedBox(height: 20),

            // ── Các điều khoản ──────────────────────────────
            _buildSection(context, '1. Thông tin chúng tôi thu thập', [
              _buildParagraph(
                context,
                'Khi bạn đăng ký và sử dụng ứng dụng B4E, chúng tôi thu thập các thông tin sau:',
              ),
              _buildBullet(context, heading: 'Thông tin đăng ký:', text: 'Tên người dùng (username), địa chỉ email, số điện thoại và địa chỉ nhà.'),
              _buildBullet(context, heading: 'Thông tin hoạt động:', text: 'Lịch sử mượn sách, lịch sử quyên góp sách, và thời gian tương tác với hệ thống.'),
              _buildBullet(context, heading: 'Thông tin kỹ thuật:', text: 'Phiên bản ứng dụng, hệ điều hành thiết bị, và thông tin kết nối nhằm đảm bảo tính ổn định của hệ thống.'),
            ]),

            _buildSection(context, '2. Mục đích sử dụng thông tin', [
              _buildParagraph(context, 'Các thông tin thu thập được sử dụng cho các mục đích sau:'),
              _buildBullet(context, text: 'Xử lý yêu cầu mượn sách và theo dõi tiến trình trả sách.'),
              _buildBullet(context, text: 'Ghi nhận và xét duyệt các đơn quyên góp sách.'),
              _buildBullet(context, text: 'Liên hệ với bạn khi cần thiết (xác nhận mượn, nhắc nhở trả sách,...).'),
              _buildBullet(context, text: 'Cải thiện trải nghiệm người dùng và phát triển các tính năng mới.'),
              _buildBullet(context, text: 'Thống kê tổng hợp phục vụ báo cáo hoạt động thư viện (ẩn danh, không định danh cá nhân).'),
            ]),

            _buildSection(context, '3. Chia sẻ thông tin với bên thứ ba', [
              _buildParagraph(
                context,
                'B4E cam kết KHÔNG bán, trao đổi hoặc chuyển giao thông tin cá nhân của bạn '
                'cho bất kỳ bên thứ ba nào vì mục đích thương mại.',
              ),
              _buildParagraph(
                context,
                'Thông tin chỉ được chia sẻ trong các trường hợp đặc biệt sau:',
              ),
              _buildBullet(context, text: 'Khi có yêu cầu hợp pháp từ cơ quan nhà nước có thẩm quyền.'),
              _buildBullet(context, text: 'Khi cần thiết để bảo vệ quyền lợi hợp pháp của tổ chức hoặc người dùng khác.'),
            ]),

            _buildSection(context, '4. Bảo mật thông tin', [
              _buildParagraph(
                context,
                'Chúng tôi áp dụng các biện pháp kỹ thuật và tổ chức phù hợp để bảo vệ thông tin cá nhân của bạn:',
              ),
              _buildBullet(context, text: 'Mật khẩu được mã hóa bằng thuật toán băm an toàn, không ai có thể đọc lại được.'),
              _buildBullet(context, text: 'Token xác thực (JWT) có thời hạn hiệu lực và được lưu trữ an toàn trên thiết bị.'),
              _buildBullet(context, text: 'Giao tiếp giữa ứng dụng và máy chủ được thực hiện qua kết nối bảo mật (HTTPS).'),
              _buildBullet(context, text: 'Hệ thống cơ sở dữ liệu được kiểm soát truy cập nghiêm ngặt, chỉ những người có thẩm quyền mới được phép truy cập.'),
            ]),

            _buildSection(context, '5. Quyền của người dùng', [
              _buildParagraph(context, 'Bạn có đầy đủ các quyền sau đối với thông tin cá nhân của mình:'),
              _buildBullet(context, heading: 'Quyền truy cập:', text: 'Xem và kiểm tra thông tin cá nhân thông qua màn hình "Hồ sơ".'),
              _buildBullet(context, heading: 'Quyền chỉnh sửa:', text: 'Cập nhật tên, số điện thoại và địa chỉ bất kỳ lúc nào.'),
              _buildBullet(context, heading: 'Quyền xóa tài khoản:', text: 'Yêu cầu xóa tài khoản và toàn bộ dữ liệu liên quan bằng cách liên hệ qua email hotroB4E@gmail.com.'),
              _buildBullet(context, heading: 'Quyền phản đối:', text: 'Từ chối nhận email thông báo không cần thiết.'),
            ]),

            _buildSection(context, '6. Lưu trữ dữ liệu', [
              _buildParagraph(
                context,
                'Dữ liệu của bạn được lưu trữ trên máy chủ đặt tại Việt Nam. '
                'Thông tin cá nhân sẽ được lưu giữ trong suốt thời gian tài khoản còn hoạt động. '
                'After sau khi tài khoản bị xóa, dữ liệu sẽ được ẩn danh hóa và giữ lại tối đa 30 ngày '
                'trước khi xóa hoàn toàn khỏi hệ thống.',
              ),
            ]),

            _buildSection(context, '7. Sử dụng Cookie & Token', [
              _buildParagraph(
                context,
                'Ứng dụng B4E sử dụng JSON Web Token (JWT) thay cho cookie để xác thực người dùng. '
                'Token này được lưu trữ an toàn trong bộ nhớ bảo mật của thiết bị (Secure Storage), '
                'không thể bị truy cập bởi các ứng dụng khác.',
              ),
            ]),

            _buildSection(context, '8. Liên hệ về chính sách bảo mật', [
              _buildParagraph(context, 'Nếu bạn có thắc mắc hoặc yêu cầu liên quan đến chính sách bảo mật, vui lòng liên hệ:'),
              _buildContactInfo(context, Icons.email_outlined, 'hotroB4E@gmail.com'),
              _buildContactInfo(context, Icons.phone_outlined, '0989 676 555'),
              _buildContactInfo(context, Icons.location_on_outlined,
                  '470 Trần Đại Nghĩa, Ngũ Hành Sơn, Đà Nẵng'),
            ]),

            // ── Ghi chú cuối ─────────────────────────────────
            _buildFooterNote(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.privacy_tip_outlined,
                  color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                'Chính sách bảo mật B4E',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Chúng tôi tôn trọng quyền riêng tư của bạn và cam kết bảo vệ thông tin '
            'cá nhân theo các tiêu chuẩn bảo mật cao nhất.',
            style: TextStyle(
                color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Cập nhật lần cuối: $_lastUpdated',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableOfContents(BuildContext context) {
    final items = [
      'Thông tin chúng tôi thu thập',
      'Mục đích sử dụng thông tin',
      'Chia sẻ thông tin với bên thứ ba',
      'Bảo mật thông tin',
      'Quyền của người dùng',
      'Lưu trữ dữ liệu',
      'Sử dụng Cookie & Token',
      'Liên hệ về chính sách bảo mật',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mục lục',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: context.textPrimary)),
          const SizedBox(height: 10),
          ...items.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Text('${e.key + 1}. ',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary)),
                    Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                fontSize: 13,
                                color: context.textSecondary))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: context.isDarkMode
                  ? Colors.transparent
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: context.colors.primary)),
          Divider(height: 16, color: context.divider),
          ...content,
        ],
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 13.5, color: context.textSecondary, height: 1.6)),
    );
  }

  Widget _buildBullet(BuildContext context, {String? heading, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ',
              style: TextStyle(
                  color: context.colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 13.5,
                    color: context.textSecondary,
                    height: 1.5),
                children: [
                  if (heading != null)
                    TextSpan(
                      text: '$heading ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.colors.primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(fontSize: 13, color: context.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildFooterNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: context.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chính sách này có hiệu lực từ ngày $_lastUpdated. '
              'B4E có quyền cập nhật chính sách này và sẽ thông báo cho người dùng '
              'qua email hoặc thông báo trong ứng dụng.',
              style: TextStyle(
                  fontSize: 11.5, color: context.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

