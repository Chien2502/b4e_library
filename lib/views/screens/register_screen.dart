import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/theme/theme_extensions.dart';

class RegisterScreen extends StatefulWidget {
  /// Truyền xuống từ LoginScreen để sau khi đăng ký xong, pop về Login
  /// và giữ nguyên returnTabIndex.
  final int? returnTabIndex;

  const RegisterScreen({super.key, this.returnTabIndex});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _headerSlide;
  late final Animation<Offset> _formSlide;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final curve = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(curve);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(curve);
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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
      SnackBarUtils.showSuccess(context, 'Đăng ký thành công! Hãy đăng nhập.');
      Navigator.pop(context); // Quay về LoginScreen
    } else {
      SnackBarUtils.showError(context, 'Đăng ký thất bại. Email có thể đã tồn tại!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildHeader(context),
                ),
              ),

              // ── Form ────────────────────────────────────────────
              SlideTransition(
                position: _formSlide,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tạo tài khoản',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gia nhập cộng đồng đọc sách B4E ngay hôm nay',
                            style: TextStyle(
                                fontSize: 13, color: context.textSecondary),
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
                                  color: context.textSecondary,
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
                                  color: context.textSecondary,
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
                                backgroundColor: context.colors.primary,
                                foregroundColor: context.colors.onPrimary,
                                disabledBackgroundColor:
                                    context.colors.primary.withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                                shadowColor: context.colors.primary
                                    .withValues(alpha: 0.4),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: context.colors.onPrimary),
                                    )
                                  : Text(
                                      'Tạo tài khoản',
                                      style: TextStyle(
                                        color: context.colors.onPrimary,
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
                                      fontSize: 13, color: context.textSecondary)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Đăng nhập',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.colors.primary,
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
          Hero(
            tag: 'auth_logo',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_outlined,
                  color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 10),
          Hero(
            tag: 'auth_title',
            child: Material(
              color: Colors.transparent,
              child: const Text(
                'Đăng ký B4E',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Hero(
            tag: 'auth_subtitle',
            child: Material(
              color: Colors.transparent,
              child: const Text(
                'Miễn phí • Nhanh chóng • An toàn',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
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
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textPrimary),
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
      hintStyle: TextStyle(fontSize: 13, color: context.textSecondary),
      prefixIcon: Icon(icon, size: 20, color: context.textSecondary),
      suffixIcon: suffix,
      filled: true,
      fillColor: context.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: context.colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.error, width: 1.5),
      ),
    );
  }
}

