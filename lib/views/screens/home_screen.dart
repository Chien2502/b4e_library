import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/book_provider.dart';
import '../../viewmodels/recommendation_provider.dart';
import '../../data/models/book_model.dart';
import 'book_detail_screen.dart';
import 'book_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sách mới nhất (BookProvider)
      Provider.of<BookProvider>(context, listen: false).fetchLatestBooks();
      // Popular đã được fetch trong MainLayout — chỉ fetch nếu rỗng
      final rec = Provider.of<RecommendationProvider>(context, listen: false);
      if (rec.popular.isEmpty) rec.fetchPopular();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.status == AuthStatus.authenticated;
    final userName = auth.userProfile?.username ?? '';

    return Consumer2<BookProvider, RecommendationProvider>(
      builder: (context, bookProvider, recProvider, _) {
        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              bookProvider.fetchLatestBooks(forceRefresh: true),
              recProvider.fetchPopular(forceRefresh: true),
              if (isLoggedIn) recProvider.fetchRecommendations(forceRefresh: true),
            ]);
          },
          child: CustomScrollView(
            slivers: [
              // ── Greeting Banner ─────────────────────────────────
              SliverToBoxAdapter(child: _buildGreeting(isLoggedIn, userName)),

              // ── Section: Gợi ý cho bạn (chỉ khi login) ─────────
              if (isLoggedIn) ...[
                if (recProvider.isRecLoading)
                  const SliverToBoxAdapter(child: _SectionShimmer())
                else if (recProvider.hasHistory)
                  ..._buildSection(
                    context,
                    icon: Icons.auto_awesome,
                    color: Colors.deepPurple,
                    title: 'Gợi ý cho bạn',
                    subtitle: recProvider.result?.subtitle,
                    books: recProvider.recommendations,
                  )
                else
                  SliverToBoxAdapter(child: _buildFirstBorrowBanner()),
              ],

              // ── Section: Mượn nhiều nhất ─────────────────────────
              if (recProvider.isPopularLoading)
                const SliverToBoxAdapter(child: _SectionShimmer())
              else if (recProvider.popular.isNotEmpty)
                ..._buildSection(
                  context,
                  icon: Icons.trending_up,
                  color: Colors.orange[700]!,
                  title: 'Được mượn nhiều nhất',
                  books: recProvider.popular,
                ),

              // ── Section: Mới nhất ───────────────────────────────
              if (bookProvider.isLoading)
                const SliverToBoxAdapter(child: _SectionShimmer())
              else if (bookProvider.books.isNotEmpty)
                ..._buildSection(
                  context,
                  icon: Icons.fiber_new,
                  color: Colors.teal,
                  title: 'Mới thêm vào thư viện',
                  books: bookProvider.books,
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  // ── Greeting ──────────────────────────────────────────────────
  Widget _buildGreeting(bool isLoggedIn, String name) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Chào buổi sáng'
        : hour < 18
            ? 'Chào buổi chiều'
            : 'Chào buổi tối';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_library_outlined,
              color: Colors.white70, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? '$greeting, $name! 👋' : 'Khám phá thư viện',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoggedIn
                      ? 'Hôm nay bạn muốn đọc gì?'
                      : 'Đăng nhập để nhận gợi ý cá nhân hóa',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Banner khi chưa có lịch sử mượn ─────────────────────────
  Widget _buildFirstBorrowBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.deepPurple.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome,
              color: Colors.deepPurple, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mượn sách đầu tiên để nhận gợi ý! 🎯',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chúng tôi sẽ gợi ý sách phù hợp với sở thích của bạn.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Xây dựng sliver section + horizontal list ─────────────────
  List<Widget> _buildSection(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required List<Book> books,
  }) {
    final displayBooks = books.take(3).toList();
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookListScreen(
                        title: title,
                        books: books,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Xem thêm', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => BookListCard(book: displayBooks[i]),
          childCount: displayBooks.length,
        ),
      ),
    ];
  }
}


// ════════════════════════════════════════════════════════════════
// Shimmer placeholder khi đang tải
// ════════════════════════════════════════════════════════════════
class _SectionShimmer extends StatelessWidget {
  const _SectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
