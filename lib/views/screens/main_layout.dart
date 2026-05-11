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

  // Lazy build: chỉ tạo màn hình khi lần đầu được ghé thăm.
  // Tab 0 (HomeScreen) luôn được tạo sẵn vì là màn hình mặc định.
  final Set<int> _visitedTabs = {0};
  // Cache các widget đã build — mỗi màn hình chỉ được tạo đúng 1 lần.
  final Map<int, Widget> _screenCache = {};

  // Factory cho từng tab — chỉ gọi khi cần
  Widget _getScreen(int index) {
    return _screenCache.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return const RepaintBoundary(child: HomeScreen());
        case 1:
          return const RepaintBoundary(
            child: SafeArea(bottom: false, child: SearchScreen()),
          );
        case 2:
          return const RepaintBoundary(
            child: SafeArea(bottom: false, child: MyBooksScreen()),
          );
        case 3:
          return const RepaintBoundary(
            child: SafeArea(bottom: false, child: DonationScreen()),
          );
        case 4:
        default:
          return const RepaintBoundary(
            child: SafeArea(bottom: false, child: ProfileScreen()),
          );
      }
    });
  }

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
    setState(() {
      _visitedTabs.add(index); // đánh dấu đã visit để lazy-build
      _currentIndex = index;
    });
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

      // ── Body (Lazy IndexedStack) ───────────────────────────────────
      // Chỉ build màn hình khi lần đầu được chọn (_visitedTabs).
      // Màn hình đã build được giữ alive trong stack, giống IndexedStack
      // chuẩn nhưng không build tất cả 5 màn hình ngay lúc khởi động.
      body: Stack(
        children: List.generate(5, (i) {
          final visited = _visitedTabs.contains(i);
          return Offstage(
            offstage: _currentIndex != i,
            child: visited ? _getScreen(i) : const SizedBox.shrink(),
          );
        }),
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
