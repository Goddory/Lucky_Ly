import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app_theme.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';


class UsersManagementScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;
  const UsersManagementScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  String _selectedFilter = 'Tất cả';
  final List<String> _filters = ['Tất cả', 'Hoạt động', 'Đã khóa', 'Quản trị'];

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(
            Uri.parse('${widget.apiBaseUrl}/api/users'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.accessToken}',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        setState(() {
          _users = List<Map<String, dynamic>>.from(data['users']);
          _isLoading = false;
        });
      } else {
        _showSnack('Lỗi lấy dữ liệu người dùng');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showSnack('Không thể kết nối đến máy chủ');
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_selectedFilter == 'Tất cả') return _users;
    if (_selectedFilter == 'Hoạt động')
      return _users
          .where((u) => u['isActive'] == true && u['role'] != 'admin')
          .toList();
    if (_selectedFilter == 'Đã khóa')
      return _users.where((u) => u['isActive'] == false).toList();
    if (_selectedFilter == 'Quản trị')
      return _users.where((u) => u['role'] == 'admin').toList();
    return _users;
  }

  Future<void> _toggleUserStatus(int index, bool newValue) async {
    final filteredUsers = _filteredUsers;
    if (index < 0 || index >= filteredUsers.length) return;

    final user = filteredUsers[index];
    if (user['role'] == 'admin') {
      _showSnack('Không thể khóa tài khoản Quản trị viên');
      return;
    }

    final userId = user['id'];
    final sourceIndex = _users.indexWhere(
      (u) => u['id']?.toString() == userId?.toString(),
    );
    if (sourceIndex == -1) {
      _showSnack('Không tìm thấy người dùng để cập nhật');
      return;
    }

    // Save previous state to revert if API fails
    final previousState = _users[sourceIndex]['isActive'];
    setState(() {
      _users[sourceIndex]['isActive'] = newValue;
    });

    try {
      final response = await http
          .put(
            Uri.parse('${widget.apiBaseUrl}/api/users/$userId/status'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.accessToken}',
            },
            body: jsonEncode({'isActive': newValue}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('API Failed');
      }
    } catch (e) {
      _showSnack('Thay đổi trạng thái thất bại');
      setState(() {
        _users[sourceIndex]['isActive'] = previousState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.bg,
      body: Column(
        children: [
          _buildHeroHeader(context),
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? Center(
                    child: const CustomLoading(size: 80),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserTile(user, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: theme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5D8).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people_alt_outlined,
                      color: Color(0xFF0EA5D8),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Quản lý Người dùng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Danh sách tài khoản & phân quyền',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final theme = AppTheme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              selected: isSelected,
              selectedColor: theme.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              showCheckmark: false,
              elevation: isSelected ? 4 : 0,
              onSelected: (bool selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, int index) {
    final theme = AppTheme.of(context);
    final bool isActive = user['isActive'];
    final bool isAdmin = user['role'] == 'admin';
    final String name = user['name'];

    return Badge(
      isLabelVisible: isAdmin,
      label: const Text('Admin', style: TextStyle(fontSize: 10)),
      backgroundColor: Colors.red,
      alignment: Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? theme.card : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? null
              : Border.all(color: Colors.red.withValues(alpha: 0.2)),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isActive
                  ? theme.primary.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              radius: 24,
              child: Text(
                name[0].toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isActive ? theme.primary : Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isActive ? theme.textDark : theme.textMuted,
                      decoration: isActive
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user['email'],
                    style: TextStyle(
                      color: isActive
                          ? theme.textMuted
                          : Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isActive,
              onChanged: isAdmin
                  ? null
                  : (val) => _toggleUserStatus(index, val),
              activeColor: const Color(0xFF10B981),
              inactiveThumbColor: Colors.red,
              inactiveTrackColor: Colors.red.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
