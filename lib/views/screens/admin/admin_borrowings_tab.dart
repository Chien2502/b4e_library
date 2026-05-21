import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/network_error_handler.dart';
import '../../widgets/custom_dialog.dart';
import '../../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/admin_data_provider.dart';
import '../../../core/theme/theme_extensions.dart';

class AdminBorrowingsTab extends StatefulWidget {
  const AdminBorrowingsTab({super.key});
  @override
  State<AdminBorrowingsTab> createState() => _AdminBorrowingsTabState();
}

class _AdminBorrowingsTabState extends State<AdminBorrowingsTab> with SingleTickerProviderStateMixin {
  final _dio = DioClient().dio;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  
  late TabController _tabController;
  String _subFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get(ApiConstants.adminBorrowings);
      setState(() => _items = List<Map<String, dynamic>>.from(res.data['data'] ?? []));
    } on DioException catch (e) {
      setState(() => _error = NetworkErrorHandler.getFriendlyMessage(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<(String, String, Color)> _getSubFiltersForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return [
          ('all', 'Tất cả', Colors.blueGrey),
          ('pending_pickup', 'Tại quầy (Manual)', Colors.orange),
          ('pending_delivery', 'Giao hàng', Colors.deepOrange),
          ('approved', 'Đã duyệt', Colors.teal),
          ('preparing', 'Đang chuẩn bị', Colors.indigo),
        ];
      case 1:
        return [
          ('all', 'Tất cả', Colors.blueGrey),
          ('shipped', 'Đang giao đi', Colors.blue),
          ('return_approved', 'Đã duyệt trả', Colors.teal),
          ('return_shipping', 'Đang ship trả', Colors.deepOrange),
        ];
      case 2:
        return [
          ('all', 'Tất cả', Colors.blueGrey),
          ('borrowed', 'Đang mượn', Colors.green),
          ('overdue', 'Quá hạn ⚠️', Colors.red),
          ('return_requested', 'Yêu cầu trả', Colors.orange),
        ];
      case 3:
        return [
          ('all', 'Tất cả', Colors.blueGrey),
          ('returned', 'Đã trả', Colors.teal),
          ('cancelled', 'Đã hủy', Colors.grey),
        ];
      default:
        return [];
    }
  }

  int _getCountForSubFilter(int tabIndex, String subFilterKey) {
    List<Map<String, dynamic>> baseItems = [];
    switch (tabIndex) {
      case 0:
        baseItems = _items.where((e) {
          final s = e['status'] ?? '';
          return s == 'pending_approval' || s == 'approved' || s == 'preparing';
        }).toList();
        break;
      case 1:
        baseItems = _items.where((e) {
          final s = e['status'] ?? '';
          return s == 'shipped' || s == 'return_approved' || s == 'return_shipping';
        }).toList();
        break;
      case 2:
        baseItems = _items.where((e) {
          final s = e['status'] ?? '';
          return s == 'borrowed' || s == 'overdue' || s == 'return_requested' || s == 'returning';
        }).toList();
        break;
      case 3:
        baseItems = _items.where((e) {
          final s = e['status'] ?? '';
          return s == 'returned' || s == 'cancelled';
        }).toList();
        break;
    }
    
    if (subFilterKey == 'all') return baseItems.length;
    
    return baseItems.where((e) {
      final s = e['status'] ?? '';
      final d = e['delivery_type'] ?? '';
      
      if (tabIndex == 0) {
        if (subFilterKey == 'pending_pickup') {
          return s == 'pending_approval' && d == 'pickup';
        }
        if (subFilterKey == 'pending_delivery') {
          return s == 'pending_approval' && d == 'delivery';
        }
        return s == subFilterKey;
      }
      
      if (tabIndex == 2) {
        if (subFilterKey == 'return_requested') {
          return s == 'return_requested' || s == 'returning';
        }
      }
      
      return s == subFilterKey;
    }).length;
  }

  List<Map<String, dynamic>> get _filtered {
    final tabIndex = _tabController.index;
    
    // First, filter by tab group
    List<Map<String, dynamic>> tabItems = [];
    switch (tabIndex) {
      case 0: // Chờ xử lý
        tabItems = _items.where((e) {
          final s = e['status'] ?? '';
          return s == 'pending_approval' || s == 'approved' || s == 'preparing';
        }).toList();
        break;
      case 1: // Vận chuyển
        tabItems = _items.where((e) {
          final s = e['status'] ?? '';
          return s == 'shipped' || s == 'return_approved' || s == 'return_shipping';
        }).toList();
        break;
      case 2: // Đang mượn
        tabItems = _items.where((e) {
          final s = e['status'] ?? '';
          return s == 'borrowed' || s == 'overdue' || s == 'return_requested' || s == 'returning';
        }).toList();
        break;
      case 3: // Lịch sử
        tabItems = _items.where((e) {
          final s = e['status'] ?? '';
          return s == 'returned' || s == 'cancelled';
        }).toList();
        break;
    }

    // Second, apply sub-filter within the tab group
    if (_subFilter == 'all') return tabItems;

    return tabItems.where((e) {
      final s = e['status'] ?? '';
      final d = e['delivery_type'] ?? '';
      
      if (tabIndex == 0) {
        if (_subFilter == 'pending_pickup') {
          return s == 'pending_approval' && d == 'pickup';
        }
        if (_subFilter == 'pending_delivery') {
          return s == 'pending_approval' && d == 'delivery';
        }
        return s == _subFilter;
      }
      
      if (tabIndex == 2) {
        if (_subFilter == 'return_requested') {
          return s == 'return_requested' || s == 'returning';
        }
      }
      
      return s == _subFilter;
    }).toList();
  }

  // ── Transition API call ──────────────────────────────────────────
  Future<void> _updateStatus(int borrowId, String newStatus, {String? confirmMsg}) async {
    final title = _actionLabel(newStatus);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: title,
        message: confirmMsg ?? 'Xác nhận thực hiện thao tác này?',
        icon: _actionIcon(newStatus),
        iconColor: _actionColor(newStatus),
        confirmLabel: 'Xác nhận',
        confirmColor: _actionColor(newStatus),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _dio.post(
        ApiConstants.adminUpdateBorrowStatus,
        data: {'borrowing_id': borrowId, 'status': newStatus},
        options: Options(contentType: Headers.jsonContentType),
      );
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, '✅ $title thành công!');
      _load();
    } on DioException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.response?.data?['error'] ?? 'Lỗi xử lý');
    }
  }

  Future<void> _confirmPayment(int borrowId) async {
    try {
      await _dio.post(ApiConstants.confirmPayment, data: {'borrowing_id': borrowId});
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, '✅ Đã xác nhận thanh toán!');
      _load();
    } on DioException catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, e.response?.data?['error'] ?? 'Lỗi xử lý');
    }
  }

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

  Widget _buildTitleBar() {
    return Container(
      color: context.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Icon(Icons.swap_horiz, color: context.colors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quản lý Mượn & Trả Sách',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary)),
              Text('Tổng: ${_items.length} phiếu',
                  style: TextStyle(fontSize: 11, color: context.textSecondary)),
            ]),
          ),
          IconButton(icon: Icon(Icons.refresh, color: context.textPrimary), onPressed: _load),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: context.card,
      width: double.infinity,
      child: TabBar(
        controller: _tabController,
        labelColor: context.colors.primary,
        unselectedLabelColor: context.textSecondary,
        indicatorColor: context.colors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        tabs: const [
          Tab(text: 'Chờ xử lý'),
          Tab(text: 'Vận chuyển'),
          Tab(text: 'Đang mượn'),
          Tab(text: 'Lịch sử'),
        ],
        onTap: (index) {
          setState(() {
            _subFilter = 'all';
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final tabIndex = _tabController.index;
    final subFilters = _getSubFiltersForTab(tabIndex);
    
    return Container(
      color: context.card,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: subFilters.map((filter) {
            final key = filter.$1;
            final label = filter.$2;
            final color = filter.$3;
            final isSelected = _subFilter == key;
            final count = _getCountForSubFilter(tabIndex, key);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white : context.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _subFilter = key;
                  });
                },
                selectedColor: context.colors.primary,
                backgroundColor: context.card,
                checkmarkColor: Colors.white,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? context.colors.primary : context.divider,
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
      ]));
    }
    final list = _filtered;
    if (list.isEmpty) {
      return Center(child: Text('Không có dữ liệu', style: TextStyle(color: context.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, kBottomNavigationBarHeight + 12),
        itemCount: list.length,
        separatorBuilder: (_, idx) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final status   = (item['status'] ?? '').toString();
    final borrowId = int.tryParse('${item['id']}') ?? 0;
    final imageUrl = '${ApiConstants.uploadsUrl}/${item['image_url'] ?? ''}';
    final delivery = (item['delivery_type'] ?? 'pickup').toString();
    final payStatus = (item['payment_status'] ?? '').toString();
    final fee = int.tryParse('${item['shipping_fee'] ?? 0}') ?? 0;
    final returnMethod = item['return_method']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: context.isDarkMode ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))
        ],
        border: context.isDarkMode ? Border.all(color: context.divider, width: 0.5) : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row trên: ảnh + thông tin ────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ảnh sách
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 52, height: 68,
                  child: (item['image_url'] ?? '').toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          httpHeaders: kIsWeb ? const {'ngrok-skip-browser-warning': 'true'} : const {},
                          placeholder: (_, url) => _imgPlaceholder(),
                          errorWidget: (_, url, err) => _imgPlaceholder(),
                        )
                      : _imgPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['book_title'] ?? '---',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  _infoRow(Icons.person_outline,
                      '#${item['user_id']} • ${item['username'] ?? ''} • ${item['phone'] ?? ''}'),
                  _infoRow(Icons.calendar_today_outlined, 'Mượn: ${item['borrow_date'] ?? '---'}'),
                  if ((item['due_date'] ?? '').isNotEmpty)
                    _infoRow(Icons.timer_outlined, 'Hạn: ${item['due_date']}', color: context.colors.error),
                  // Delivery info
                  if (delivery == 'delivery') ...[
                    _infoRow(Icons.local_shipping_outlined,
                        '${item['delivery_address'] ?? 'Chưa có địa chỉ'}',
                        color: const Color(0xFF1E88E5)),
                    if (fee > 0)
                      _infoRow(Icons.payments_outlined,
                          'Phí ship: ${_fmtMoney(fee)} — ${_payLabel(payStatus)}',
                          color: payStatus == 'paid' ? Colors.green : Colors.orange),
                  ],
                  if (returnMethod != null && (status == 'return_requested' || status == 'return_shipping' || status == 'returned')) ...[
                    _infoRow(
                      returnMethod == 'direct' ? Icons.storefront_outlined : Icons.local_shipping_outlined,
                      returnMethod == 'direct' ? 'Trả trực tiếp tại quầy' : 'Gửi qua bưu điện/shipper',
                      color: returnMethod == 'direct' ? Colors.teal : Colors.orange,
                    ),
                  ],
                ]),
              ),
              // Badge trạng thái
              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Row dưới: Action buttons ──────────────────────────────
          _buildActions(borrowId, status, delivery, payStatus, item),
        ],
      ),
    );
  }

  Widget _buildActions(
    int borrowId,
    String status,
    String delivery,
    String payStatus,
    Map<String, dynamic> item,
  ) {
    final actions = <Widget>[];

    switch (status) {
      // ── 1. Chờ duyệt ───────────────────────────────────────────
      case 'pending_approval':
        // Nếu delivery + VietQR + chưa trả → xác nhận thanh toán trước
        if (delivery == 'delivery' &&
            item['payment_method'] == 'vietqr' &&
            payStatus != 'paid') {
          actions.add(_ActionBtn(
            label: 'Xác nhận đã TT',
            icon: Icons.qr_code_scanner,
            color: Colors.teal,
            onTap: () => _confirmPayment(borrowId),
          ));
        }
        actions.add(_ActionBtn(
          label: 'Duyệt đơn',
          icon: Icons.thumb_up_alt_outlined,
          color: Colors.green,
          onTap: () {
            if (delivery == 'pickup') {
              _updateStatus(
                borrowId,
                'borrowed',
                confirmMsg: 'Xác nhận duyệt và cho mượn sách trực tiếp tại quầy?',
              );
            } else {
              _updateStatus(
                borrowId,
                'approved',
                confirmMsg: 'Duyệt yêu cầu mượn sách này?',
              );
            }
          },
        ));
        actions.add(_ActionBtn(
          label: 'Từ chối',
          icon: Icons.cancel_outlined,
          color: Colors.red,
          onTap: () => _updateStatus(borrowId, 'cancelled',
              confirmMsg: 'Từ chối và hủy phiếu mượn này?'),
        ));
        break;

      // ── 2. Đã duyệt (pickup) → cho mượn / (delivery) → chuẩn bị ─
      case 'approved':
        if (delivery == 'pickup') {
          actions.add(_ActionBtn(
            label: 'Xác nhận đã lấy',
            icon: Icons.storefront,
            color: Colors.indigo,
            onTap: () => _updateStatus(borrowId, 'borrowed',
                confirmMsg: 'User đã đến lấy sách trực tiếp?'),
          ));
        } else {
          actions.add(_ActionBtn(
            label: 'Bắt đầu chuẩn bị',
            icon: Icons.inventory_2_outlined,
            color: Colors.indigo,
            onTap: () => _updateStatus(borrowId, 'preparing',
                confirmMsg: 'Bắt đầu đóng gói và chuẩn bị giao hàng?'),
          ));
        }
        break;

      // ── 3. Đang chuẩn bị → đã ship ──────────────────────────────
      case 'preparing':
        actions.add(_ActionBtn(
          label: 'Đã giao shipper',
          icon: Icons.local_shipping_outlined,
          color: Colors.blue,
          onTap: () => _updateStatus(borrowId, 'shipped',
              confirmMsg: 'Xác nhận đã bàn giao sách cho shipper?'),
        ));
        break;

      // ── 4. Đang vận chuyển → chờ nhận ────────────────────────────
      case 'shipped':
        actions.add(const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('Chờ user xác nhận đã nhận sách',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ));
        break;

      // ── 5. Đang mượn / quá hạn ──────────────────────────────────
      case 'borrowed':
      case 'overdue':
        actions.add(const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('Chờ user gửi trả sách',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ));
        if (item['renew_status'] == 'pending') {
          actions.add(_RenewalActions(
            borrowId: borrowId,
            days: int.tryParse('${item['renew_days'] ?? 0}') ?? 0,
            onAction: (a) => _handleRenewal(borrowId, a),
          ));
        }
        break;

      // ── 5b. Đã duyệt trả → chờ user gửi shipper ──────────────────
      case 'return_approved':
        actions.add(const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text('Chờ user gửi shipper trả sách',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ));
        break;

      // ── 6. Yêu cầu trả ─────────────────────────────────
      case 'return_requested':
        final retMethod = item['return_method']?.toString() ?? 'direct';
        if (retMethod == 'direct') {
          actions.add(_ActionBtn(
            label: 'Đã nhận sách trả',
            icon: Icons.assignment_return_outlined,
            color: Colors.green,
            onTap: () => _updateStatus(borrowId, 'returned',
                confirmMsg: 'Xác nhận đã nhận lại sách trực tiếp từ user?'),
          ));
        } else {
          actions.add(_ActionBtn(
            label: 'Duyệt yêu cầu trả',
            icon: Icons.assignment_turned_in_outlined,
            color: Colors.blue,
            onTap: () => _updateStatus(borrowId, 'return_approved',
                confirmMsg: 'Duyệt yêu cầu gửi trả sách qua bưu điện/shipper của user?'),
          ));
        }
        break;

      // ── 7. Sách đang về (delivery) ───────────────────────────────
      case 'return_shipping':
        actions.add(_ActionBtn(
          label: 'Đã nhận về kho',
          icon: Icons.inventory,
          color: Colors.green,
          onTap: () => _updateStatus(borrowId, 'returned',
              confirmMsg: 'Xác nhận đã nhận lại sách về thư viện?'),
        ));
        break;

      // ── Legacy (dữ liệu cũ) ──────────────────────────────────────
      case 'returning':
        actions.add(_ActionBtn(
          label: 'Xác nhận đã nhận',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          onTap: () => _updateStatus(borrowId, 'returned'),
        ));
        break;

      case 'returned':
      case 'cancelled':
        actions.add(const SizedBox.shrink());
        break;
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 8, runSpacing: 6, children: actions);
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Icon(icon, size: 12, color: color ?? context.textSecondary),
        const SizedBox(width: 4),
        Expanded(child: Text(text,
            style: TextStyle(fontSize: 11, color: color ?? context.textSecondary),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: context.background,
    child: Icon(Icons.menu_book_outlined, size: 28, color: context.divider),
  );

  Future<void> _handleRenewal(int borrowId, String action) async {
    final err = await context.read<AdminDataProvider>().handleRenewal(borrowId, action);
    if (!mounted) return;
    if (err == null) {
      SnackBarUtils.showSuccess(context, action == 'approve' ? 'Đã duyệt gia hạn' : 'Đã từ chối gia hạn');
      _load();
    } else {
      SnackBarUtils.showError(context, err);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────
  String _actionLabel(String s) {
    const m = {
      'approved': 'Duyệt đơn', 'cancelled': 'Từ chối', 'preparing': 'Chuẩn bị',
      'shipped': 'Đã giao shipper', 'borrowed': 'Xác nhận nhận sách',
      'returned': 'Xác nhận đã trả', 'return_approved': 'Duyệt yêu cầu trả',
      'return_shipping': 'Giao shipper trả',
    };
    return m[s] ?? s;
  }

  IconData _actionIcon(String s) {
    const m = {
      'approved': Icons.thumb_up_alt_outlined, 'cancelled': Icons.cancel_outlined,
      'preparing': Icons.inventory_2_outlined, 'shipped': Icons.local_shipping_outlined,
      'borrowed': Icons.check_circle_outline, 'returned': Icons.assignment_return_outlined,
      'return_approved': Icons.assignment_turned_in_outlined,
      'return_shipping': Icons.local_shipping_outlined,
    };
    return m[s] ?? Icons.edit;
  }

  Color _actionColor(String s) {
    const m = {
      'approved': Colors.green, 'cancelled': Colors.red, 'preparing': Colors.indigo,
      'shipped': Colors.blue, 'borrowed': Colors.green, 'returned': Colors.green,
      'return_approved': Colors.blue, 'return_shipping': Colors.orange,
    };
    return (m[s] ?? Colors.grey) as Color;
  }

  String _fmtMoney(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$bufđ';
  }

  String _payLabel(String s) {
    return s == 'paid' ? '✅ Đã thanh toán' : '⏳ Chưa thanh toán';
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

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
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }

  (String, Color) _resolve() {
    switch (status) {
      case 'pending_approval':  return ('Chờ duyệt', Colors.orange);
      case 'approved':          return ('Đã duyệt', Colors.teal);
      case 'preparing':         return ('Chuẩn bị', Colors.indigo);
      case 'shipped':           return ('Đang ship', Colors.blue);
      case 'borrowed':          return ('Đang mượn', Colors.green.shade700);
      case 'overdue':           return ('Quá hạn', Colors.red);
      case 'return_requested':  return ('Yêu cầu trả', Colors.deepOrange);
      case 'return_approved':   return ('Đã duyệt trả', Colors.teal);
      case 'return_shipping':   return ('Sách về kho', Colors.deepOrange);
      case 'returning':         return ('Chờ trả', Colors.orange);
      case 'returned':          return ('Đã trả', Colors.green);
      case 'cancelled':         return ('Đã hủy', Colors.grey);
      default:                  return (status, Colors.grey);
    }
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        icon: Icon(icon, size: 13, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ),
    );
  }
}

class _RenewalActions extends StatelessWidget {
  final int borrowId;
  final int days;
  final void Function(String) onAction;

  const _RenewalActions({
    required this.borrowId,
    required this.days,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Expanded(child: Text('Xin gia hạn thêm $days ngày',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue))),
        _ActionBtn(label: 'Duyệt', icon: Icons.check, color: Colors.green, onTap: () => onAction('approve')),
        const SizedBox(width: 6),
        _ActionBtn(label: 'Từ chối', icon: Icons.close, color: Colors.red, onTap: () => onAction('reject')),
      ]),
    );
  }
}
