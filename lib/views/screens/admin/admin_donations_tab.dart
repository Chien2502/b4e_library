import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

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

class _AdminDonationsTabState extends State<AdminDonationsTab> {
  final _dio = DioClient().dio;
  List<AdminDonation> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
      final msg = _parseDioError(e);
      setState(() => _error = msg);
    } on TypeError catch (e) {
      setState(() => _error = 'Lỗi phân tích dữ liệu: $e');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Approve ───────────────────────────────────────────────────────
  Future<void> _approve(int donationId) async {
    try {
      // PHP đọc json_decode(file_get_contents('php://input'))
      // → phải gửi JSON body (contentType: json)
      await _dio.post(
        ApiConstants.adminApproveDonation,
        data: {'donation_id': donationId},
        options: Options(contentType: Headers.jsonContentType),
      );
      if (!mounted) return;
      _showSnack('✅ Đã tiếp nhận sách vào kho thành công!', false);
      _load();
    } on DioException catch (e) {
      _showSnack(_parseDioError(e), true);
    } catch (e) {
      _showSnack(e.toString(), true);
    }
  }

  // ── Reject ────────────────────────────────────────────────────────
  Future<void> _reject(int donationId) async {
    try {
      await _dio.post(
        ApiConstants.adminRejectDonation,
        data: {'donation_id': donationId},
        options: Options(contentType: Headers.jsonContentType),
      );
      if (!mounted) return;
      _showSnack('Đã từ chối yêu cầu quyên góp.', false);
      _load();
    } on DioException catch (e) {
      _showSnack(_parseDioError(e), true);
    } catch (e) {
      _showSnack(e.toString(), true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────
  String _parseDioError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        return data['error']?.toString() ??
            data['message']?.toString() ??
            'Lỗi server ${e.response?.statusCode}';
      }
    } catch (_) {}
    return e.message ?? 'Lỗi kết nối';
  }

  void _showSnack(String msg, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTitleBar(),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildTitleBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism,
              color: Color(0xFF1565C0), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Duyệt Quyên Góp Sách',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87)),
                Text(
                  _items.isEmpty && !_loading
                      ? 'Không có yêu cầu nào chờ duyệt'
                      : 'Có ${_items.length} yêu cầu chờ xác nhận nhập kho',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Tải lại',
          ),
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

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                color: Colors.green[400], size: 64),
            const SizedBox(height: 12),
            const Text(
              'Không có yêu cầu chờ duyệt',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tất cả quyên góp đã được xử lý!',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, kBottomNavigationBarHeight + 12),
        itemCount: _items.length,
        separatorBuilder: (_, a) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildCard(_items[i]),
      ),
    );
  }

  Widget _buildCard(AdminDonation d) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Người gửi ─────────────────────────────────────
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.person, size: 18, color: Color(0xFF1565C0)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.senderName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(d.senderEmail,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              // Badge hình thức
              if (d.donationType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(d.donationType,
                      style: TextStyle(
                          fontSize: 10, color: Colors.blue[800])),
                ),
            ],
          ),

          const Divider(height: 16, thickness: 0.5),

          // ── Thông tin sách ────────────────────────────────
          Text(
            d.bookTitle.isNotEmpty ? d.bookTitle : '(Chưa có tiêu đề)',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0)),
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
              const Icon(Icons.schedule, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Gửi lúc: ${d.createdAt.isNotEmpty ? d.createdAt.substring(0, d.createdAt.length > 16 ? 16 : d.createdAt.length) : "---"}',
                style:
                    const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Nút hành động ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmAction(
                    'Tiếp nhận sách "${d.bookTitle}" vào kho?',
                    () => _approve(d.id),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check, size: 16, color: Colors.white),
                  label: const Text('Tiếp nhận',
                      style:
                          TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmAction(
                    'Từ chối yêu cầu quyên góp này?',
                    () => _reject(d.id),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                  label: const Text('Từ chối',
                      style:
                          TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
            ],
          ),
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
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction(String msg, VoidCallback onConfirm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xác nhận'),
        content: Text(msg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0)),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok == true) onConfirm();
  }
}
