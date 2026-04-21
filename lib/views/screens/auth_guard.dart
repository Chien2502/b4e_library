import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import 'login_screen.dart';

/// Điều hướng đến LoginScreen, lưu lại [returnTabIndex] để sau khi
/// đăng nhập thành công quay về đúng tab.
///
/// Cách dùng:
/// ```dart
/// AuthGuard.requireLogin(context, returnTabIndex: 2);
/// ```
class AuthGuard {
  AuthGuard._();

  /// Trả về true nếu đã đăng nhập, false nếu đã đẩy màn hình Login.
  static bool requireLogin(
    BuildContext context, {
    required int returnTabIndex,
  }) {
    final auth = context.read<AuthProvider>();
    if (auth.status == AuthStatus.authenticated) return true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(returnTabIndex: returnTabIndex),
      ),
    );
    return false;
  }
}

