import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import 'admin/admin_dashboard_tab.dart';
import 'admin/admin_books_tab.dart';
import 'admin/admin_categories_tab.dart';
import 'admin/admin_borrowings_tab.dart';
import 'admin/admin_donations_tab.dart';
import 'admin/admin_users_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Tổng quan'),
    _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'Sách'),
    _NavItem(Icons.category_outlined, Icons.category, 'Thể loại'),
    _NavItem(Icons.volunteer_activism_outlined, Icons.volunteer_activism, 'Quyên góp'),
    _NavItem(Icons.swap_horiz_outlined, Icons.swap_horiz, 'Mượn/Trả'),
    _NavItem(Icons.people_outlined, Icons.people, 'Người dùng'),
  ];

  List<Widget> _buildTabs() => [
        AdminDashboardTab(onNavigate: (i) => setState(() => _currentIndex = i)),
        const AdminBooksTab(),
        const AdminCategoriesTab(),
        const AdminDonationsTab(),
        const AdminBorrowingsTab(),
        const AdminUsersTab(),
      ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userProfile;
    final username = user?.username ?? 'Admin';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.local_library, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text(
              'B4E Admin',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 6),
                Text(
                  username,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: _buildTabs(),
      ),
      bottomNavigationBar: _buildMobileBottomNav(),
    );
  }

  // ── Drawer sidebar (như web) ─────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final user = context.watch<AuthProvider>().userProfile;
    final username = user?.username ?? 'Admin';
    final email = user?.email ?? '';

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : 'B4E Admin Panel',
                  style: TextStyle(
                      color: Colors.white.withAlpha(180), fontSize: 12),
                ),
              ],
            ),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = _currentIndex == i;
                return ListTile(
                  leading: Icon(
                    selected ? item.activeIcon : item.icon,
                    color: selected
                        ? const Color(0xFF1565C0)
                        : Colors.grey[600],
                    size: 22,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF1565C0)
                          : Colors.grey[800],
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  selected: selected,
                  selectedTileColor: const Color(0xFF1565C0).withAlpha(15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  horizontalTitleGap: 8,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 2),
                  onTap: () {
                    setState(() => _currentIndex = i);
                    Navigator.pop(context);
                  },
                );
              }),
            ),
          ),

          const Divider(height: 1),

          // Quay về trang chủ
          ListTile(
            leading: const Icon(Icons.home_outlined,
                color: Color(0xFF1565C0), size: 22),
            title: const Text('Trang chủ',
                style: TextStyle(fontSize: 14, color: Color(0xFF1565C0))),
            onTap: () {
              // Đóng drawer rồi pop hết stack về root (MainWrapper)
              Navigator.pop(context);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          ),

          // Đăng xuất
          ListTile(
            leading:
                const Icon(Icons.logout, color: Colors.red, size: 22),
            title: const Text('Đăng xuất',
                style: TextStyle(fontSize: 14, color: Colors.red)),
            onTap: () async {
              // Đóng drawer
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  title: const Text('Đăng xuất'),
                  content: const Text(
                      'Bạn có chắc muốn đăng xuất khỏi tài khoản?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Hủy')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Đăng xuất',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                // Logout → xóa token, notifyListeners
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  // Pop toàn bộ stack về root (MainWrapper)
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              }
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Mobile bottom nav (6 icon nhỏ) ──────────────────────────────
  Widget _buildMobileBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey[500],
        selectedFontSize: 9.5,
        unselectedFontSize: 9.5,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        elevation: 0,
        items: _navItems
            .map((e) => BottomNavigationBarItem(
                  icon: Icon(e.icon, size: 22),
                  activeIcon: Icon(e.activeIcon, size: 22),
                  label: e.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

