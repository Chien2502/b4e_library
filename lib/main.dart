import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_provider.dart';
import 'viewmodels/book_provider.dart';
import 'viewmodels/search_provider.dart';
import 'viewmodels/my_books_provider.dart';
import 'viewmodels/notification_provider.dart';
import 'viewmodels/recommendation_provider.dart';
import 'viewmodels/admin_data_provider.dart';
import 'main_wrapper.dart';

/// main() chỉ làm 2 việc: bind Flutter và gọi runApp ngay lập tức.
/// Mọi async init (Firebase, FCM, SQLite, auth check) đều chuyển vào
/// MainWrapper.initState() để splash screen có thể render ngay frame đầu.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => MyBooksProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        // AdminDataProvider sống ở cấp app → cache tồn tại suốt session
        // dù AdminScreen bị push/pop nhiều lần
        ChangeNotifierProvider(create: (_) => AdminDataProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'B4E Library',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        splashFactory: InkRipple.splashFactory,
      ),
      home: const MainWrapper(),
    );
  }
}
