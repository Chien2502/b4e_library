import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'my_books_screen.dart';
import 'donation_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // ── Index mapping ──────────────────────────
  // 0: Trang chủ
  // 1: Tìm kiếm
  // 2: Sách của tôi
  // 3: Quyên góp
  // 4: Hồ sơ

  final List<Widget> _screens = [
    // 0 — Trang chủ
    const HomeScreen(),

    // 1 — Tìm kiếm
    const SearchScreen(),

    // 2 — Sách của tôi
    const MyBooksScreen(),

    // 3 — Quyên góp
    const DonationScreen(),

    // 4 — Hồ sơ
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],

      // ── Top App Bar ────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Bỏ leading menu (không cần Drawer)
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
          // Icon Thông báo (chuyển sang top bar)
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
                  // TODO: Mở trang thông báo hoặc hiện panel
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chưa có thông báo mới.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              // Badge số thông báo (chưa đọc) — placeholder
              // Uncomment và truyền số thực khi có API thông báo
              // Positioned(
              //   top: 8,
              //   right: 8,
              //   child: Container(
              //     width: 16, height: 16,
              //     decoration: const BoxDecoration(
              //       color: Colors.red,
              //       shape: BoxShape.circle,
              //     ),
              //     child: const Center(
              //       child: Text('3', style: TextStyle(color: Colors.white, fontSize: 9)),
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Body ───────────────────────────────────────────────────
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: const [
            // 0 — Trang chủ
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            // 1 — Tìm kiếm
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Tìm kiếm',
            ),
            // 2 — Sách của tôi
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'Sách của tôi',
            ),
            // 3 — Quyên góp
            BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism_outlined),
              activeIcon: Icon(Icons.volunteer_activism),
              label: 'Quyên góp',
            ),
            // 4 — Hồ sơ
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
