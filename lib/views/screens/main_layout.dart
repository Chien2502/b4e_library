import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import 'home_screen.dart'; // Nơi chứa giao diện Trang chủ thực sự

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Biến lưu trữ index của tab đang được chọn
  int _currentIndex = 0;

  // Danh sách các màn hình tương ứng với các tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text('Màn hình Tìm kiếm')), // Các màn hình giữ chỗ
    const Center(child: Text('Sách của tôi')),
    const Center(child: Text('Thông báo')),
    Builder(
      builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Hồ sơ cá nhân', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  // Đăng xuất sử dụng AuthProvider
                  context.read<AuthProvider>().logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Đăng xuất'),
              )
            ],
          ),
        );
      }
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Màu nền tổng thể sáng sủa
      // --- THANH ĐIỀU HƯỚNG TRÊN (APP BAR) ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0, // Bỏ bóng đổ để phẳng và hiện đại hơn
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            // TODO: Xử lý mở Drawer (Menu cạnh bên) nếu cần
          },
        ),
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
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.blueAccent, size: 30),
            onPressed: () {
              // Chuyển sang tab Hồ sơ (index 4)
              setState(() {
                _currentIndex = 4;
              });
            },
          ),
          const SizedBox(width: 8), // Khoảng cách nhỏ lề phải
        ],
      ),

      // --- PHẦN THÂN (BODY) ---
      // Dùng IndexedStack để giữ state của các màn hình khi chuyển tab
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // --- THANH ĐIỀU HƯỚNG DƯỚI (BOTTOM NAVIGATION BAR) ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          // Quan trọng: type fixed giúp hiển thị đầy đủ icon và text khi có từ 4 item trở lên
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
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
              icon: Icon(Icons.notifications_none_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Thông báo',
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
