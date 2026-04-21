import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class AdminDashboardTab extends StatefulWidget {
  /// Callback chuyển tab trong AdminScreen.
  /// 0=Dashboard, 1=Sách, 2=Thể loại, 3=Quyên góp, 4=Mượn/Trả, 5=Users
  final void Function(int tabIndex)? onNavigate;
  const AdminDashboardTab({super.key, this.onNavigate});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  final _dio = DioClient().dio;
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _dio.get(ApiConstants.adminStats);
      setState(() => _stats = Map<String, dynamic>.from(res.data));
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(() => _error = data is Map
          ? data['error']?.toString() ?? data['message']?.toString()
          : e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            const Text(
              'Thống kê & Quản lý',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nhấn vào từng mục để quản lý chi tiết',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildNavCards(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Header banner ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_library_outlined,
              color: Colors.white, size: 36),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hệ thống quản trị thư viện',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'B4E Library Admin Panel',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _load,
            tooltip: 'Làm mới',
          ),
        ],
      ),
    );
  }

  // ── Stat + Nav cards gộp lại ─────────────────────────────────────
  Widget _buildNavCards() {
    final cards = _cards();
    return Column(
      children: [
        // Hàng 1: 2 card lớn nhiều quan trọng
        Row(
          children: [
            Expanded(child: _buildCard(cards[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildCard(cards[1])),
          ],
        ),
        const SizedBox(height: 12),
        // Hàng 2: 2 card alert (màu cam, đỏ)
        Row(
          children: [
            Expanded(child: _buildCard(cards[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildCard(cards[3])),
          ],
        ),
        const SizedBox(height: 12),
        // Hàng 3: card thể loại (chiếm full width, ít dữ liệu số)
        _buildCard(cards[4], fullWidth: true),
      ],
    );
  }

  // ── Dữ liệu từng card ────────────────────────────────────────────
  List<_NavCard> _cards() => [
        _NavCard(
          tabIndex: 1,
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF1565C0),
          label: 'Kho sách',
          value: '${_stats['books'] ?? 0}',
          unit: 'đầu sách',
          action: 'Quản lý sách →',
          badge: null,
        ),
        _NavCard(
          tabIndex: 5,
          icon: Icons.people_rounded,
          color: Colors.teal,
          label: 'Người dùng',
          value: '${_stats['users'] ?? 0}',
          unit: 'tài khoản',
          action: 'Quản lý users →',
          badge: null,
        ),
        _NavCard(
          tabIndex: 3,
          icon: Icons.volunteer_activism_rounded,
          color: Colors.orange,
          label: 'Chờ duyệt quyên góp',
          value: '${_stats['pending_donations'] ?? 0}',
          unit: 'yêu cầu',
          action: 'Duyệt ngay →',
          badge: int.tryParse('${_stats['pending_donations'] ?? 0}') != null &&
                  (int.tryParse('${_stats['pending_donations'] ?? 0}') ?? 0) > 0
              ? '!'
              : null,
        ),
        _NavCard(
          tabIndex: 4,
          icon: Icons.assignment_return_rounded,
          color: Colors.redAccent,
          label: 'Chờ xác nhận trả',
          value: '${_stats['returning_books'] ?? 0}',
          unit: 'lượt trả',
          action: 'Xác nhận →',
          badge: int.tryParse('${_stats['returning_books'] ?? 0}') != null &&
                  (int.tryParse('${_stats['returning_books'] ?? 0}') ?? 0) > 0
              ? '!'
              : null,
        ),
        _NavCard(
          tabIndex: 2,
          icon: Icons.category_rounded,
          color: Colors.deepPurple,
          label: 'Thể loại sách',
          value: '${_stats['categories'] ?? '—'}',
          unit: 'thể loại',
          action: 'Quản lý thể loại →',
          badge: null,
        ),
      ];

  // ── Card widget ───────────────────────────────────────────────────
  Widget _buildCard(_NavCard c, {bool fullWidth = false}) {
    final hasAlert = c.badge != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onNavigate != null
            ? () => widget.onNavigate!(c.tabIndex)
            : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: hasAlert
                ? Border.all(color: c.color.withAlpha(80), width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: hasAlert
                    ? c.color.withAlpha(30)
                    : Colors.black.withAlpha(10),
                blurRadius: hasAlert ? 12 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: fullWidth
              ? _buildCardInnerRow(c)
              : _buildCardInnerColumn(c),
        ),
      ),
    );
  }

  // layout dọc (cho 2 hàng 2 cột)
  Widget _buildCardInnerColumn(_NavCard c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: c.color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(c.icon, color: c.color, size: 20),
            ),
            if (c.badge != null)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: c.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high,
                    color: Colors.white, size: 13),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          c.value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: c.color,
            height: 1,
          ),
        ),
        Text(
          c.unit,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: 0.5),
        const SizedBox(height: 8),
        Text(
          c.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                c.action,
                style: TextStyle(
                  fontSize: 11,
                  color: c.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 10, color: c.color),
          ],
        ),
      ],
    );
  }

  // layout ngang (cho full width)
  Widget _buildCardInnerRow(_NavCard c) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(c.icon, color: c.color, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                c.action,
                style: TextStyle(fontSize: 12, color: c.color),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              c.value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: c.color,
              ),
            ),
            Text(c.unit,
                style:
                    TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(width: 4),
        Icon(Icons.arrow_forward_ios, size: 12, color: c.color.withAlpha(150)),
      ],
    );
  }

  // ── Error state ───────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 56),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Lỗi không xác định',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────
class _NavCard {
  final int tabIndex;
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final String action;
  final String? badge;

  const _NavCard({
    required this.tabIndex,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    required this.action,
    this.badge,
  });
}
