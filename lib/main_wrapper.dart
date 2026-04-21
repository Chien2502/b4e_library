import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_provider.dart';
import 'views/screens/main_layout.dart';

/// MainWrapper chỉ còn nhiệm vụ hiển thị splash khi chưa kiểm tra xong auth.
/// Sau khi auth được kiểm tra, luôn vào MainLayout – không bắt login ngay.
class MainWrapper extends StatelessWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    if (status == AuthStatus.uninitialized) {
      return const _SplashScreen();
    }
    return const MainLayout();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_library_outlined,
                  color: Colors.white, size: 64),
              SizedBox(height: 16),
              Text(
                'B4E Library',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

