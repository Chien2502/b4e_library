import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import 'about_screen.dart';
import 'admin_screen.dart';
import 'borrowing_guide_screen.dart';
import 'support_screen.dart';
import 'privacy_policy_screen.dart';

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
    final user =
        context.read<AuthProvider>().userProfile;
    if (user != null) {
      _usernameCtrl.text = user.username;
      _phoneCtrl.text = user.phone;
      _addressCtrl.text = user.address;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final err =
        await context.read<AuthProvider>().updateProfile(
              username: _usernameCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
            );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      if (err == null) _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(err ?? 'Cập nhật thành công! ✓'),
        backgroundColor:
            err == null ? Colors.green[700] : Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
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
          // Avatar vòng tròn với chữ cái đầu
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      size: 14, color: Colors.grey),
                ),
              ),
            ],
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings_outlined,
                      color: Colors.white, size: 24),
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
                        style: TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white54, size: 16),
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
        color: Colors.white,
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
            padding:
                const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                const Icon(Icons.person_outline,
                    color: Color(0xFF1E88E5), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // Nội dung: chế độ xem hoặc edit
          _isEditing
              ? _buildEditForm()
              : _buildViewMode(user),
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
          _buildInfoRow(Icons.person_outline, 'Tên đăng nhập',
              user.username),
          _buildInfoRow(
              Icons.email_outlined, 'Email', user.email),
          _buildInfoRow(Icons.phone_outlined, 'Điện thoại',
              user.phone.isNotEmpty ? user.phone : '—'),
          _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ',
              user.address.isNotEmpty ? user.address : '—',
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isLast = false}) {
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
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[600])),
              ),
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
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
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập tên'
                  : null,
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
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu thay đổi',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
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
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFF1E88E5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // WIDGET 4: Quick Menu (Về chúng tôi, Cài đặt,...)
  // ════════════════════════════════════════════════════════════════
  Widget _buildQuickMenu(BuildContext context) {
    final items = [
      {
        'icon': Icons.menu_book_outlined,
        'title': 'Hướng dẫn mượn sách',
        'subtitle': 'Cách mượn, trả và quy định',
        'color': Colors.teal,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BorrowingGuideScreen())),
      },
      {
        'icon': Icons.info_outline,
        'title': 'Về chúng tôi',
        'subtitle': 'Giới thiệu dự án B4E',
        'color': Colors.blue,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AboutScreen())),
      },
      {
        'icon': Icons.help_outline,
        'title': 'Hỗ trợ & Góp ý',
        'subtitle': 'Liên hệ đội ngũ phát triển',
        'color': Colors.green,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SupportScreen())),
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'title': 'Chính sách bảo mật',
        'subtitle': 'Điều khoản và quy định',
        'color': Colors.orange,
        'onTap': () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.vertical(
                    top: i == 0
                        ? const Radius.circular(16)
                        : Radius.zero,
                    bottom: i == items.length - 1
                        ? const Radius.circular(16)
                        : Radius.zero,
                  ),
                  onTap: item['onTap'] as VoidCallback,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: (item['color'] as Color)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item['icon'] as IconData,
                              size: 18,
                              color: item['color'] as Color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(item['title'] as String,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87)),
                              Text(item['subtitle'] as String,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.grey, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(
                    height: 1,
                    indent: 64,
                    color: Color(0xFFF0F0F0)),
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
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Đăng xuất'),
                content: const Text('Bạn có chắc muốn đăng xuất?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Hủy',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              context.read<AuthProvider>().logout();
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.logout, color: Colors.red, size: 20),
          label: const Text('Đăng xuất',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

