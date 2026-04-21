import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/search_provider.dart';
import '../../data/models/book_model.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  // Các lựa chọn trạng thái
  static const List<Map<String, String>> _statusOptions = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'available', 'label': 'Có sẵn'},
    {'value': 'borrowed', 'label': 'Đã mượn'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SearchProvider>();
      provider.fetchCategories();
      provider.fetchBooks(page: 1);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Debounce search để tránh gọi API liên tục khi gõ
  void _onSearchInput(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<SearchProvider>().onSearchChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Thanh Search + Dropdown trạng thái ──────────────
            _buildSearchBar(provider),

            // ── 2. Chips chọn thể loại ──────────────────────────────
            _buildCategoryChips(provider),

            // ── 3. Tổng số kết quả ─────────────────────────────────
            if (!provider.isLoading && provider.errorMessage.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 6.0),
                child: Text(
                  'Tìm thấy ${provider.totalItems} cuốn sách',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            // ── 4. Danh sách sách ───────────────────────────────────
            Expanded(child: _buildBookContent(provider)),

            // ── 5. Phân trang ──────────────────────────────────────
            if (!provider.isLoading &&
                provider.errorMessage.isEmpty &&
                provider.totalPages > 1)
              _buildPagination(provider),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────
  // WIDGET 1: Search bar + Status dropdown
  // ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(SearchProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchInput,
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên sách, tác giả...',
                  hintStyle: TextStyle(
                      fontSize: 13, color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search,
                      size: 20, color: Colors.blueAccent),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            context
                                .read<SearchProvider>()
                                .onSearchChanged('');
                          },
                          child: const Icon(Icons.clear,
                              size: 18, color: Colors.grey),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 12),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Status dropdown
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.selectedStatus,
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: Colors.blueAccent),
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500),
                items: _statusOptions.map((opt) {
                  return DropdownMenuItem(
                    value: opt['value'],
                    child: Text(opt['label']!),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    provider.onStatusChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // WIDGET 2: Category filter chips (horizontal scroll)
  // ────────────────────────────────────────────────────────────────
  Widget _buildCategoryChips(SearchProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 38,
        child: provider.isCategoriesLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Đang tải thể loại...',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              )
            : ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // Chip "Tất cả"
                  _buildCategoryChip(provider, 'Tất cả'),
                  // Chips cho từng thể loại
                  ...provider.categories.map(
                    (cat) => _buildCategoryChip(provider, cat.name),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryChip(SearchProvider provider, String name) {
    final isSelected = provider.selectedCategory == name;
    return GestureDetector(
      onTap: () => provider.onCategorySelected(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey[300]!,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // WIDGET 3: Nội dung chính (Loading / Error / Empty / Grid)
  // ────────────────────────────────────────────────────────────────
  Widget _buildBookContent(SearchProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(
              provider.errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  provider.fetchBooks(page: provider.currentPage),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (provider.books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy sách nào',
              style: TextStyle(
                  fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () {
                _searchController.clear();
                provider.resetFilters();
              },
              child: const Text('Xóa bộ lọc'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.55,
      ),
      itemCount: provider.books.length,
      itemBuilder: (context, index) {
        return _buildBookCard(provider.books[index]);
      },
    );
  }

  // ────────────────────────────────────────────────────────────────
  // WIDGET 4: Thẻ sách (tái sử dụng thiết kế từ HomeScreen)
  // ────────────────────────────────────────────────────────────────
  Widget _buildBookCard(Book book) {
    final bool isAvailable = book.status == 'available';
    final Color statusColor = isAvailable ? Colors.green : Colors.orange;
    final String statusText = isAvailable ? 'Có sẵn' : 'Đã mượn';

    return GestureDetector(
      onTap: () async {
        final didBorrow = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(
              bookId: book.id,
              heroTag: 'search_book_${book.id}',
            ),
          ),
        );
        // Nếu mượn thành công → reload trang hiện tại
        if (didBorrow == true && mounted) {
          context.read<SearchProvider>().fetchBooks(
                page: context.read<SearchProvider>().currentPage);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh bìa
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      book.displayImageUrl,
                      fit: BoxFit.cover,
                      headers: kIsWeb
                          ? const {'ngrok-skip-browser-warning': 'true'}
                          : const {},
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image,
                            size: 50, color: Colors.grey),
                      ),
                    ),
                    // Badge trạng thái
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Thông tin sách
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
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
                          fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      book.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
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

  // ────────────────────────────────────────────────────────────────
  // WIDGET 5: Thanh phân trang
  // ────────────────────────────────────────────────────────────────
  Widget _buildPagination(SearchProvider provider) {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nút "Trước"
          _buildPageButton(
            icon: Icons.chevron_left,
            onTap: provider.currentPage > 1
                ? () => provider.onPageChanged(provider.currentPage - 1)
                : null,
            enabled: provider.currentPage > 1,
          ),

          const SizedBox(width: 8),

          // Các nút số trang (hiển thị thông minh: ... nếu nhiều trang)
          ..._buildPageNumbers(provider),

          const SizedBox(width: 8),

          // Nút "Sau"
          _buildPageButton(
            icon: Icons.chevron_right,
            onTap: provider.currentPage < provider.totalPages
                ? () => provider.onPageChanged(provider.currentPage + 1)
                : null,
            enabled: provider.currentPage < provider.totalPages,
          ),
        ],
      ),
    );
  }

  // Tạo danh sách nút số trang thông minh (hiện "..." khi nhiều trang)
  List<Widget> _buildPageNumbers(SearchProvider provider) {
    final int total = provider.totalPages;
    final int current = provider.currentPage;
    final List<Widget> widgets = [];
    final Set<int> pagesToShow = {};

    // Luôn hiện trang 1, trang cuối, trang hiện tại và 1 trang kề
    pagesToShow.add(1);
    pagesToShow.add(total);
    for (int i = current - 1; i <= current + 1; i++) {
      if (i >= 1 && i <= total) pagesToShow.add(i);
    }

    final List<int> sortedPages = pagesToShow.toList()..sort();

    int? prev;
    for (final page in sortedPages) {
      if (prev != null && page - prev > 1) {
        // Thêm dấu "..."
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.grey)),
          ),
        );
      }
      widgets.add(_buildNumberButton(page, current, provider));
      prev = page;
    }

    return widgets;
  }

  Widget _buildNumberButton(
      int page, int current, SearchProvider provider) {
    final bool isActive = page == current;
    return GestureDetector(
      onTap: isActive ? null : () => provider.onPageChanged(page),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isActive ? Colors.blueAccent : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? Colors.blueAccent : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey[400],
          size: 22,
        ),
      ),
    );
  }
}

