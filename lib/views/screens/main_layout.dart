import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'my_books_screen.dart';
import 'donation_screen.dart';
import 'profile_screen.dart';
import 'auth_guard.dart';

class MainLayout extends StatefulWidget {
  /// Nếu được truyền vào (từ LoginScreen sau đăng nhập), tự động chuyển tab.
  final int initialIndex;
  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int _currentIndex;

  // Tab nào yêu cầu đăng nhập:  2 = Sách của tôi, 3 = Quyên góp, 4 = Hồ sơ
  static const _protectedTabs = {2, 3, 4};

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    MyBooksScreen(),
    DonationScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    // Nếu tab yêu cầu auth, kiểm tra trước
    if (_protectedTabs.contains(index)) {
      final guard = AuthGuard.requireLogin(context, returnTabIndex: index);
      if (!guard) return; // đã push LoginScreen, không chuyển tab
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn =
        context.watch<AuthProvider>().status == AuthStatus.authenticated;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      // ── Top App Bar ──────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Thư viện B4E',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // Thông báo (chỉ hiện khi đã đăng nhập)
          if (isLoggedIn)
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.black87,
                    size: 28,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chưa có thông báo mới.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Tìm kiếm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'Sách của tôi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism_outlined),
              activeIcon: Icon(Icons.volunteer_activism),
              label: 'Quyên góp',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ',
            ),
          ],
        ),
      ),
    );
  }
}

