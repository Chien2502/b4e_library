import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/donation_record_model.dart';

// ── Các lựa chọn dropdown ──────────────────────────────────────────
const List<Map<String, String>> _conditionOptions = [
  {'value': 'new', 'label': 'Mới (100%)'},
  {'value': 'like_new', 'label': 'Gần như mới (90-99%)'},
  {'value': 'good', 'label': 'Tốt (80-89%)'},
  {'value': 'fair', 'label': 'Khá (50-79%)'},
  {'value': 'poor', 'label': 'Cũ (dưới 50%)'},
];

const List<Map<String, String>> _donationTypeOptions = [
  {'value': 'direct', 'label': 'Trực tiếp đến thư viện'},
  {'value': 'pickup', 'label': 'Đề nghị đến nhận tại nhà'},
  {'value': 'delivery', 'label': 'Gửi qua dịch vụ chuyển phát'},
];

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DioClient _dioClient = DioClient();

  // ── Form state ─────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _publisherCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String? _selectedCondition;
  String? _selectedDonationType;
  bool _isSubmitting = false;
  bool _submitSuccess = false;

  // ── History state ───────────────────────────────────────────────
  List<DonationRecord> _donations = [];
  bool _isHistoryLoading = false;
  String _historyError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Tải lịch sử khi chuyển sang tab Theo dõi
      if (_tabController.index == 1 && _donations.isEmpty) {
        _fetchHistory();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _publisherCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  // ── API: Gửi form quyên góp ────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final Response res = await _dioClient.dio.post(
        ApiConstants.createDonation,
        data: {
          'book_title': _titleCtrl.text.trim(),
          'book_author': _authorCtrl.text.trim(),
          'book_publisher': _publisherCtrl.text.trim().isEmpty
              ? null
              : _publisherCtrl.text.trim(),
          'book_year': _yearCtrl.text.trim().isEmpty
              ? null
              : _yearCtrl.text.trim(),
          'book_condition': _selectedCondition,
          'donation_type': _selectedDonationType,
        },
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        setState(() {
          _submitSuccess = true;
          _donations = []; // Invalidate cache để tab theo dõi reload
        });
        _resetForm();
      } else {
        _showSnackBar(
            res.data?['error'] ?? 'Gửi thất bại. Vui lòng thử lại.',
            isError: true);
      }
    } on DioException catch (e) {
      _showSnackBar(
          e.response?.data?['error'] ??
              'Lỗi kết nối: ${e.message ?? e.type.name}',
          isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ── API: Lấy lịch sử quyên góp ────────────────────────────────
  Future<void> _fetchHistory() async {
    setState(() {
      _isHistoryLoading = true;
      _historyError = '';
    });

    try {
      final Response res =
          await _dioClient.dio.get(ApiConstants.userDonations);

      if (res.statusCode == 200) {
        final List<dynamic> data = res.data as List<dynamic>;
        setState(() {
          _donations =
              data.map((j) => DonationRecord.fromJson(j)).toList();
        });
      } else {
        setState(() => _historyError = 'Lỗi server: ${res.statusCode}');
      }
    } on DioException catch (e) {
      setState(
          () => _historyError = 'Lỗi kết nối: ${e.message ?? e.type.name}');
    } finally {
      setState(() => _isHistoryLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleCtrl.clear();
    _authorCtrl.clear();
    _publisherCtrl.clear();
    _yearCtrl.clear();
    setState(() {
      _selectedCondition = null;
      _selectedDonationType = null;
    });
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Tab bar ──────────────────────────────────────────────
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14),
            tabs: const [
              Tab(
                icon: Icon(Icons.volunteer_activism_outlined, size: 18),
                text: 'Quyên góp',
                iconMargin: EdgeInsets.only(bottom: 2),
              ),
              Tab(
                icon: Icon(Icons.track_changes_outlined, size: 18),
                text: 'Theo dõi',
                iconMargin: EdgeInsets.only(bottom: 2),
              ),
            ],
          ),
        ),

        // ── Tab view ─────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFormTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TAB 1: FORM QUYÊN GÓP
  // ════════════════════════════════════════════════════════════════
  Widget _buildFormTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildHeroBanner(),
          _buildProcessSteps(),
          const SizedBox(height: 16),
          _submitSuccess ? _buildSuccessBanner() : _buildDonationForm(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Banner xanh gradient ─────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.volunteer_activism,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quyên góp sách',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 3),
                Text('Chia sẻ tri thức, lan tỏa yêu thương',
                    style:
                        TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quy trình 3 bước ────────────────────────────────────────
  Widget _buildProcessSteps() {
    const steps = [
      {
        'num': '1',
        'title': 'Điền thông tin',
        'desc': 'Điền đầy đủ thông tin về cuốn sách vào form bên dưới.',
      },
      {
        'num': '2',
        'title': 'Xác nhận',
        'desc': 'Chúng tôi sẽ xác nhận thông tin và sắp xếp việc nhận sách.',
      },
      {
        'num': '3',
        'title': 'Gửi sách',
        'desc':
            'Gửi trực tiếp hoặc chúng tôi sẽ sắp xếp người đến nhận sách.',
      },
    ];

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Column(
        children: [
          const Text('Quy trình quyên góp',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 6),
          Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: steps.length,
              separatorBuilder: (_, a) => const SizedBox(width: 10),
              itemBuilder: (_, i) => SizedBox(
                width: 180,
                child: _buildStepCard(
                  number: steps[i]['num']!,
                  title: steps[i]['title']!,
                  desc: steps[i]['desc']!,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildStepCard(
      {required String number,
      required String title,
      required String desc}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
                color: Color(0xFF1E88E5), shape: BoxShape.circle),
            child: Center(
                child: Text(number,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14))),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black87),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Expanded(
            child: Text(desc,
                style: TextStyle(
                    fontSize: 10, color: Colors.grey[600], height: 1.4),
                textAlign: TextAlign.center,
                overflow: TextOverflow.fade),
          ),
        ],
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────────────
  Widget _buildDonationForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Form quyên góp sách',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0))),
            const SizedBox(height: 20),
            _buildLabel('Tên sách', required: true),
            _buildTextField(
              controller: _titleCtrl,
              hint: 'Nhập tên sách...',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập tên sách'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildLabel('Tác giả', required: true),
            _buildTextField(
              controller: _authorCtrl,
              hint: 'Nhập tên tác giả...',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập tên tác giả'
                  : null,
            ),
            const SizedBox(height: 14),
            _buildLabel('Nhà xuất bản'),
            _buildTextField(
                controller: _publisherCtrl,
                hint: 'Nhập tên nhà xuất bản...'),
            const SizedBox(height: 14),
            _buildLabel('Năm xuất bản'),
            _buildTextField(
              controller: _yearCtrl,
              hint: 'VD: 2020',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final y = int.tryParse(v);
                return (y == null || y < 1900 || y > 2100)
                    ? 'Năm không hợp lệ'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            _buildLabel('Tình trạng sách', required: true),
            _buildDropdown(
              hint: '-- Chọn tình trạng --',
              value: _selectedCondition,
              options: _conditionOptions,
              onChanged: (v) => setState(() => _selectedCondition = v),
              validator: (v) =>
                  v == null ? 'Vui lòng chọn tình trạng sách' : null,
            ),
            const SizedBox(height: 14),
            _buildLabel('Hình thức quyên góp', required: true),
            _buildDropdown(
              hint: '-- Chọn hình thức --',
              value: _selectedDonationType,
              options: _donationTypeOptions,
              onChanged: (v) => setState(() => _selectedDonationType = v),
              validator: (v) =>
                  v == null ? 'Vui lòng chọn hình thức quyên góp' : null,
            ),
            const SizedBox(height: 8),
            Text('* Thông tin bắt buộc',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  disabledBackgroundColor:
                      const Color(0xFF1E88E5).withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined,
                        color: Colors.white, size: 20),
                label: Text(
                  _isSubmitting ? 'Đang gửi...' : 'Gửi quyên góp',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner thành công ─────────────────────────────────────────
  Widget _buildSuccessBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration:
                BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
            child: const Icon(Icons.check_circle,
                color: Colors.green, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Gửi quyên góp thành công!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Cảm ơn bạn đã đóng góp! Chúng tôi sẽ liên hệ để xác nhận và sắp xếp nhận sách.',
            style: TextStyle(
                fontSize: 13, color: Colors.grey[600], height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _submitSuccess = false),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: Color(0xFF1E88E5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.add,
                    color: Color(0xFF1E88E5), size: 16),
                label: const Text('Quyên góp thêm',
                    style: TextStyle(
                        color: Color(0xFF1E88E5), fontSize: 13)),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(1);
                  _fetchHistory();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                icon: const Icon(Icons.track_changes,
                    color: Colors.white, size: 16),
                label: const Text('Xem lịch sử',
                    style: TextStyle(
                        color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TAB 2: LỊCH SỬ QUYÊN GÓP
  // ════════════════════════════════════════════════════════════════
  Widget _buildHistoryTab() {
    if (_isHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 8),
            Text(_historyError,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _fetchHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_donations.isEmpty && !_isHistoryLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism_outlined,
                size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Bạn chưa có đơn quyên góp nào',
                style: TextStyle(fontSize: 15, color: Colors.grey[500])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchHistory,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tải dữ liệu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: Column(
        children: [
          // Header bảng
          _buildTableHeader(),
          // Danh sách
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _donations.length,
              separatorBuilder: (_, a) =>
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (_, i) => _buildDonationRow(_donations[i]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header giống table web ─────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('Tên sách',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87)),
          ),
          Expanded(
            flex: 3,
            child: Text('Hình thức',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87)),
          ),
          Expanded(
            flex: 3,
            child: Text('Trạng thái',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  // ── 1 dòng trong bảng lịch sử ─────────────────────────────────
  Widget _buildDonationRow(DonationRecord d) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên sách + tác giả + ngày gửi
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.bookTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (d.bookAuthor.isNotEmpty)
                  Text(
                    d.bookAuthor,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF1565C0)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 10, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        _formatDateTime(d.createdAt),
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Hình thức
          Expanded(
            flex: 3,
            child: Text(
              d.donationTypeLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),

          // Badge trạng thái
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildStatusBadge(d.status, d.statusLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, String label) {
    Color bg;
    Color fg;

    switch (status) {
      case 'pending':
        bg = const Color(0xFFFFF3E0);
        fg = Colors.orange[800]!;
        break;
      case 'approved':
        bg = const Color(0xFFE8F5E9);
        fg = Colors.green[700]!;
        break;
      case 'rejected':
        bg = const Color(0xFFFFEBEE);
        fg = Colors.red[700]!;
        break;
      default:
        bg = Colors.grey[100]!;
        fg = Colors.grey[700]!;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  String _formatDateTime(String raw) {
    if (raw.isEmpty) return '—';
    // "2026-04-02 14:49:08" → "02/04/2026 14:49"
    try {
      final parts = raw.split(' ');
      final dateParts = parts[0].split('-');
      final time = parts.length > 1 ? parts[1].substring(0, 5) : '';
      return '${dateParts[2]}/${dateParts[1]}/${dateParts[0]} $time';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87),
          children: required
              ? const [
                  TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red))
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(fontSize: 13, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFF1E88E5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<Map<String, String>> options,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      hint: Text(hint,
          style:
              TextStyle(fontSize: 13, color: Colors.grey[400])),
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: Color(0xFF1E88E5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      icon: const Icon(Icons.keyboard_arrow_down,
          color: Colors.grey),
      isExpanded: true,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      items: options.map((opt) {
        return DropdownMenuItem(
          value: opt['value'],
          child: Text(opt['label']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

