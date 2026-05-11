import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/notification_provider.dart';
import '../../viewmodels/recommendation_provider.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'my_books_screen.dart';
import 'donation_screen.dart';
import 'profile_screen.dart';
import 'auth_guard.dart';
import 'notification_screen.dart';
import '../../core/utils/page_transitions.dart';
import '../widgets/liquid_nav_bar.dart';

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

  // Tự động fetch thông báo khi trạng thái đăng nhập thay đổi
  AuthStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final status = context.read<AuthProvider>().status;

    if (status == AuthStatus.authenticated && _lastStatus != AuthStatus.authenticated) {
      // Defer ra sau frame hiện tại để tránh setState-during-build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NotificationProvider>().fetchNotifications();
          // Fetch recommendations khi đăng nhập
          context.read<RecommendationProvider>().fetchRecommendations();
          context.read<RecommendationProvider>().fetchPopular();
        }
      });
    }
    if (status == AuthStatus.unauthenticated && _lastStatus == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NotificationProvider>().clear();
          // Xóa dữ liệu cá nhân khi đăng xuất
          context.read<RecommendationProvider>().clearPersonalized();
          // Reset về trang chủ sau khi đăng xuất
          setState(() => _currentIndex = 0);
        }
      });
    }
    // Khi lần đầu khởi động (cả khách) cũng fetch popular
    if (_lastStatus == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<RecommendationProvider>().fetchPopular();
      });
    }
    _lastStatus = status;
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

      // ── Top App Bar (chỉ hiển thị ở Trang chủ) ──────────────────
      appBar: _currentIndex == 0
          ? AppBar(
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
                // Nút chuông thông báo (chỉ hiện khi đã đăng nhập)
                if (isLoggedIn)
                  Consumer<NotificationProvider>(
                    builder: (ctx, notifProv, _) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_outlined,
                              color: Colors.black87,
                              size: 28,
                            ),
                            onPressed: () {
                              Navigator.push(
                                ctx,
                                FadeSlideRoute(
                                  page: const NotificationScreen(),
                                ),
                              );
                            },
                          ),
                          // Badge đỏ chỉ hiện khi có thông báo chưa đọc
                          if (notifProv.hasUnread)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(
                                    minWidth: 16, minHeight: 16),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  notifProv.unreadCount > 99
                                      ? '99+'
                                      : '${notifProv.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                const SizedBox(width: 4),
              ],
            )
          : null,

      // ── Body ─────────────────────────────────────────────────────
      // Khi không có AppBar (tab != 0), bọc SafeArea để tránh bị
      // che bởi status bar của hệ thống.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _currentIndex == 0
              ? IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                )
              : SafeArea(
                  bottom: false,
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
        ),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────
      bottomNavigationBar: LiquidNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          LiquidNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Trang chủ',
          ),
          LiquidNavItem(
            icon: Icons.search_outlined,
            activeIcon: Icons.search,
            label: 'Tìm kiếm',
          ),
          LiquidNavItem(
            icon: Icons.library_books_outlined,
            activeIcon: Icons.library_books,
            label: 'Sách của tôi',
          ),
          LiquidNavItem(
            icon: Icons.volunteer_activism_outlined,
            activeIcon: Icons.volunteer_activism,
            label: 'Quyên góp',
          ),
          LiquidNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

