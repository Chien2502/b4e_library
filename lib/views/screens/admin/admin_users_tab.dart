import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});
  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _dio = DioClient().dio;
  List<Map<String, dynamic>> _users = [];
  int? _currentAdminId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _dio.get(ApiConstants.adminUsers);
      setState(() {
        _users = List<Map<String, dynamic>>.from(res.data['data'] ?? []);
        _currentAdminId = res.data['current_admin_id'];
      });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['error'] ?? e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser(int userId, String role, String username) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa người dùng'),
        content: Text('Bạn có chắc muốn xóa tài khoản "$username"?\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _dio.post(ApiConstants.adminDeleteUser, data: {'id': userId});
      if (!mounted) return;
      _showSnack('Đã xóa người dùng "$username".', false);
      _load();
    } on DioException catch (e) {
      _showSnack(e.response?.data?['error'] ?? 'Lỗi xử lý', true);
    }
  }

  void _openEditSheet(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditUserSheet(
        user: user,
        dio: _dio,
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
      ),
    );
  }

  void _showSnack(String msg, bool err) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'super-admin': return Colors.pink;
      case 'admin': return Colors.deepPurple;
      default: return Colors.teal;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'super-admin': return 'Super-Admin';
      case 'admin': return 'Admin';
      default: return 'User';
    }
  }

  bool _canEdit(Map<String, dynamic> user) {
    // Super-admin không cần restrict; admin không sửa super-admin
    final targetRole = user['role'] ?? 'user';
    if (targetRole == 'super-admin') return false;
    return true;
  }

  bool _canDelete(Map<String, dynamic> user) {
    final targetId = int.tryParse('${user['id']}') ?? -1;
    final targetRole = user['role'] ?? 'user';
    if (targetId == _currentAdminId) return false; // Không xóa chính mình
    if (targetRole == 'super-admin') return false;
    if (targetRole == 'admin') return false; // Admin không xóa admin khác
    return true;
  }

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.people, color: Color(0xFF1565C0), size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quản lý Người dùng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Danh sách tất cả tài khoản trong hệ thống',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, color: Colors.red, size: 48),
      const SizedBox(height: 12),
      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Thử lại')),
    ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length,
        separatorBuilder: (_, a) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildCard(_users[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> user) {
    final id = int.tryParse('${user['id']}') ?? 0;
    final role = user['role'] ?? 'user';
    final username = user['username'] ?? '---';
    final email = user['email'] ?? '---';
    final phone = user['phone'] ?? '';
    final address = user['address'] ?? '';
    final createdAt = (user['created_at'] ?? '').toString().split(' ').first;
    final isSelf = id == _currentAdminId;
    final canEdit = _canEdit(user);
    final canDel = _canDelete(user);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isSelf ? Border.all(color: Colors.blue[200]!, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID
          SizedBox(
            width: 32,
            child: Text('#$id', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: _roleColor(role).withAlpha(30),
            child: Text(username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(username,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  if (isSelf)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                      child: const Text('Bạn', style: TextStyle(fontSize: 10, color: Colors.blue)),
                    ),
                ]),
                Text(email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(children: [
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _roleColor(role),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(_roleLabel(role),
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  if (phone.isNotEmpty) ...[
                    const Icon(Icons.phone, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Text(phone, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ]),
                if (address.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                    const SizedBox(width: 2),
                    Expanded(child: Text(address,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                const SizedBox(height: 2),
                Text('Tham gia: $createdAt', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          // Actions
          Column(
            children: [
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF1565C0), size: 20),
                  onPressed: () => _openEditSheet(user),
                  tooltip: 'Chỉnh sửa',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 4),
                  child: Text('Không đủ\nquyền hạn',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                ),
              if (canDel)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[600], size: 20),
                  onPressed: () => _deleteUser(id, role, username),
                  tooltip: 'Xóa',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                )
              else if (!canEdit && role != 'super-admin')
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Text('(Ban)',
                      style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet Chỉnh sửa Người dùng ──────────────────────────────
class _EditUserSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final Dio dio;
  final VoidCallback onSaved;
  const _EditUserSheet({required this.user, required this.dio, required this.onSaved});

  @override
  State<_EditUserSheet> createState() => _EditUserSheetState();
}

class _EditUserSheetState extends State<_EditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late String _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: (widget.user['username'] ?? '').toString());
    _phoneCtrl = TextEditingController(text: (widget.user['phone'] ?? '').toString());
    _addressCtrl = TextEditingController(text: (widget.user['address'] ?? '').toString());
    _role = (widget.user['role'] ?? 'user').toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.dio.post(ApiConstants.adminUpdateUser, data: {
        'id': widget.user['id'],
        'username': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'role': _role,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Cập nhật người dùng thành công!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      widget.onSaved();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.response?.data?['error'] ?? 'Lỗi xử lý'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Chỉnh sửa Người dùng',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Email (chỉ xem)
            _label('Email (Không thể sửa)'),
            TextFormField(
              initialValue: widget.user['email'] ?? '',
              readOnly: true,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              decoration: _dec(hint: '', icon: Icons.email_outlined),
            ),
            const SizedBox(height: 12),
            // Tên
            _label('Tên đăng nhập'),
            TextFormField(
              controller: _nameCtrl,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
              decoration: _dec(hint: 'Tên hiển thị', icon: Icons.person_outline),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            // Role
            _label('Phân quyền (Role)'),
            DropdownButtonFormField<String>(
              initialValue: _role,
              onChanged: (v) { if (v != null) setState(() => _role = v); },
              decoration: _dec(hint: '', icon: Icons.shield_outlined),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('User (Thành viên)')),
                DropdownMenuItem(value: 'admin', child: Text('Admin (Quản trị viên)')),
                DropdownMenuItem(value: 'super-admin', child: Text('Super Admin')),
              ],
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            // SĐT
            _label('Số điện thoại'),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: _dec(hint: 'Số điện thoại', icon: Icons.phone_outlined),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            // Địa chỉ
            _label('Địa chỉ'),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: _dec(hint: 'Địa chỉ', icon: Icons.location_on_outlined),
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Hủy'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Lưu thay đổi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
  );

  InputDecoration _dec({required String hint, required IconData icon}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
    filled: true,
    fillColor: Colors.grey[50],
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1565C0))),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
  );
}

