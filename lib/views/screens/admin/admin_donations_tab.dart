import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_error_handler.dart';
import '../../widgets/custom_dialog.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/theme/theme_extensions.dart';


// ── Model ────────────────────────────────────────────────────────────
class AdminDonation {
  final int id;
  final String bookTitle;
  final String bookAuthor;
  final String bookPublisher;
  final String bookYear;
  final String bookCondition;
  final String donationType;
  final String status;
  final String senderName;
  final String senderEmail;
  final String createdAt;

  AdminDonation({
    required this.id,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookPublisher,
    required this.bookYear,
    required this.bookCondition,
    required this.donationType,
    required this.status,
    required this.senderName,
    required this.senderEmail,
    required this.createdAt,
  });

  factory AdminDonation.fromJson(Map<String, dynamic> j) {
    // Hàm helper: chuyển bất kỳ kiểu nào (int, String, null) → String an toàn
    String str(String key, [String fallback = '']) {
      final v = j[key];
      if (v == null) return fallback;
      return v.toString(); // Xử lý cả int (book_year) lẫn String
    }

    return AdminDonation(
      id: int.tryParse(str('id', '0')) ?? 0,        // id INT → parse int
      bookTitle: str('book_title'),
      bookAuthor: str('book_author'),
      bookPublisher: str('book_publisher'),
      bookYear: str('book_year'),                    // INT NULL → '2023' hoặc ''
      bookCondition: str('book_condition'),
      donationType: str('donation_type'),
      status: str('status', 'pending'),
      senderName: str('username', '---'),
      senderEmail: str('email', '---'),
      createdAt: str('created_at'),
    );
  }
}

// ── Widget ───────────────────────────────────────────────────────────
class AdminDonationsTab extends StatefulWidget {
  const AdminDonationsTab({super.key});
  @override
  State<AdminDonationsTab> createState() => _AdminDonationsTabState();
}

class _AdminDonationsTabState extends State<AdminDonationsTab> with SingleTickerProviderStateMixin {
  final _dio = DioClient().dio;
  List<AdminDonation> _items = [];
  bool _loading = true;
  String? _error;
  
  late TabController _tabController;
  String _subFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _subFilter = 'all';
        });
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<(String, String, Color)> _getSubFiltersForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return [
          ('all', 'Tất cả', Colors.blueGrey),
          ('pending', 'Chờ duyệt', Colors.orange),
        ];
      case 1:
        return [
          ('all', 'Tất cả', Colors.blueGrey),
          ('approved', 'Đã duyệt', Colors.indigo),
          ('in_transit', 'Đang ship', Colors.blue),
          ('received', 'Đã nhận', Colors.teal),
        ];
      case 2:
        return [
          ('all', 'Tất cả', Colors.blueGrey),
          ('processed', 'Đã nhập kho', Colors.green),
          ('rejected', 'Từ chối', Colors.red),
        ];
      default:
        return [];
    }
  }

  int _getCountForSubFilter(int tabIndex, String subFilterKey) {
    List<AdminDonation> baseItems = [];
    switch (tabIndex) {
      case 0:
        baseItems = _items.where((e) => e.status == 'pending').toList();
        break;
      case 1:
        baseItems = _items.where((e) {
          final s = e.status;
          return s == 'approved' || s == 'in_transit' || s == 'received';
        }).toList();
        break;
      case 2:
        baseItems = _items.where((e) {
          final s = e.status;
          return s == 'processed' || s == 'rejected';
        }).toList();
        break;
    }
    
    if (subFilterKey == 'all') return baseItems.length;
    return baseItems.where((e) => e.status == subFilterKey).length;
  }

  // ── Load danh sách pending ────────────────────────────────────────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _dio.get(ApiConstants.adminDonations);

      // Backend trả về array thuần [] hoặc có thể là map lỗi
      final raw = res.data;
      List<AdminDonation> list;

      if (raw is List) {
        // ✅ Trường hợp bình thường: PHP trả đúng array
        list = raw
            .whereType<Map<String, dynamic>>()
            .map((e) => AdminDonation.fromJson(e))
            .toList();
      } else if (raw is Map && raw.containsKey('data')) {
        // Trường hợp PHP bọc trong {data: [...]}
        list = (raw['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => AdminDonation.fromJson(e))
            .toList();
      } else if (raw is Map && (raw['error'] == true || raw.containsKey('message'))) {
        // PHP trả về lỗi dạng object
        throw Exception(raw['message'] ?? raw['error'] ?? 'Lỗi server');
      } else {
        list = [];
      }

      setState(() => _items = list);
    } on DioException catch (e) {
      setState(() => _error = NetworkErrorHandler.getFriendlyMessage(e));
    } on TypeError {
      setState(() => _error = 'Lỗi phân tích dữ liệu. Vui lòng thử lại.');
    } catch (e) {
      setState(() => _error = NetworkErrorHandler.getFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Generic status update ─────────────────────────────────────────
  Future<void> _updateStatus(int donationId, String newStatus) async {
    try {
      await _dio.post(
        ApiConstants.adminUpdateDonationStatus,
        data: {'donation_id': donationId, 'status': newStatus},
        options: Options(contentType: Headers.jsonContentType),
      );
      if (!mounted) return;
      _showSnack('✅ Cập nhật thành công!', false);
      _load();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['error'] ??
          NetworkErrorHandler.getFriendlyMessage(e), true);
    }
  }

  Widget _buildDonationActions(AdminDonation d) {
    switch (d.status) {
      case 'pending':
        return Row(children: [
          Expanded(child: _DonBtn(
            label: 'Duyệt', icon: Icons.check, color: Colors.green,
            onTap: () => _confirmAction('Chấp nhận yêu cầu quyên góp "${d.bookTitle}"?',
                () => _updateStatus(d.id, 'approved')),
          )),
          const SizedBox(width: 8),
          Expanded(child: _DonBtn(
            label: 'Từ chối', icon: Icons.close, color: Colors.red,
            onTap: () => _confirmAction('Từ chối yêu cầu này?',
                () => _updateStatus(d.id, 'rejected')),
          )),
        ]);
      case 'approved':
      case 'in_transit':
        return Row(children: [
          Expanded(child: _DonBtn(
            label: 'Đã nhận sách', icon: Icons.inventory_2_outlined, color: Colors.teal,
            onTap: () => _confirmAction('Đã nhận được sách từ người dùng?',
                () => _updateStatus(d.id, 'received')),
          )),
          const SizedBox(width: 8),
          Expanded(child: _DonBtn(
            label: 'Hủy/Không nhận', icon: Icons.close, color: Colors.red,
            onTap: () => _confirmAction('Hủy quyên góp vì không nhận được sách?',
                () => _updateStatus(d.id, 'rejected')),
          )),
        ]);
      case 'received':
        return Row(children: [
          Expanded(child: _DonBtn(
            label: 'Nhập kho', icon: Icons.library_add_outlined, color: Colors.indigo,
            onTap: () => _confirmAction('Đã kiểm tra và đưa sách vào kho thư viện?',
                () => _updateStatus(d.id, 'processed')),
          )),
          const SizedBox(width: 8),
          Expanded(child: _DonBtn(
            label: 'Hư hỏng', icon: Icons.broken_image_outlined, color: Colors.orange,
            onTap: () => _confirmAction('Sách bị hư hỏng, không thể nhập kho?',
                () => _updateStatus(d.id, 'rejected')),
          )),
        ]);
      case 'processed':
        return const Text('✅ Đã nhập kho thành công',
            style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600));
      case 'rejected':
        return const Text('❌ Đã từ chối',
            style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600));
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────

  void _showSnack(String msg, bool isError) {
    if (!mounted) return;
    if (isError) {
      SnackBarUtils.showError(context, msg);
    } else {
      SnackBarUtils.showSuccess(context, msg);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTitleBar(),
        _buildTabBar(),
        _buildFilterChips(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  List<AdminDonation> get _filtered {
    final tabIndex = _tabController.index;
    
    // First, filter by chronological group
    List<AdminDonation> tabItems = [];
    switch (tabIndex) {
      case 0: // Chờ xử lý
        tabItems = _items.where((e) => e.status == 'pending').toList();
        break;
      case 1: // Tiếp nhận
        tabItems = _items.where((e) {
          final s = e.status;
          return s == 'approved' || s == 'in_transit' || s == 'received';
        }).toList();
        break;
      case 2: // Lịch sử
        tabItems = _items.where((e) {
          final s = e.status;
          return s == 'processed' || s == 'rejected';
        }).toList();
        break;
    }

    // Second, apply sub-filter within the tab group
    if (_subFilter == 'all') return tabItems;
    return tabItems.where((e) => e.status == _subFilter).toList();
  }

  Widget _buildTabBar() {
    final pendingCount = _items.where((e) => e.status == 'pending').length;
    final transitCount = _items.where((e) {
      final s = e.status;
      return s == 'approved' || s == 'in_transit' || s == 'received';
    }).length;
    final historyCount = _items.where((e) {
      final s = e.status;
      return s == 'processed' || s == 'rejected';
    }).length;

    return Container(
      color: context.card,
      child: TabBar(
        controller: _tabController,
        labelColor: context.colors.primary,
        unselectedLabelColor: context.textSecondary,
        indicatorColor: context.colors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: context.divider,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Chờ xử lý'),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 4),
                  _buildTabBadge(pendingCount, Colors.orange),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Tiếp nhận'),
                if (transitCount > 0) ...[
                  const SizedBox(width: 4),
                  _buildTabBadge(transitCount, Colors.indigo),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Lịch sử'),
                if (historyCount > 0) ...[
                  const SizedBox(width: 4),
                  _buildTabBadge(historyCount, Colors.green),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final subFilters = _getSubFiltersForTab(_tabController.index);
    if (subFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      color: context.background,
      height: 54,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: subFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = subFilters[index];
          final isSelected = _subFilter == filter.$1;
          final count = _getCountForSubFilter(_tabController.index, filter.$1);
          final themeColor = filter.$3;

          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : context.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.25)
                        : themeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : themeColor,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: context.card,
            selectedColor: themeColor,
            checkmarkColor: Colors.white,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected 
                    ? themeColor
                    : context.divider.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _subFilter = filter.$1;
                });
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildTitleBar() {
    final pending = _items.where((d) => d.status == 'pending').length;
    return Container(
      color: context.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(Icons.volunteer_activism, color: context.colors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quản lý Quyên Góp Sách',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Tổng ${_items.length} đơn quyên góp — $pending chờ duyệt',
                  style: TextStyle(fontSize: 11, color: context.textSecondary)),
            ]),
          ),
          IconButton(icon: Icon(Icons.refresh, color: context.textPrimary), onPressed: _load),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, color: Colors.red, size: 56),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism_outlined,
                color: Colors.green[400], size: 64),
            const SizedBox(height: 12),
            Text(
              'Không có yêu cầu quyên góp nào',
              style: TextStyle(fontSize: 15, color: context.textSecondary),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _load,
              icon: Icon(Icons.refresh, size: 16, color: context.colors.primary),
              label: Text('Làm mới', style: TextStyle(color: context.colors.primary)),
            ),
          ],
        ),
      );
    }

    final filteredList = _filtered;
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                color: context.textSecondary.withValues(alpha: 0.5), size: 56),
            const SizedBox(height: 12),
            Text(
              'Không có dữ liệu trong mục này',
              style: TextStyle(fontSize: 14, color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, kBottomNavigationBarHeight + 12),
        itemCount: filteredList.length,
        separatorBuilder: (_, a) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(filteredList[i]),
      ),
    );
  }

  Widget _buildCard(AdminDonation d) {
    return Container(
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: context.isDarkMode ? null : [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
        border: context.isDarkMode ? Border.all(color: context.divider, width: 0.5) : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Người gửi ─────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                child: Icon(Icons.person, size: 18, color: context.colors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.senderName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
                    Text(d.senderEmail,
                        style:
                            TextStyle(fontSize: 11, color: context.textSecondary)),
                  ],
                ),
              ),
              _DonationStatusBadge(status: d.status),
            ],
          ),

          Divider(height: 16, thickness: 0.5, color: context.divider),

          // ── Thông tin sách ────────────────────────────────
          Text(
            d.bookTitle.isNotEmpty ? d.bookTitle : '(Chưa có tiêu đề)',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.colors.primary),
          ),
          const SizedBox(height: 4),
          _infoRow(
              'Tác giả:', d.bookAuthor.isNotEmpty ? d.bookAuthor : '---'),
          if (d.bookPublisher.isNotEmpty)
            _infoRow('NXB:',
                '${d.bookPublisher}${d.bookYear.isNotEmpty ? ' (${d.bookYear})' : ''}'),
          _infoRow('Tình trạng:',
              d.bookCondition.isNotEmpty ? d.bookCondition : 'Mới'),

          // Ngày gửi
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: context.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Gửi lúc: ${d.createdAt.isNotEmpty ? d.createdAt.substring(0, d.createdAt.length > 16 ? 16 : d.createdAt.length) : "---"}',
                style:
                    TextStyle(fontSize: 11, color: context.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Nút hành động (dynamic theo trạng thái) ────────────────
          _buildDonationActions(d),

        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(value,
                style:
                    TextStyle(fontSize: 12, color: context.textPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction(String msg, VoidCallback onConfirm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: 'Xác nhận',
        message: msg,
        icon: Icons.help_outline_rounded,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok == true) onConfirm();
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _DonationStatusBadge extends StatelessWidget {
  final String status;
  const _DonationStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  (String, Color) _resolve() {
    switch (status) {
      case 'pending':    return ('Chờ duyệt', Colors.orange);
      case 'approved':   return ('Đã duyệt', Colors.indigo);
      case 'in_transit': return ('Đang vận chuyển', Colors.blue);
      case 'received':   return ('Đã nhận', Colors.teal);
      case 'processed':  return ('Đã nhập kho', Colors.green);
      case 'rejected':   return ('Từ chối', Colors.red);
      default:           return (status, Colors.grey);
    }
  }
}

class _DonBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DonBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          elevation: 0,
        ),
        icon: Icon(icon, size: 14, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ),
    );
  }
}
