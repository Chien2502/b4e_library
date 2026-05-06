import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_service.dart';
import 'core/database/static_content_seeder.dart';
import 'viewmodels/auth_provider.dart';
import 'viewmodels/book_provider.dart';
import 'viewmodels/search_provider.dart';
import 'viewmodels/my_books_provider.dart';
import 'viewmodels/notification_provider.dart';
import 'viewmodels/recommendation_provider.dart';
import 'main_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo SQLite local cache
  await DatabaseService.instance.init();
  await StaticContentSeeder.seed();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => MyBooksProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'B4E Library',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainWrapper(), // Sử dụng Wrapper làm điểm bắt đầu
    );
  }
}
