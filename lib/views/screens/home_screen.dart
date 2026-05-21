import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/book_provider.dart';
import '../../viewmodels/recommendation_provider.dart';
import '../../data/models/book_model.dart';
import 'book_list_screen.dart';
import '../widgets/staggered_list_item.dart';
import '../widgets/shimmer_widget.dart';
import '../widgets/popular_carousel_slider.dart';
import '../../core/utils/page_transitions.dart';
import '../../core/theme/theme_extensions.dart';

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
              // ── Section: Mượn nhiều nhất (waka.vn Slider Carousel) ──
              if (recProvider.isPopularLoading)
                const SliverToBoxAdapter(child: _SectionShimmer())
              else if (recProvider.popular.isNotEmpty)
                SliverToBoxAdapter(
                  child: PopularCarouselSlider(books: recProvider.popular),
                ),

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
                  ),
              ],

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
                        style: TextStyle(
                            fontSize: 11, color: context.textSecondary),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    FadeSlideRoute(
                      page: BookListScreen(
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
          (context, i) => StaggeredListItem(
            index: i,
            child: BookListCard(book: displayBooks[i]),
          ),
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
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: BookCardShimmer(),
          ),
        ),
      ),
    );
  }
}
