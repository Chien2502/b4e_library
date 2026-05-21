import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/theme_extensions.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        backgroundColor: context.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Về chúng tôi',
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
        child: Column(
          children: [
            _buildHeroBanner(),
            _buildQuoteSection(context),
            _buildTeamSection(context),
            _buildContactSection(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── 1. Banner ─────────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_library_outlined,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'B4E – Book For Everyone',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Thư viện cộng đồng – Chia sẻ tri thức',
            style: TextStyle(fontSize: 13, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── 2. Câu chuyện / Quote ─────────────────────────────────────
  Widget _buildQuoteSection(BuildContext context) {
    return Container(
      color: context.card,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          // Blockquote
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: context.colors.primary, width: 4),
              ),
              color: context.isDarkMode
                  ? context.colors.primary.withValues(alpha: 0.1)
                  : const Color(0xFFE3F2FD),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Text(
              '"Chúng tôi tin rằng mỗi cuốn sách đều chứa đựng một thế giới, '
              'và mỗi người đều xứng đáng được khám phá những thế giới ấy"',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: context.textPrimary,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 20),

          _buildParagraph(
            context,
            'Đó là tâm nhìn chung mà đội ngũ sáng lập đã thống nhất khi '
            'quyết định xây dựng dự án B4E – Book for everyone.',
          ),
          const SizedBox(height: 10),
          _buildParagraph(
            context,
            'Sau bao nhiêu nỗ lực, nhóm chúng mình đã cho ra mắt bản mobile '
            'nơi mà mọi người có thể mượn những quyển sách dự án đang có, '
            'hãy quyên góp thêm sách để gia tăng độ đa dạng của kho lưu trữ '
            'của dự án.',
          ),
          const SizedBox(height: 10),
          _buildParagraph(
            context,
            'Từ ước mơ ban đầu của đội ngũ sáng lập, dự án B4E đã trở thành '
            'ngôi nhà chung của những người yêu sách, nơi tri thức được '
            'tự do chia sẻ và lan tỏa.',
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 13.5, color: context.textSecondary, height: 1.65),
    );
  }

  // ── 3. Đội ngũ sáng lập ──────────────────────────────────────
  Widget _buildTeamSection(BuildContext context) {
    const members = [
      {
        'name': 'Nguyễn Thanh Chiến',
        'role': 'ĐỒNG SÁNG LẬP & GIÁM ĐỐC ĐIỀU HÀNH',
        'bio': [
          'Hơn 2 năm kinh nghiệm trong lĩnh vực quản lý và tổ chức sự kiện văn hóa',
          'Từng đạt nhiều giải thưởng học sinh giỏi môn văn trong quá khứ',
          'Đam mê sách và tin rằng sách có thể thay đổi cuộc sống của mỗi người',
        ],
        'email': 'chien@b4eproject.com',
      },
      {
        'name': 'Huỳnh Kim Thống',
        'role': 'ĐỒNG SÁNG LẬP & GIÁM ĐỐC NỘI DUNG',
        'bio': [
          'Bươn chải với đời và nắm bắt được thực trạng cuộc sống',
          'Từng tổ chức nhiều sự kiện trong học đường trong quá khứ',
          'Từng đạt giải thưởng khuyến khích cấp thành phố về các phong trào thi đua và tiên phong',
        ],
        'email': 'thong@b4eproject.com',
      },
    ];

    return Container(
      color: context.background,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        children: [
          Text(
            'Đội ngũ sáng lập',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gặp gỡ những người sáng lập đầy nhiệt huyết phía sau dự án Thư Viện Cộng Đồng',
            style: TextStyle(fontSize: 12, color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // 2 cards cuộn ngang
          SizedBox(
            height: 310,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (_, a) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final m = members[i];
                return SizedBox(
                  width: 260,
                  child: _buildMemberCard(
                    context,
                    name: m['name'] as String,
                    role: m['role'] as String,
                    bio: m['bio'] as List<String>,
                    email: m['email'] as String,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context, {
    required String name,
    required String role,
    required List<String> bio,
    required String email,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.transparent
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar placeholder
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                child: Text(
                  name[0],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.divider),
          const SizedBox(height: 10),

          // Bullet bio
          ...bio.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),
          Divider(height: 1, color: context.divider),
          const SizedBox(height: 8),

          // Email + Facebook links
          Row(
            children: [
              InkWell(
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: context.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Email',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.facebook, size: 14, color: context.colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Facebook',
                      style: TextStyle(fontSize: 12, color: context.colors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 4. Thông tin liên hệ ──────────────────────────────────────
  Widget _buildContactSection(BuildContext context) {
    return Container(
      color: context.card,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Thông tin liên hệ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildContactRow(
            context,
            icon: Icons.location_on_outlined,
            label: 'Văn phòng chính:',
            value: '470 Trần Đại Nghĩa, Ngũ Hành Sơn, Đà Nẵng',
            valueColor: context.colors.primary,
          ),
          _buildContactRow(
            context,
            icon: Icons.phone_outlined,
            label: 'Điện thoại:',
            value: '0989 676 555',
          ),
          _buildContactRow(
            context,
            icon: Icons.email_outlined,
            label: 'Email:',
            value: 'hotroB4E@gmail.com',
            valueColor: context.colors.primary,
          ),
          _buildContactRow(
            context,
            icon: Icons.language_outlined,
            label: 'Website:',
            value: 'B4EProject',
            valueColor: context.colors.primary,
          ),

          const SizedBox(height: 16),

          // Giờ hoạt động
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Giờ hoạt động:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 22),
                    Text(
                      'Thứ Hai – Chủ Nhật: ',
                      style: TextStyle(fontSize: 13, color: context.textSecondary),
                    ),
                    Text(
                      '8:00 – 21:00',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 22),
                    Text(
                      'Ngày lễ: ',
                      style: TextStyle(fontSize: 13, color: context.textSecondary),
                    ),
                    Text(
                      'Tạm nghỉ',
                      style: TextStyle(fontSize: 13, color: context.error),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bản đồ vị trí văn phòng (Google Maps)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: context.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(15.9753, 108.2523), // Tọa độ 470 Trần Đại Nghĩa
                      initialZoom: 15.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none, // Vô hiệu hóa thao tác (scroll/zoom)
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.b4e_library',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: const LatLng(15.9753, 108.2523),
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Lớp phủ để bắt sự kiện mở Google Maps external
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _launch('https://maps.google.com/?q=15.9753,108.2523'),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: context.isDarkMode
                                ? Colors.transparent
                                : Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, size: 14, color: context.colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Chỉ đường',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: context.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? context.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

