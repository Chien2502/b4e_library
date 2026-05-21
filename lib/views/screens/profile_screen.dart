import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import 'about_screen.dart';
import 'admin_screen.dart';
import 'borrowing_guide_screen.dart';
import 'chat_screen.dart';
import 'support_screen.dart';
import 'privacy_policy_screen.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/theme_picker_dialog.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/theme/theme_extensions.dart';
import '../../viewmodels/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Edit form controllers ──────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    // Prefill từ provider nếu đã có
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillForm();
    });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _prefillForm() {
    final user = context.read<AuthProvider>().userProfile;
    if (user != null) {
      _usernameCtrl.text = user.username;
      _phoneCtrl.text = user.phone;
      _addressCtrl.text = user.address;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final err = await context.read<AuthProvider>().updateProfile(
      username: _usernameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (err == null) _isEditing = false;
    });

    if (err == null) {
      SnackBarUtils.showSuccess(context, 'Cập nhật thành công!');
    } else {
      SnackBarUtils.showError(context, err);
    }
  }

  // ── Chọn ảnh và upload avatar ──────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đổi ảnh đại diện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn ảnh từ camera hoặc thư viện',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildAvatarOption(
              icon: Icons.camera_alt_rounded,
              color: const Color(0xFF1E88E5),
              title: 'Chụp ảnh mới',
              subtitle: 'Sử dụng camera để chụp ảnh đại diện',
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _buildAvatarOption(
              icon: Icons.photo_library_rounded,
              color: const Color(0xFF00897B),
              title: 'Chọn từ thư viện',
              subtitle: 'Chọn ảnh có sẵn trong thiết bị',
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);

    final err = await context.read<AuthProvider>().uploadAvatar(File(picked.path));

    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);

    if (err == null) {
      SnackBarUtils.showSuccess(context, 'Cập nhật ảnh đại diện thành công! ✓');
    } else {
      SnackBarUtils.showError(context, err);
    }
  }

  Widget _buildAvatarOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: context.divider),
          borderRadius: BorderRadius.circular(14),
          color: context.isDarkMode ? context.colors.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey[50],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: context.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.userProfile;

        // Còn đang tải profile lần đầu
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Sync controllers khi profile thay đổi từ bên ngoài
        if (!_isEditing) {
          _usernameCtrl.text = user.username;
          _phoneCtrl.text = user.phone;
          _addressCtrl.text = user.address;
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── Header avatar + tên ──────────────────────────────
              _buildProfileHeader(user),

              const SizedBox(height: 12),

              // ── Nút Admin (chỉ hiện với admin/super-admin) ───────
              if (user.isAdmin) _buildAdminCard(context),

              // ── Form thông tin cá nhân ───────────────────────────
              _buildInfoCard(context, user),

              const SizedBox(height: 12),

              // ── Menu nhanh ───────────────────────────────────────
              _buildQuickMenu(context),

              const SizedBox(height: 12),

              // ── Nút đăng xuất ───────────────────────────────────
              _buildLogoutButton(context),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET 1: Header — Avatar + tên + email + badge role
  // ════════════════════════════════════════════════════════════════
  Widget _buildProfileHeader(UserProfile user) {
    final String roleLabel = user.role == 'super-admin'
        ? 'Super Admin'
        : user.role == 'admin'
        ? 'Admin'
        : 'Thành viên';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        children: [
          // Avatar vòng tròn — hiển thị ảnh thật hoặc chữ cái đầu
          GestureDetector(
            onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl != null
                      ? null
                      : Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                // Overlay loading khi đang upload
                if (_isUploadingAvatar)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Nút camera nhỏ
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 15,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.username,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: Text(
              roleLabel,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET 2: Card Admin Panel (chỉ hiển thị nếu isAdmin)
  // ════════════════════════════════════════════════════════════════
  Widget _buildAdminCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF283593)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trang quản trị',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Quản lý sách, người dùng & quyên góp',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET 3: Thông tin cá nhân (xem + chỉnh sửa)
  // ════════════════════════════════════════════════════════════════
  Widget _buildInfoCard(BuildContext context, UserProfile user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: Color(0xFF1E88E5),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    if (_isEditing) {
                      // Hủy → restore
                      setState(() {
                        _isEditing = false;
                        _usernameCtrl.text = user.username;
                        _phoneCtrl.text = user.phone;
                        _addressCtrl.text = user.address;
                      });
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                  icon: Icon(
                    _isEditing ? Icons.close : Icons.edit_outlined,
                    size: 16,
                  ),
                  label: Text(_isEditing ? 'Hủy' : 'Sửa'),
                  style: TextButton.styleFrom(
                    foregroundColor: _isEditing
                        ? Colors.grey
                        : const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.divider),

          // Nội dung: chế độ xem hoặc edit
          _isEditing ? _buildEditForm() : _buildViewMode(user),
        ],
      ),
    );
  }

  // ── Chế độ xem ────────────────────────────────────────────────
  Widget _buildViewMode(UserProfile user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, 'Tên đăng nhập', user.username),
          _buildInfoRow(Icons.email_outlined, 'Email', user.email),
          _buildInfoRow(
            Icons.phone_outlined,
            'Điện thoại',
            user.phone.isNotEmpty ? user.phone : '—',
          ),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Địa chỉ',
            user.address.isNotEmpty ? user.address : '—',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: context.divider.withValues(alpha: 0.5)),
      ],
    );
  }

  // ── Chế độ edit ───────────────────────────────────────────────
  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildEditField(
              controller: _usernameCtrl,
              label: 'Tên đăng nhập',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 12),
            _buildEditField(
              controller: _phoneCtrl,
              label: 'Điện thoại',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập số điện thoại'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildEditField(
              controller: _addressCtrl,
              label: 'Địa chỉ',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập địa chỉ'
                  : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final borderColor = context.isDarkMode ? context.divider : Colors.grey[300]!;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(fontSize: 14, color: context.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: context.textSecondary),
        filled: true,
        fillColor: context.isDarkMode ? context.card : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.colors.error),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET 4: Quick Menu (Về chúng tôi, Cài đặt,...)
  // ════════════════════════════════════════════════════════════════
  Widget _buildQuickMenu(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().userProfile?.isAdmin ?? false;
    final items = [
      {
        'icon': Icons.menu_book_outlined,
        'title': 'Hướng dẫn mượn sách',
        'subtitle': 'Cách mượn, trả và quy định',
        'color': Colors.teal,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BorrowingGuideScreen()),
        ),
      },
      {
        'icon': Icons.info_outline,
        'title': 'Về chúng tôi',
        'subtitle': 'Giới thiệu dự án B4E',
        'color': Colors.blue,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        ),
      },
      // Ẩn "Chat với hệ thống" nếu user là admin (admin quản lý chat từ màn hình riêng)
      if (!isAdmin)
        {
          'icon': Icons.chat_bubble_outline,
          'title': 'Chat với hệ thống',
          'subtitle': 'Hỏi đáp, hỗ trợ mượn trả sách',
          'color': const Color(0xFF1565C0),
          'onTap': () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          ),
        },
      {
        'icon': Icons.help_outline,
        'title': 'Hỗ trợ & Góp ý',
        'subtitle': 'Liên hệ đội ngũ phát triển',
        'color': Colors.green,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SupportScreen()),
        ),
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'title': 'Chính sách bảo mật',
        'subtitle': 'Điều khoản và quy định',
        'color': Colors.orange,
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
        ),
      },
      {
        'icon': Icons.palette_outlined,
        'title': 'Giao diện',
        'subtitle': context.watch<ThemeProvider>().isDarkMode 
            ? 'Chế độ tối' 
            : context.watch<ThemeProvider>().isSystemMode 
                ? 'Theo hệ thống' 
                : 'Chế độ sáng',
        'color': Colors.purple,
        'onTap': () => showDialog(
          context: context,
          builder: (_) => const ThemePickerDialog(),
        ),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: context.isDarkMode
            ? Border.all(color: context.divider, width: 0.5)
            : null,
        boxShadow: context.isDarkMode ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.vertical(
                    top: i == 0 ? const Radius.circular(16) : Radius.zero,
                    bottom: i == items.length - 1
                        ? const Radius.circular(16)
                        : Radius.zero,
                  ),
                  onTap: item['onTap'] as VoidCallback,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 18,
                            color: item['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.textPrimary,
                                ),
                              ),
                              Text(
                                item['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: context.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < items.length - 1)
                Divider(height: 1, indent: 64, color: context.divider),
            ],
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET 5: Nút Đăng xuất
  // ════════════════════════════════════════════════════════════════
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => CustomDialog(
                title: 'Đăng xuất',
                message: 'Bạn có chắc muốn đăng xuất khỏi ứng dụng B4E?',
                icon: Icons.logout_rounded,
                iconColor: Colors.red,
                confirmLabel: 'Đăng xuất',
                confirmColor: Colors.red,
                onConfirm: () => Navigator.pop(ctx, true),
              ),
            );
            if (confirm == true && context.mounted) {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                // Pop tất cả về root → MainWrapper sẽ rebuild MainLayout với tab 0
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.logout, color: Colors.red, size: 20),
          label: const Text(
            'Đăng xuất',
            style: TextStyle(
              color: Colors.red,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
