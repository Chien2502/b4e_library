import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_provider.dart';
import 'views/screens/login_screen.dart';

void main() {
  runApp(
    // Đăng ký Provider ở đây
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'B4E Library',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(), // Đặt màn hình khởi chạy là Login
    );
  }
}
