import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_provider.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/main_layout.dart';

class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Kiểm tra trạng thái và trả về màn hình tương ứng
    if (authProvider.status == AuthStatus.uninitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()), // Màn hình chờ
      );
    } else if (authProvider.status == AuthStatus.authenticated) {
      return const MainLayout(); // Đã đăng nhập, vào Main Layout
    } else {
      return const LoginScreen(); // Chưa đăng nhập
    }
  }
}
