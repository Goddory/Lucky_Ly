import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucky_ly_mobile/app_theme.dart';

class AdminUserManagementScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String accessToken;
  final String apiBaseUrl;

  const AdminUserManagementScreen({
    super.key,
    required this.userData,
    required this.accessToken,
    required this.apiBaseUrl,
  });

  @override
  _AdminUserManagementScreenState createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = ''; // '', 'ACTIVE', 'BLOCKED'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('${widget.apiBaseUrl}/api/admin/users?search=$_searchQuery&status=$_statusFilter');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _users = data['users'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _updateUserStatus(String userId, String currentStatus) async {
    final newStatus = currentStatus == 'ACTIVE' ? 'BLOCKED' : 'ACTIVE';
    String reason = '';
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text(newStatus == 'BLOCKED' ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Bạn có chắc chắn muốn ${newStatus == 'BLOCKED' ? 'khóa' : 'mở khóa'} tài khoản này không?'),
                  if (newStatus == 'BLOCKED') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Lý do khóa',
                        hintText: 'Nhập lý do (bắt buộc)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                TextButton(
                  onPressed: () {
                    if (newStatus == 'BLOCKED' && reasonController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập lý do khóa')),
                      );
                      return;
                    }
                    Navigator.pop(context, {'confirm': true, 'reason': reasonController.text.trim()});
                  },
                  child: Text(
                    newStatus == 'BLOCKED' ? 'Khóa' : 'Mở khóa',
                    style: TextStyle(color: newStatus == 'BLOCKED' ? Colors.red : Colors.green),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || result['confirm'] != true) return;
    reason = result['reason'] ?? '';

    try {
      final response = await http.put(
        Uri.parse('${widget.apiBaseUrl}/api/admin/users/$userId/status'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': newStatus, 'reason': reason}),
      );

      if (response.statusCode == 200) {
        _fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái thành công')),
        );
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Quản lý người dùng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('Không tìm thấy người dùng'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) => _buildUserCard(_users[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên, email...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        _fetchUsers();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (value) {
              setState(() => _searchQuery = value);
              _fetchUsers();
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả', ''),
                const SizedBox(width: 8),
                _buildFilterChip('Đang hoạt động', 'ACTIVE'),
                const SizedBox(width: 8),
                _buildFilterChip('Đã khóa', 'BLOCKED'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _statusFilter = value);
          _fetchUsers();
        }
      },
      selectedColor: AppTheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : AppTheme.textMuted,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    final bool isBlocked = user['status'] == 'BLOCKED';
    final bool isAdmin = user['role'] == 'ADMIN';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null ? Icon(Icons.person, color: AppTheme.primary) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['full_name'] ?? user['username'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (isAdmin)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                        child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                Text(user['email'] ?? '', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Số dư: ${user['balance'] ?? 0} ${user['currency'] ?? 'VND'}',
                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (isBlocked && user['block_reason'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lý do: ${user['block_reason']}',
                    style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
          if (!isAdmin)
            IconButton(
              icon: Icon(isBlocked ? Icons.lock_open : Icons.block, color: isBlocked ? Colors.green : Colors.red),
              onPressed: () => _updateUserStatus(user['user_id'], user['status']),
            ),
        ],
      ),
    );
  }
}
