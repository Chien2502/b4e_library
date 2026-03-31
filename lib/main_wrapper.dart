import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_provider.dart';
import 'views/screens/login_screen.dart';
import 'views/screens/home_screen.dart';

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
      return const HomeScreen(); // Đã đăng nhập
    } else {
      return const LoginScreen(); // Chưa đăng nhập
    }
  }
}
