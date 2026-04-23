import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/book_provider.dart';
import '../../viewmodels/recommendation_provider.dart';
import '../../data/models/book_model.dart';
import 'book_detail_screen.dart';

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
              bookProvider.fetchLatestBooks(),
              recProvider.fetchPopular(),
              if (isLoggedIn) recProvider.fetchRecommendations(),
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
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: books.length,
            itemBuilder: (context, i) =>
                _BookCard(book: books[i]),
          ),
        ),
      ),
    ];
  }
}

// ════════════════════════════════════════════════════════════════
// Book Card — hiển thị trong horizontal scroll
// ════════════════════════════════════════════════════════════════
class _BookCard extends StatelessWidget {
  final Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BookDetailScreen(bookId: book.id)),
      ),
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover ────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: book.displayImageUrl.isNotEmpty
                    ? Image.network(
                        book.displayImageUrl,
                        fit: BoxFit.cover,
                        headers: kIsWeb
                            ? const {
                                'ngrok-skip-browser-warning': 'true'
                              }
                            : const {},
                        errorBuilder: (context, error, stack) =>
                            _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            // ── Info ─────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[500]),
                    ),
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: book.status == 'available'
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.status == 'available'
                            ? 'Còn sách'
                            : 'Đang mượn',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: book.status == 'available'
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.menu_book_outlined,
              size: 36, color: Colors.grey),
        ),
      );
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
      child: Row(
        children: List.generate(
          3,
          (_) => Container(
            width: 130,
            height: 185,
            margin: const EdgeInsets.only(right: 10),
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
