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

  // Mỗi màn hình bọc bởi RepaintBoundary (tránh vẽ lại màn hình ẩn) và
  // SafeArea(bottom: false) cho tab 1-4 (HomeScreen đã có AppBar xử lý).
  // Danh sách static final → tạo một lần duy nhất, không bao giờ rebuild.
  static final List<Widget> _screens = [
    const RepaintBoundary(child: HomeScreen()),
    const RepaintBoundary(child: SafeArea(bottom: false, child: SearchScreen())),
    const RepaintBoundary(child: SafeArea(bottom: false, child: MyBooksScreen())),
    const RepaintBoundary(child: SafeArea(bottom: false, child: DonationScreen())),
    const RepaintBoundary(child: SafeArea(bottom: false, child: ProfileScreen())),
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

    if (status == AuthStatus.authenticated &&
        _lastStatus != AuthStatus.authenticated) {
      // Defer ra sau frame hiện tại để tránh setState-during-build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NotificationProvider>().fetchNotifications();
          context.read<RecommendationProvider>().fetchRecommendations();
          context.read<RecommendationProvider>().fetchPopular();
        }
      });
    }
    if (status == AuthStatus.unauthenticated &&
        _lastStatus == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NotificationProvider>().clear();
          context.read<RecommendationProvider>().clearPersonalized();
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
    // Early-return: không setState nếu nhấn lại tab đang active
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn =
        context.watch<AuthProvider>().status == AuthStatus.authenticated;

    return Scaffold(
      backgroundColor: Colors.grey[50],

      // ── Top App Bar ────────────────────────────────────────────────
      // Chỉ hiển thị AppBar ở tab Trang chủ (tab 0).
      // Dùng conditional null thay vì PreferredSize(Size.zero) để tránh
      // lỗi layout body trên một số phiên bản Flutter.
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
                                    page: const NotificationScreen()),
                              );
                            },
                          ),
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

      // ── Body ───────────────────────────────────────────────────────
      // IndexedStack giữ tất cả màn hình trong bộ nhớ và chỉ hiển thị
      // tab đang active. KHÔNG bọc AnimatedSwitcher bên ngoài — vì
      // ValueKey thay đổi sẽ destroy/recreate toàn bộ widget tree,
      // phá vỡ hoàn toàn mục đích của IndexedStack.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────────
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
