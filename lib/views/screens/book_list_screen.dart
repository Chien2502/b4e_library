import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/models/book_model.dart';
import 'book_detail_screen.dart';
import '../widgets/staggered_list_item.dart';
import '../../core/utils/page_transitions.dart';

class BookListScreen extends StatelessWidget {
  final String title;
  final List<Book> books;

  const BookListScreen({
    super.key,
    required this.title,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: books.isEmpty
          ? const Center(child: Text('Không có sách nào.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: books.length,
              itemBuilder: (context, index) {
                return StaggeredListItem(
                  index: index,
                  child: BookListCard(book: books[index]),
                );
              },
            ),
    );
  }
}

class BookListCard extends StatelessWidget {
  final Book book;
  const BookListCard({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final heroTag = 'book_cover_${book.id}';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        FadeSlideRoute(
            page: BookDetailScreen(bookId: book.id, heroTag: heroTag)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover
            Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
                child: SizedBox(
                  height: 110,
                  width: 80,
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
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                          fontSize: 10,
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
              size: 28, color: Colors.grey),
        ),
      );
}
