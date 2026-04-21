import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  /// Truyền xuống từ LoginScreen để sau khi đăng ký xong, pop về Login
  /// và giữ nguyên returnTabIndex.
  final int? returnTabIndex;

  const RegisterScreen({super.key, this.returnTabIndex});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok =
        await auth.register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text.trim());

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Đăng ký thành công! Hãy đăng nhập.'),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
      Navigator.pop(context); // Quay về LoginScreen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Đăng ký thất bại. Email có thể đã tồn tại!')),
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
              // ── Header ──────────────────────────────────────────
              _buildHeader(context),

              // ── Form ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tạo tài khoản',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gia nhập cộng đồng đọc sách B4E ngay hôm nay',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),

                      // Họ tên
                      _fieldLabel('Họ và tên'),
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập họ tên'
                            : null,
                        decoration: _inputDecoration(
                          hint: 'Nguyễn Văn A...',
                          icon: Icons.person_outline,
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 14),

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
                      const SizedBox(height: 14),

                      // Mật khẩu
                      _fieldLabel('Mật khẩu'),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          if (v.length < 6) {
                            return 'Mật khẩu tối thiểu 6 ký tự';
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hint: 'Tối thiểu 6 ký tự...',
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
                      const SizedBox(height: 14),

                      // Xác nhận mật khẩu
                      _fieldLabel('Xác nhận mật khẩu'),
                      TextFormField(
                        controller: _confirmPassCtrl,
                        obscureText: _obscureConfirm,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu';
                          }
                          if (v != _passCtrl.text) {
                            return 'Mật khẩu không khớp';
                          }
                          return null;
                        },
                        decoration: _inputDecoration(
                          hint: 'Nhập lại mật khẩu...',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 28),

                      // Nút tạo tài khoản
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleRegister,
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
                                  'Tạo tài khoản',
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

                      // Đã có tài khoản
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Đã có tài khoản? ',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600])),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1E88E5),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildHeader(BuildContext context) {
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add_outlined,
                color: Colors.white, size: 32),
          ),
          const SizedBox(height: 10),
          const Text(
            'Đăng ký B4E',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Miễn phí • Nhanh chóng • An toàn',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

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

