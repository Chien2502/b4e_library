import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_provider.dart';
import 'main_wrapper.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
      ],
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
      home: const MainWrapper(), // Sử dụng Wrapper làm điểm bắt đầu
    );
  }
}
