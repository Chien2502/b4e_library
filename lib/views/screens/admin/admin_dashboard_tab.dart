import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/admin_data_provider.dart';

class AdminDashboardTab extends StatefulWidget {
  /// Callback chuyển tab trong AdminScreen.
  /// 0=Dashboard, 1=Sách, 2=Thể loại, 3=Quyên góp, 4=Mượn/Trả, 5=Users
  final void Function(int tabIndex)? onNavigate;
  const AdminDashboardTab({super.key, this.onNavigate});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  @override
  void initState() {
    super.initState();
    // Fetch sau frame đầu (tránh context-in-initState)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminDataProvider>().fetchStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsState = context.watch<AdminDataProvider>().stats;
    final loading = statsState.isLoading && !statsState.hasData;
    final error = statsState.error;
    final stats = statsState.data ?? {};

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && !statsState.hasData) {
      return _buildError(error, () =>
          context.read<AdminDataProvider>().fetchStats(forceRefresh: true));
    }
    return RefreshIndicator(
      onRefresh: () =>
          context.read<AdminDataProvider>().fetchStats(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(stats),
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
            _buildNavCards(stats),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Header banner ────────────────────────────────────────────────
  Widget _buildHeader(Map<String, dynamic> stats) {
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
            onPressed: () => context.read<AdminDataProvider>().fetchStats(forceRefresh: true),
            tooltip: 'Làm mới',
          ),
        ],
      ),
    );
  }

  // ── Stat + Nav cards gộp lại ─────────────────────────────────────
  Widget _buildNavCards(Map<String, dynamic> stats) {
    final cards = _cards(stats);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCard(cards[0])),
            const SizedBox(width: 12),
            Expanded(child: _buildCard(cards[1])),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildCard(cards[2])),
            const SizedBox(width: 12),
            Expanded(child: _buildCard(cards[3])),
          ],
        ),
        const SizedBox(height: 12),
        _buildCard(cards[4], fullWidth: true),
      ],
    );
  }

  // ── Dữ liệu từng card ────────────────────────────────────────────
  List<_NavCard> _cards(Map<String, dynamic> stats) => [
        _NavCard(
          tabIndex: 1,
          icon: Icons.menu_book_rounded,
          color: const Color(0xFF1565C0),
          label: 'Kho sách',
          value: '${stats['books'] ?? 0}',
          unit: 'đầu sách',
          action: 'Quản lý sách →',
          badge: null,
        ),
        _NavCard(
          tabIndex: 5,
          icon: Icons.people_rounded,
          color: Colors.teal,
          label: 'Người dùng',
          value: '${stats['users'] ?? 0}',
          unit: 'tài khoản',
          action: 'Quản lý users →',
          badge: null,
        ),
        _NavCard(
          tabIndex: 3,
          icon: Icons.volunteer_activism_rounded,
          color: Colors.orange,
          label: 'Chờ duyệt quyên góp',
          value: '${stats['pending_donations'] ?? 0}',
          unit: 'yêu cầu',
          action: 'Duyệt ngay →',
          badge: int.tryParse('${stats['pending_donations'] ?? 0}') != null &&
                  (int.tryParse('${stats['pending_donations'] ?? 0}') ?? 0) > 0
              ? '!'
              : null,
        ),
        _NavCard(
          tabIndex: 4,
          icon: Icons.assignment_return_rounded,
          color: Colors.redAccent,
          label: 'Chờ xác nhận trả',
          value: '${stats['returning_books'] ?? 0}',
          unit: 'lượt trả',
          action: 'Xác nhận →',
          badge: int.tryParse('${stats['returning_books'] ?? 0}') != null &&
                  (int.tryParse('${stats['returning_books'] ?? 0}') ?? 0) > 0
              ? '!'
              : null,
        ),
        _NavCard(
          tabIndex: 2,
          icon: Icons.category_rounded,
          color: Colors.deepPurple,
          label: 'Thể loại sách',
          value: '${stats['categories'] ?? '—'}',
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
  Widget _buildError(String msg, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 56),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
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
