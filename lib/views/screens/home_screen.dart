import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/book_provider.dart';
import '../../data/models/book_model.dart';

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
      Provider.of<BookProvider>(context, listen: false).fetchLatestBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        // --- Trạng thái 1: Đang tải ---
        if (bookProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // --- Trạng thái 2: Lỗi ---
        if (bookProvider.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 8),
                Text(
                  bookProvider.errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => bookProvider.fetchLatestBooks(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        // --- Trạng thái 3: Không có sách ---
        if (bookProvider.books.isEmpty) {
          return const Center(
            child: Text('Chưa có sách nào trong thư viện.'),
          );
        }

        // --- Trạng thái 4: Hiển thị theo thể loại ---
        final categoryMap = bookProvider.booksByCategory;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 24),
          itemCount: categoryMap.length,
          itemBuilder: (context, index) {
            final category = categoryMap.keys.elementAt(index);
            final booksInCategory = categoryMap[category]!;
            return _buildCategorySection(category, booksInCategory);
          },
        );
      },
    );
  }

  // ----------------------------------------------------------------
  // SECTION: Tiêu đề thể loại + danh sách sách cuộn ngang
  // ----------------------------------------------------------------
  Widget _buildCategorySection(String category, List<Book> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header thể loại ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${books.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Điều hướng đến trang xem tất cả sách của thể loại này
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Danh sách sách cuộn ngang ---
        SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 8),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return _buildHorizontalBookCard(books[index]);
            },
          ),
        ),

        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 0.5, indent: 16, endIndent: 16),
        const SizedBox(height: 8),
      ],
    );
  }

  // ----------------------------------------------------------------
  // CARD: Thẻ sách theo chiều ngang (dạng compact)
  // ----------------------------------------------------------------
  Widget _buildHorizontalBookCard(Book book) {
    final bool isAvailable = book.status == 'available';
    final Color statusColor = isAvailable ? Colors.green : Colors.orange;
    final String statusText = isAvailable ? 'Có sẵn' : 'Đã mượn';

    return GestureDetector(
      onTap: () {
        // TODO: Xem chi tiết sách
      },
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Ảnh bìa ---
            Expanded(
              flex: 7,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      book.displayImageUrl,
                      fit: BoxFit.cover,
                      headers: kIsWeb
                          ? const {'ngrok-skip-browser-warning': 'true'}
                          : const {},
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image,
                              size: 36, color: Colors.grey),
                        );
                      },
                    ),
                    // Badge trạng thái
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Thông tin sách ---
            Expanded(
              flex: 3,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
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
}
