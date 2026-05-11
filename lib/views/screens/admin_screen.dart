import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import 'admin/admin_dashboard_tab.dart';
import 'admin/admin_books_tab.dart';
import 'admin/admin_categories_tab.dart';
import 'admin/admin_borrowings_tab.dart';
import 'admin/admin_donations_tab.dart';
import 'admin/admin_users_tab.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/liquid_nav_bar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0;

  // Lazy build: chỉ tạo tab khi lần đầu được visit
  final Set<int> _visitedTabs = {0};
  final Map<int, Widget> _tabCache = {};

  static const List<LiquidNavItem> _navItems = [
    LiquidNavItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Tổng quan',
    ),
    LiquidNavItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Sách',
    ),
    LiquidNavItem(
      icon: Icons.category_outlined,
      activeIcon: Icons.category,
      label: 'Thể loại',
    ),
    LiquidNavItem(
      icon: Icons.volunteer_activism_outlined,
      activeIcon: Icons.volunteer_activism,
      label: 'Quyên góp',
    ),
    LiquidNavItem(
      icon: Icons.swap_horiz_outlined,
      activeIcon: Icons.swap_horiz,
      label: 'Mượn/Trả',
    ),
    LiquidNavItem(
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      label: 'Người dùng',
    ),
  ];

  Widget _getTab(int index) {
    return _tabCache.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return AdminDashboardTab(
            onNavigate: (i) => setState(() {
              _visitedTabs.add(i);
              _currentIndex = i;
            }),
          );
        case 1:
          return const AdminBooksTab();
        case 2:
          return const AdminCategoriesTab();
        case 3:
          return const AdminDonationsTab();
        case 4:
          return const AdminBorrowingsTab();
        case 5:
        default:
          return const AdminUsersTab();
      }
    });
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _visitedTabs.add(index);
      _currentIndex = index;
    });
  }

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
        title: const Row(
          children: [
            Icon(Icons.local_library, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
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
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white24,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl != null
                      ? null
                      : Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

      // ── Body: Lazy Offstage stack (giống main_layout) ──────────────
      body: Stack(
        children: List.generate(6, (i) {
          return Offstage(
            offstage: _currentIndex != i,
            child: _visitedTabs.contains(i)
                ? _getTab(i)
                : const SizedBox.shrink(),
          );
        }),
      ),

      // ── Bottom nav: LiquidNavBar ───────────────────────────────────
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: _navItems,
      ),
    );
  }

  // ── Drawer sidebar ───────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context) {
    final user = context.watch<AuthProvider>().userProfile;
    final username = user?.username ?? 'Admin';
    final email = user?.email ?? '';

    return Drawer(
      child: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl != null
                        ? null
                        : const Icon(Icons.admin_panel_settings,
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
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  selected: selected,
                  selectedTileColor:
                      const Color(0xFF1565C0).withAlpha(15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  horizontalTitleGap: 8,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 2),
                  onTap: () {
                    _onTabTapped(i);
                    Navigator.pop(context);
                  },
                );
              }),
            ),
          ),

          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                // Quay về trang chủ
                ListTile(
                  leading: const Icon(Icons.home_outlined,
                      color: Color(0xFF1565C0), size: 22),
                  title: const Text('Trang chủ',
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF1565C0))),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 2),
                ),
                // Đăng xuất
                ListTile(
                  leading: const Icon(Icons.logout,
                      color: Colors.red, size: 22),
                  title: const Text('Đăng xuất',
                      style:
                          TextStyle(fontSize: 14, color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => CustomDialog(
                        title: 'Đăng xuất',
                        message:
                            'Bạn có chắc muốn đăng xuất khỏi tài khoản Quản trị?',
                        icon: Icons.admin_panel_settings_rounded,
                        iconColor: Colors.red,
                        confirmLabel: 'Đăng xuất',
                        confirmColor: Colors.red,
                        onConfirm: () => Navigator.pop(ctx, true),
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.popUntil(
                            context, (route) => route.isFirst);
                      }
                    }
                  },
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
