import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import 'register_screen.dart';
import 'main_layout.dart';

class LoginScreen extends StatefulWidget {
  /// Sau login, pop về màn hình gọi (vd: BookDetailScreen).
  /// Ưu tiên cao nhất khi = true.
  final bool popOnSuccess;

  /// Nếu được truyền và [popOnSuccess] = false, sau khi đăng nhập sẽ
  /// pushAndRemoveUntil về MainLayout với tab này.
  final int? returnTabIndex;

  const LoginScreen({
    super.key,
    this.popOnSuccess = false,
    this.returnTabIndex,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());

    if (!mounted) return;

    if (ok) {
      if (widget.popOnSuccess) {
        // Trường hợp gọi từ BookDetail hoặc màn hình cụ thể:
        // chỉ pop về màn hình trước, không xóa stack
        Navigator.pop(context);
      } else if (widget.returnTabIndex != null) {
        // Gọi từ bottom nav guard: về MainLayout đúng tab, xóa stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainLayout(initialIndex: widget.returnTabIndex!),
          ),
          (route) => false,
        );
      } else {
        // Default: về MainLayout tab 0, xóa stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Email hoặc mật khẩu không đúng!')),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── Header gradient ────────────────────────────────
              _buildHeader(),

              // ── Form card ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề form
                      const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chào mừng bạn quay lại thư viện B4E',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 28),

                      // Email
                      _fieldLabel('Email'),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!v.contains('@')) return 'Email không hợp lệ';
                          return null;
                        },
                        decoration: _inputDecoration(
                          hint: 'email@example.com',
                          icon: Icons.email_outlined,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),

                      // Mật khẩu
                      _fieldLabel('Mật khẩu'),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                        decoration: _inputDecoration(
                          hint: 'Nhập mật khẩu...',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 28),

                      // Nút đăng nhập
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            disabledBackgroundColor:
                                const Color(0xFF1E88E5).withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                            shadowColor: const Color(0xFF1565C0)
                                .withValues(alpha: 0.4),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white),
                                )
                              : const Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12),
                            child: Text('hoặc',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400])),
                          ),
                          Expanded(
                              child: Divider(color: Colors.grey[300])),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Nút đăng ký
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RegisterScreen(
                                  returnTabIndex: widget.returnTabIndex,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF1E88E5), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Tạo tài khoản mới',
                            style: TextStyle(
                              color: Color(0xFF1E88E5),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Skip đăng nhập (hiện khi đến từ tab guard hoặc popOnSuccess)
                      if (widget.returnTabIndex != null || widget.popOnSuccess)
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.grey),
                            child: const Text(
                              'Tiếp tục mà không đăng nhập',
                              style: TextStyle(fontSize: 13),
                            ),
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
    );
  }

  // ── Header với gradient + logo ─────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      margin: const EdgeInsets.only(bottom: 28),
      child: Column(
        children: [
          // Logo
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_library_outlined,
                color: Colors.white, size: 38),
          ),
          const SizedBox(height: 12),
          const Text(
            'B4E Library',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Book For Everyone',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
      prefixIcon: Icon(icon, size: 20, color: Colors.grey[500]),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

