import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/database/database_service.dart';
import 'core/database/static_content_seeder.dart';
import 'core/services/push_notification_service.dart';
import 'core/network/connectivity_service.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'views/screens/main_layout.dart';
/// MainWrapper quản lý toàn bộ luồng khởi động:
///
/// Frame 1 → Splash render ngay (gradient + logo + dots animation)
/// initState → chạy tất cả init song song (Firebase, auth, FCM, SQLite)
/// Khi tất cả xong → cross-fade sang MainLayout
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper>
    with SingleTickerProviderStateMixin {
  // Thời gian tối thiểu splash hiển thị để animation logo hoàn tất
  static const int _minSplashMs = 1600;

  late final AnimationController _transitionCtrl;
  late final Animation<double> _fadeOut; // splash fade ra
  late final Animation<double> _fadeIn; // main layout fade vào

  bool _initDone = false; // tất cả init xong chưa
  bool _minTimeDone = false; // thời gian tối thiểu đã đủ chưa
  bool _transitioning = false; // đang fade transition
  bool _transitionDone = false; // transition hoàn tất → remove splash khỏi tree

  @override
  void initState() {
    super.initState();

    // ── Transition animation controller ─────────────────────────────
    _transitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeOut = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeIn));
    _fadeIn = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeOut));

    // Khi animation xong → đánh dấu để xoá splash khỏi widget tree
    // (tránh splash ẩn vẫn block touch events)
    _transitionCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _transitionDone = true);
      }
    });

    // ── Thời gian tối thiểu (chạy song song với init) ────────────────
    Future.delayed(const Duration(milliseconds: _minSplashMs), () {
      if (mounted) {
        _minTimeDone = true;
        _tryTransition();
      }
    });

    // ── Toàn bộ init chạy sau frame đầu tiên ────────────────────────
    // addPostFrameCallback đảm bảo splash đã được render rồi mới bắt đầu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runAllInit();
    });
  }

  /// Chạy toàn bộ init song song, không block UI thread.
  Future<void> _runAllInit() async {
    try {
      debugPrint('[Splash] Step 1: Loading .env and checking connectivity...');
      // Load .env với timeout 3s để tránh kẹt nếu file không tồn tại hoặc lỗi đọc file
      try {
        await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('[Splash] .env load error or timeout: $e');
      }

      // Kiểm tra mạng TRƯỚC TIÊN — kết quả này quyết định các bước sau
      // Thêm timeout cho checkStatus để tránh kẹt ở tầng plugin native
      bool isOnline = true;
      try {
        isOnline = await ConnectivityService().checkStatus().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('[Splash] Connectivity check timeout, assuming online: $e');
      }
      
      ConnectivityService().initialize(); // bắt đầu lắng nghe thay đổi mạng
      debugPrint('[Splash] Connectivity: ${isOnline ? "ONLINE" : "OFFLINE"}');

      // Bước 1: Firebase & SQLite
      debugPrint('[Splash] Step 1: Starting Firebase and SQLite init...');
      Future<void> firebaseInit() async {
        try {
          await Firebase.initializeApp(
                  options: DefaultFirebaseOptions.currentPlatform)
              .timeout(const Duration(seconds: 8));
          debugPrint('[Splash] Firebase initialized');
        } catch (e) {
          debugPrint('[Splash] Firebase init error or timeout: $e — continuing anyway');
        }
      }

      await Future.wait([
        firebaseInit(),
        DatabaseService.instance
            .init()
            .timeout(const Duration(seconds: 5))
            .then((_) => debugPrint('[Splash] Database initialized'))
            .catchError((e) => debugPrint('[Splash] Database init error: $e')),
      ]);
      debugPrint('[Splash] Step 1 completed.');

      // FCM chỉ khởi động khi online
      if (isOnline) {
        PushNotificationService().init().catchError((e) {
          debugPrint('[FCM] Init error: $e');
        });
      }

      debugPrint('[Splash] Step 2: Auth check and seeder...');
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await Future.wait([
        // Auth: đọc token → load cache → chỉ gọi server nếu online
        auth.checkAuthStatus().timeout(const Duration(seconds: 10)).then((_) => debugPrint('[Splash] Auth check completed')),
        // Seed dữ liệu tĩnh (chỉ đọc từ assets → luôn ok kể cả offline)
        StaticContentSeeder.seed().timeout(const Duration(seconds: 5)).then((_) => debugPrint('[Splash] StaticContentSeeder completed')),
      ]);
      debugPrint('[Splash] Step 2 completed.');

    } catch (e) {
      debugPrint('[MainWrapper] Init error (non-fatal): $e');
      if (mounted) {
        final auth = context.read<AuthProvider>();
        if (auth.status == AuthStatus.uninitialized) {
          auth.forceUnauthenticated();
        }
      }
    } finally {
      if (mounted) {
        debugPrint('[Splash] Setting _initDone = true');
        setState(() {
          _initDone = true;
        });
        _tryTransition();
      }
    }
  }

  /// Bắt đầu transition chỉ khi CẢ HAI điều kiện thoả:
  /// init xong VÀ đã hiển thị tối thiểu _minSplashMs ms
  void _tryTransition() {
    debugPrint('[Splash] _tryTransition: _initDone=$_initDone, _minTimeDone=$_minTimeDone, _transitioning=$_transitioning, mounted=$mounted');
    if (_initDone && _minTimeDone && !_transitioning && mounted) {
      debugPrint('[Splash] Transitioning to MainLayout...');
      setState(() {
        _transitioning = true;
      });
      _transitionCtrl.forward();
    }
  }

  @override
  void dispose() {
    _transitionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Transition hoàn tất: chỉ hiện MainLayout, splash đã bị xoá khỏi tree ──
    // Quan trọng: splash phải được remove để không block touch events.
    if (_transitionDone) {
      return const MainLayout();
    }

    // Một Scaffold duy nhất bao toàn bộ — tránh bug "2 Scaffold trong Stack
    // chia đôi màn hình" vì Flutter không overlay 2 Scaffold đúng cách.
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── MainLayout ở dưới (build sẵn trong khi transition) ───
          if (_transitioning)
            FadeTransition(opacity: _fadeIn, child: const MainLayout())
          else
            const SizedBox.shrink(),

          // ── Splash ở trên, fade ra khi transition bắt đầu ────────
          if (_transitioning)
            FadeTransition(opacity: _fadeOut, child: const _SplashContent())
          else
            const _SplashContent(),
        ],
      ),
    );
  }
}

// ── Splash Content (không có Scaffold — Scaffold do parent cung cấp) ──────────

class _SplashContent extends StatefulWidget {
  const _SplashContent();

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;
  late final Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final logoInterval = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );
    final dotsInterval = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(logoInterval);
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(logoInterval);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(logoInterval);
    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(dotsInterval);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Container lấp đầy toàn bộ không gian được cấp (StackFit.expand từ parent)
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // ── Logo + tên app ──────────────────────────────────────
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ScaleTransition(
                    scale: _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.local_library_rounded,
                            color: Colors.white,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'B4E Library',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thư viện sách miễn phí',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),

            // ── Loading dots ────────────────────────────────────────
            AnimatedBuilder(
              animation: _dotsFade,
              builder: (context, _) => Opacity(
                opacity: _dotsFade.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BouncingDots(),
                    const SizedBox(height: 12),
                    // Text(
                    //   'Đang khởi động...',
                    //   style: TextStyle(
                    //     color: Colors.white.withValues(alpha: 0.6),
                    //     fontSize: 12,
                    //     letterSpacing: 0.5,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

/// 3 chấm nảy lần lượt — animation độc lập, luôn chạy mượt
class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Mỗi chấm trễ 0.25s so với chấm trước
            final phase = i * 0.25;
            final t = ((_ctrl.value - phase + 1.0) % 1.0);
            // Parabola 0→1→0: nảy lên ở nửa đầu, rơi xuống ở nửa sau
            final bounce = t < 0.5 ? (2 * t) : (2 * (1 - t));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -10 * bounce),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.4 + 0.6 * bounce),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
