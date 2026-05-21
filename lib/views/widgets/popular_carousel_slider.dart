import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/page_transitions.dart';
import '../../data/models/book_model.dart';
import '../screens/book_detail_screen.dart';

class PopularCarouselSlider extends StatefulWidget {
  final List<Book> books;
  const PopularCarouselSlider({super.key, required this.books});

  @override
  State<PopularCarouselSlider> createState() => _PopularCarouselSliderState();
}

class _PopularCarouselSliderState extends State<PopularCarouselSlider> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _timer;
  bool _isUserInteracting = false;

  @override
  void initState() {
    super.initState();
    // Bắt đầu từ trang 0.
    // Dùng PageController với viewportFraction 0.92 để hé lộ một phần của trang trước/sau (giống waka.vn)
    _pageController = PageController(initialPage: 0, viewportFraction: 0.9);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _isUserInteracting || widget.books.isEmpty) return;
      
      final nextIndex = (_currentIndex + 1) % widget.books.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mục nổi bật
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sách phổ biến nhất',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              // Nút xem tất cả
              Icon(Icons.chevron_right, color: Colors.orange[700], size: 20),
            ],
          ),
        ),

        // Slider
        SizedBox(
          height: 180,
          child: GestureDetector(
            onPanDown: (_) => setState(() => _isUserInteracting = true),
            onPanCancel: () {
              setState(() => _isUserInteracting = false);
              _startAutoPlay();
            },
            onPanEnd: (_) {
              setState(() => _isUserInteracting = false);
              _startAutoPlay();
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.books.length,
              itemBuilder: (context, index) {
                final book = widget.books[index];
                return _buildCarouselCard(context, book, index);
              },
            ),
          ),
        ),

        // Indicator dots
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.books.length > 8 ? 8 : widget.books.length, // Giới hạn tối đa 8 chấm cho đẹp
            (index) => _buildIndicator(index),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(int index) {
    // Nếu quá 8 phần tử, gom bớt
    final isSelected = _currentIndex % (widget.books.length > 8 ? 8 : widget.books.length) == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isSelected ? 18 : 6,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.orange[700]
            : (context.isDarkMode ? Colors.grey[700] : Colors.grey[300]),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildCarouselCard(BuildContext context, Book book, int index) {
    final heroTag = 'popular_slider_cover_${book.id}_$index';
    
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.08)).clamp(0.0, 1.0);
        }
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          FadeSlideRoute(
            page: BookDetailScreen(bookId: book.id, heroTag: heroTag),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDarkMode ? 0.4 : 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 1. Background image (Blurred book cover)
              Positioned.fill(
                child: book.displayImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: book.displayImageUrl,
                        fit: BoxFit.cover,
                        httpHeaders: kIsWeb ? const {'ngrok-skip-browser-warning': 'true'} : const {},
                        errorWidget: (c, u, e) => Container(color: Colors.grey[900]),
                      )
                    : Container(color: Colors.grey[900]),
              ),
              
              // Blur filter
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: Colors.black.withValues(alpha: context.isDarkMode ? 0.65 : 0.45),
                  ),
                ),
              ),

              // Decorative ambient glow based on brand color
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange[700]!.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // 2. Card Content Layout
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Left Side: Text and CTA
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Popular Rank Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange[800]!, Colors.amber[700]!],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.white, size: 10),
                                const SizedBox(width: 3),
                                Text(
                                  'TOP ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Book Title
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Author Name
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Action CTA Button
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange[700],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange[700]!.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Đọc Ngay',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Right Side: 3D Elevated Book Cover
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 10,
                                offset: const Offset(3, 5),
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: heroTag,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AspectRatio(
                                aspectRatio: 2 / 3,
                                child: book.displayImageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: book.displayImageUrl,
                                        fit: BoxFit.cover,
                                        httpHeaders: kIsWeb ? const {'ngrok-skip-browser-warning': 'true'} : const {},
                                        placeholder: (context, url) => _placeholder(),
                                        errorWidget: (context, url, error) => _placeholder(),
                                      )
                                    : _placeholder(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(Icons.menu_book_outlined, size: 24, color: Colors.white54),
      ),
    );
  }
}
