import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme_extensions.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedTopic = 'Báo lỗi';
  bool _submitted = false;

  final _topics = [
    'Báo lỗi',
    'Góp ý tính năng',
    'Hỏi về mượn/trả sách',
    'Khiếu nại',
    'Khác',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // Tạm thời: mở email client với nội dung đã điền
    final subject =
        Uri.encodeComponent('[B4E App] $_selectedTopic');
    final body = Uri.encodeComponent(
      'Họ tên: ${_nameCtrl.text}\n'
      'Email phản hồi: ${_emailCtrl.text}\n'
      'Chủ đề: $_selectedTopic\n\n'
      '${_messageCtrl.text}',
    );
    _launch('mailto:hotroB4E@gmail.com?subject=$subject&body=$body');
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? context.background : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? context.background : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hỗ trợ & Góp ý',
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
          children: [
            // ── Liên hệ nhanh ─────────────────────────────
            _buildQuickContactCards(),
            const SizedBox(height: 20),

            // ── Form góp ý ─────────────────────────────────
            _submitted ? _buildSuccessBanner() : _buildFeedbackForm(),
            const SizedBox(height: 20),

            // ── Giờ hỗ trợ ────────────────────────────────
            _buildSupportHours(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Các card liên hệ nhanh ─────────────────────────────────────
  Widget _buildQuickContactCards() {
    final contacts = [
      {
        'icon': Icons.phone_outlined,
        'color': Colors.green,
        'label': 'Gọi điện',
        'value': '0989 676 555',
        'url': 'tel:0989676555',
      },
      {
        'icon': Icons.email_outlined,
        'color': Colors.blue,
        'label': 'Email',
        'value': 'hotroB4E@gmail.com',
        'url': 'mailto:hotroB4E@gmail.com',
      },
      {
        'icon': Icons.location_on_outlined,
        'color': Colors.orange,
        'label': 'Địa chỉ',
        'value': '470 Trần Đại Nghĩa, Đà Nẵng',
        'url':
            'https://maps.google.com/?q=470+Trần+Đại+Nghĩa,+Ngũ+Hành+Sơn,+Đà+Nẵng',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liên hệ trực tiếp',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: context.textPrimary),
        ),
        const SizedBox(height: 10),
        ...contacts.map((c) => _buildContactCard(
              icon: c['icon'] as IconData,
              color: c['color'] as Color,
              label: c['label'] as String,
              value: c['value'] as String,
              onTap: () => _launch(c['url'] as String),
            )),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? context.card : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              color: context.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(value,
                          style: TextStyle(
                              fontSize: 14,
                              color: context.textPrimary,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.isDarkMode ? Colors.grey[700] : Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Form góp ý / báo lỗi ─────────────────────────────────────
  Widget _buildFeedbackForm() {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? context.card : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gửi góp ý & báo lỗi',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.blueAccent : const Color(0xFF1565C0))),
            const SizedBox(height: 4),
            Text('Phản hồi của bạn giúp chúng tôi cải thiện hệ thống tốt hơn.',
                style: TextStyle(fontSize: 12, color: context.textSecondary)),
            const SizedBox(height: 16),

            // Tên
            _buildLabel('Họ và tên', required: true),
            _buildField(
              controller: _nameCtrl,
              hint: 'Nhập tên của bạn...',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập tên'
                  : null,
            ),
            const SizedBox(height: 12),

            // Email
            _buildLabel('Email liên hệ', required: true),
            _buildField(
              controller: _emailCtrl,
              hint: 'email@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                if (!v.contains('@')) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Chủ đề
            _buildLabel('Chủ đề', required: true),
            _buildTopicDropdown(),
            const SizedBox(height: 12),

            // Nội dung
            _buildLabel('Nội dung', required: true),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 5,
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Vui lòng nhập ít nhất 10 ký tự'
                  : null,
              decoration: _fieldDecoration(
                  'Mô tả chi tiết vấn đề hoặc ý kiến của bạn...'),
              style: TextStyle(fontSize: 14, color: context.textPrimary),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.send_outlined,
                    color: Colors.white, size: 18),
                label: const Text('Gửi phản hồi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? context.card : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green[50], shape: BoxShape.circle),
            child: Icon(Icons.check_circle,
                color: isDark ? Colors.green[400] : Colors.green, size: 44),
          ),
          const SizedBox(height: 16),
          Text('Cảm ơn bạn đã phản hồi!',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Chúng tôi sẽ xem xét và phản hồi lại qua email của bạn trong vòng 1-2 ngày làm việc.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: context.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => setState(() {
              _submitted = false;
              _nameCtrl.clear();
              _emailCtrl.clear();
              _messageCtrl.clear();
            }),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF1E88E5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('Gửi thêm phản hồi',
                style:
                    TextStyle(color: Color(0xFF1E88E5), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Giờ hỗ trợ ────────────────────────────────────────────────
  Widget _buildSupportHours() {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.blue.withValues(alpha: 0.05) : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.1) : Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_outlined,
                  size: 18, color: isDark ? Colors.blueAccent : const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text('Giờ làm việc hỗ trợ',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.blueAccent : const Color(0xFF1565C0))),
            ],
          ),
          const SizedBox(height: 10),
          _buildHourRow('Thứ Hai – Thứ Sáu', '8:00 – 21:00'),
          _buildHourRow('Thứ Bảy – Chủ Nhật', '8:00 – 17:00'),
          _buildHourRow('Ngày lễ', 'Tạm nghỉ', isRed: true),
          const SizedBox(height: 8),
          Divider(height: 1, color: context.isDarkMode ? Colors.blue.withValues(alpha: 0.2) : const Color(0xFFBBDEFB)),
          const SizedBox(height: 8),
          Text(
            'Ngoài giờ làm việc, vui lòng gửi email hoặc để lại tin nhắn, chúng tôi sẽ phản hồi trong giờ làm việc hôm sau.',
            style: TextStyle(
                fontSize: 12, color: context.isDarkMode ? Colors.blue[200] : Colors.blue[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(String day, String hour, {bool isRed = false}) {
    final isDark = context.isDarkMode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(day,
                  style:
                      TextStyle(fontSize: 13, color: context.textPrimary))),
          Text(hour,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isRed
                      ? Colors.red[400]
                      : (isDark ? Colors.blueAccent : const Color(0xFF1565C0)))),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.textPrimary),
          children: required
              ? const [
                  TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red))
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _fieldDecoration(hint),
      style: TextStyle(fontSize: 14, color: context.textPrimary),
    );
  }

  Widget _buildTopicDropdown() {
    final isDark = context.isDarkMode;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? context.background : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? context.divider : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTopic,
          isExpanded: true,
          dropdownColor: isDark ? context.card : Colors.white,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.blueAccent),
          style: TextStyle(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.w500),
          items: _topics
              .map((t) => DropdownMenuItem(value: t, child: Text(t)))
              .toList(),
          onChanged: (v) =>
              setState(() => _selectedTopic = v ?? _topics[0]),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    final isDark = context.isDarkMode;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: context.textSecondary),
      filled: true,
      fillColor: isDark ? context.background : Colors.grey[50],
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? context.divider : Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

