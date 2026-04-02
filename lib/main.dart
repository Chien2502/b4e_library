import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_provider.dart';
import 'viewmodels/book_provider.dart';
import 'viewmodels/search_provider.dart';
import 'viewmodels/my_books_provider.dart';
import 'main_wrapper.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => MyBooksProvider()),
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
