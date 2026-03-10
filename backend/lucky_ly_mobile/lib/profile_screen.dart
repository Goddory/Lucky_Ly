import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userData,
    required this.accessToken,
    required this.refreshToken,
    required this.apiBaseUrl,
  });

  final Map<String, dynamic> userData;
  final String accessToken;
  final String refreshToken;
  final String apiBaseUrl;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;

  late String fullName;
  late String email;
  late String username;
  late String avatarUrl;
  late String authProvider;

  bool isEditing = false;
  bool isSaving = false;

  late TextEditingController fullNameController;
  late TextEditingController emailController;
  late TextEditingController avatarUrlController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();

    fullName = widget.userData['full_name']?.toString() ?? 'User';
    email = widget.userData['email']?.toString() ?? '';
    username = widget.userData['username']?.toString() ?? '';
    avatarUrl = widget.userData['avatar_url']?.toString() ?? '';
    authProvider = widget.userData['auth_provider']?.toString() ?? 'local';

    fullNameController = TextEditingController(text: fullName);
    emailController = TextEditingController(text: email);
    avatarUrlController = TextEditingController(text: avatarUrl);
  }

  @override
  void dispose() {
    _entryController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(child: _buildProfileCard()),
          SliverToBoxAdapter(child: _buildInfoSection()),
          SliverToBoxAdapter(child: _buildSettingsSection()),
          SliverToBoxAdapter(child: _buildLogoutButton()),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0EA5D8), Color(0xFF19C6C4)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Avatar
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          _getInitials(fullName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              // Tên user
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              // Badge loại tài khoản
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _providerLabel(authProvider),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Thông tin cá nhân',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (isEditing) {
                      _saveProfile();
                    } else {
                      setState(() => isEditing = true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isEditing
                          ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                          : const LinearGradient(colors: [Color(0xFF0EA5D8), Color(0xFF19C6C4)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEditing ? Icons.check : Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isEditing ? (isSaving ? 'Đang lưu...' : 'Lưu') : 'Chỉnh sửa',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isEditing) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isEditing = false;
                    fullNameController.text = fullName;
                    emailController.text = email;
                    avatarUrlController.text = avatarUrl;
                  });
                },
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.person_outline,
              label: 'Tên đầy đủ',
              value: fullName,
              isEditing: isEditing,
              controller: fullNameController,
            ),
            _buildDivider(),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: email.isNotEmpty ? email : 'Chưa cập nhật',
              isEditing: isEditing && authProvider == 'local',
              controller: emailController,
            ),
            _buildDivider(),
            _InfoRow(
              icon: Icons.alternate_email,
              label: 'Username',
              value: username,
              isEditing: false,
            ),
            _buildDivider(),
            _InfoRow(
              icon: Icons.image_outlined,
              label: 'Avatar URL',
              value: avatarUrl.isNotEmpty ? 'Đã cập nhật' : 'Chưa có',
              isEditing: isEditing,
              controller: avatarUrlController,
            ),
            _buildDivider(),
            _InfoRow(
              icon: Icons.security,
              label: 'Phương thức đăng nhập',
              value: _providerLabel(authProvider),
              isEditing: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            _SettingsTile(
              icon: Icons.lock_outline,
              label: 'Đổi mật khẩu',
              color: const Color(0xFF0EA5D8),
              onTap: () => _showSnack('Chức năng đang phát triển'),
              enabled: authProvider == 'local',
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              label: 'Thông báo',
              color: const Color(0xFFF59E0B),
              onTap: () => _showSnack('Chức năng đang phát triển'),
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _SettingsTile(
              icon: Icons.help_outline,
              label: 'Trợ giúp & Hỗ trợ',
              color: const Color(0xFF10B981),
              onTap: () => _showSnack('Chức năng đang phát triển'),
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _SettingsTile(
              icon: Icons.info_outline,
              label: 'Về Lucky Ly',
              color: const Color(0xFF8B5CF6),
              onTap: () => _showSnack('Lucky Ly v1.0.0'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GestureDetector(
        onTap: _handleLogout,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Color(0xFFEF4444), size: 22),
              SizedBox(width: 10),
              Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 40, color: Colors.grey.shade100);
  }

  Future<void> _saveProfile() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    // TODO: Gọi API cập nhật thông tin user khi backend có endpoint PUT /api/users/me
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      fullName = fullNameController.text.trim();
      email = emailController.text.trim();
      avatarUrl = avatarUrlController.text.trim();
      isEditing = false;
      isSaving = false;
    });

    _showSnack('Đã cập nhật thông tin!', isError: false);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Gọi API logout
    try {
      await http.post(
        Uri.parse('${widget.apiBaseUrl}/api/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': widget.refreshToken}),
      );
    } catch (_) {
      // Logout locally dù API fail
    }

    if (!mounted) return;

    // Quay về màn hình đăng nhập
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreenWrapper()),
      (route) => false,
    );
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: isError ? const Color(0xFF64748B) : const Color(0xFF10B981),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _providerLabel(String provider) {
    switch (provider) {
      case 'facebook':
        return '🔵 Facebook';
      case 'google':
        return '🔴 Google';
      default:
        return '🔒 Email & Password';
    }
  }
}

// Row hiển thị thông tin hoặc input chỉnh sửa
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isEditing = false,
    this.controller,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isEditing;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5D8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0EA5D8), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                isEditing && controller != null
                    ? TextField(
                        controller: controller,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF0EA5D8)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF0EA5D8), width: 2),
                          ),
                        ),
                      )
                    : Text(
                        value,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Tile cho phần Settings
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (enabled ? color : Colors.grey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: enabled ? color : Colors.grey, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: enabled ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled ? const Color(0xFF94A3B8) : Colors.grey.shade300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
