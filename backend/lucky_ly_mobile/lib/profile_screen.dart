import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'providers/auth_provider.dart';
import 'main.dart';
import 'core/database/database_helper.dart';
import 'core/services/sync_manager.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/avaturn_screen.dart' as screens;
import 'screens/avatar_3d_screen.dart' as screens;

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

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeIn;

  late String fullName;
  late String email;
  late String username;
  late String avatarUrl;
  late String authProvider;
  late String userRole;

  bool get _isAdmin => userRole == 'admin';

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
    _fadeIn = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _entryController.forward();

    final auth = context.read<AuthProvider>();
    final userData = auth.userData ?? widget.userData;

    fullName = userData['full_name']?.toString() ?? 'User';
    email = userData['email']?.toString() ?? '';
    username = userData['username']?.toString() ?? '';
    avatarUrl = userData['avatar_url']?.toString() ?? '';
    authProvider = userData['auth_provider']?.toString() ?? 'local';
    userRole = userData['role']?.toString().toLowerCase() ?? 'user';

    fullNameController = TextEditingController(text: fullName);
    emailController = TextEditingController(text: email);
    avatarUrlController = TextEditingController(text: avatarUrl);
  }

  String _resolveCurrentUserId() {
    return widget.userData['id']?.toString() ??
        widget.userData['user_id']?.toString() ??
        '1';
  }

  Future<void> _loadLocalUser() async {
    final dbHelper = DatabaseHelper.instance;
    final user = await dbHelper.getUser(_resolveCurrentUserId());
    if (user != null) {
      if (mounted) {
        setState(() {
          fullName = user['fullName']?.toString() ?? fullName;
          email = user['email']?.toString() ?? email;
          avatarUrl = user['avatarUrl']?.toString() ?? avatarUrl;

          fullNameController.text = fullName;
          emailController.text = email;
          avatarUrlController.text = avatarUrl;
        });
      }
    }
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
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final userData = auth.userData ?? {};
        fullName = userData['full_name']?.toString() ?? fullName;
        email = userData['email']?.toString() ?? email;
        avatarUrl = userData['avatar_url']?.toString() ?? avatarUrl;
        userRole = userData['role']?.toString() ?? userRole;
        final bool isSearchable = userData['is_searchable'] == true;

        return FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              _buildStaticHeader(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _buildProfileCard(),
                    _buildInfoSection(),
                    _buildPrivacySection(isSearchable, auth),
                    _buildSettingsSection(),
                    _buildLogoutButton(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildPrivacySection(bool isSearchable, AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.visibility, color: Colors.blue),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chế độ công khai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Cho phép người khác tìm thấy bạn', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Switch(
              value: isSearchable,
              onChanged: (val) => auth.updatePrivacy(val),
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticHeader() {
    final theme = AppTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: theme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
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
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
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
              Text(
                fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
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
                  if (_isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isEditing
                          ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                          : AppTheme.of(context).primaryGradient,
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
                          isEditing
                              ? (isSaving ? 'Đang lưu...' : 'Lưu')
                              : 'Chỉnh sửa',
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
            if (_isAdmin) ...[
              _SettingsTile(
                icon: Icons.admin_panel_settings,
                label: 'Quản trị hệ thống',
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminDashboardScreen(apiBaseUrl: widget.apiBaseUrl, accessToken: widget.accessToken)),
                  );
                },
              ),
              Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            ],
            _SettingsTile(
              icon: Icons.palette_outlined,
              label: _isAdmin ? 'Quản lý giao diện hệ thống' : 'Xem giao diện hệ thống',
              color: AppTheme.of(context).primary,
              onTap: () => _showThemeBottomSheet(context),
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _SettingsTile(
              icon: Icons.lock_outline,
              label: 'Đổi mật khẩu',
              color: const Color(0xFF0EA5D8),
              onTap: _showChangePasswordSheet,
              enabled: authProvider == 'local',
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _SettingsTile(
              icon: Icons.camera_front,
              label: 'Tạo Model 3D (Avaturn)',
              color: const Color(0xFFE11D48),
              onTap: () {
                // Điều hướng tới AvaturnScreen
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const screens.AvaturnScreen(avaturnSubdomain: 'https://luckyly.avaturn.dev/')),
                );
              },
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _SettingsTile(
              icon: Icons.view_in_ar,
              label: 'Xem Model 3D của tôi',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                // Điều hướng tới Avatar3DScreen hiển thị model bằng ModelViewer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const screens.Avatar3DScreen()),
                );
              },
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _SettingsTile(
              icon: Icons.sync,
              label: 'Đồng bộ Đám mây',
              color: const Color(0xFF10B981),
              onTap: () async {
                _showSnack('Đang đồng bộ...', isError: false);
                bool success = await SyncManager.manualSync();
                if (success) {
                  // Reload user sau khi đồng bộ
                  await _loadLocalUser();
                  _showSnack('Đồng bộ thành công!', isError: false);
                } else {
                  _showSnack('Đồng bộ thất bại, hãy tải lại.');
                }
              },
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
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            ),
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

  void _showThemeBottomSheet(BuildContext context) {
    final canEditTheme = _isAdmin;
    context.read<ThemeProvider>().syncThemeFromServer(
      apiBaseUrl: widget.apiBaseUrl,
      accessToken: widget.accessToken,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canEditTheme ? 'Quản lý giao diện hệ thống' : 'Giao diện hệ thống',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      canEditTheme
                          ? 'Thay đổi sẽ áp dụng cho toàn bộ người dùng.'
                          : 'Bạn chỉ có quyền xem. Chỉ admin mới được đổi giao diện.',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (themeProvider.isSyncing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(
                          color: AppTheme.of(context).primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    _buildThemeOption(
                      context,
                      themeProvider,
                      AppThemeType.defaultTheme,
                      'Mặc định',
                      Icons.phone_android,
                      enabled: canEditTheme,
                      onTap: () => _applyGlobalTheme(ctx, themeProvider, AppThemeType.defaultTheme),
                    ),
                    _buildThemeOption(
                      context,
                      themeProvider,
                      AppThemeType.tet,
                      'Tết Nguyên Đán',
                      Icons.celebration,
                      color: Colors.red,
                      enabled: canEditTheme,
                      onTap: () => _applyGlobalTheme(ctx, themeProvider, AppThemeType.tet),
                    ),
                    _buildThemeOption(
                      context,
                      themeProvider,
                      AppThemeType.valentine,
                      'Valentine',
                      Icons.favorite,
                      color: Colors.pink,
                      enabled: canEditTheme,
                      onTap: () => _applyGlobalTheme(ctx, themeProvider, AppThemeType.valentine),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _applyGlobalTheme(
    BuildContext sheetContext,
    ThemeProvider provider,
    AppThemeType type,
  ) async {
    if (!_isAdmin) return;

    final success = await provider.updateThemeAsAdmin(
      theme: type,
      apiBaseUrl: widget.apiBaseUrl,
      accessToken: widget.accessToken,
    );

    if (!mounted) return;

    if (success) {
      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }
      _showSnack('Đã áp dụng giao diện cho toàn bộ người dùng.', isError: false);
      return;
    }

    _showSnack(provider.lastError ?? 'Không thể cập nhật giao diện lúc này.');
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider provider,
    AppThemeType type,
    String name,
    IconData icon, {
    Color? color,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    final isSelected = provider.currentTheme == type;

    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.of(context).primary),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: enabled || isSelected
              ? const Color(0xFF1E293B)
              : const Color(0xFF94A3B8),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.of(context).primary)
          : (!enabled
                ? const Icon(Icons.lock_outline, color: Color(0xFF94A3B8))
                : null),
      onTap: enabled ? onTap : null,
    );
  }

  void _showChangePasswordSheet() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool obscureCurrent = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đổi mật khẩu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: currentPasswordController,
                    label: 'Mật khẩu hiện tại',
                    obscure: obscureCurrent,
                    onToggle: () =>
                        setModalState(() => obscureCurrent = !obscureCurrent),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: newPasswordController,
                    label: 'Mật khẩu mới',
                    obscure: obscureNew,
                    onToggle: () =>
                        setModalState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    label: 'Xác nhận mật khẩu mới',
                    obscure: obscureNew,
                    onToggle: () =>
                        setModalState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final current = currentPasswordController.text;
                            final newPass = newPasswordController.text;
                            final confirm = confirmPasswordController.text;

                            if (current.isEmpty ||
                                newPass.isEmpty ||
                                confirm.isEmpty) {
                              _showSnack('Vui lòng nhập đầy đủ thông tin');
                              return;
                            }
                            if (newPass != confirm) {
                              _showSnack('Mật khẩu xác nhận không khớp');
                              return;
                            }

                            setModalState(() => isLoading = true);

                            try {
                              final navigator = Navigator.of(ctx);
                              final response = await http
                                  .put(
                                    Uri.parse(
                                      '${widget.apiBaseUrl}/api/users/me/password',
                                    ),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization':
                                          'Bearer ${widget.accessToken}',
                                    },
                                    body: jsonEncode({
                                      'currentPassword': current,
                                      'newPassword': newPass,
                                    }),
                                  )
                                  .timeout(const Duration(seconds: 15));

                              if (response.statusCode >= 200 &&
                                  response.statusCode < 300) {
                                if (!ctx.mounted) return;
                                if (navigator.canPop()) {
                                  navigator.pop();
                                }
                                _showSnack(
                                  'Đổi mật khẩu thành công. Vui lòng đăng nhập lại.',
                                  isError: false,
                                );
                                // Force logout sau khi đổi pass thành công do refresh token bị revoke
                                await Future.delayed(
                                  const Duration(seconds: 2),
                                );
                                if (mounted) {
                                  _handleLogout(force: true);
                                }
                              } else {
                                final body = jsonDecode(response.body);
                                _showSnack(
                                  body['message']?.toString() ??
                                      'Đổi mật khẩu thất bại.',
                                );
                                setModalState(() => isLoading = false);
                              }
                            } catch (e) {
                              _showSnack('Lỗi kết nối server.');
                              setModalState(() => isLoading = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Xác nhận đổi mật khẩu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0EA5D8), width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF94A3B8),
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (isSaving) return;
    setState(() => isSaving = true);

    try {
      final String currentId = _resolveCurrentUserId();
      final newFullName = fullNameController.text.trim();
      final newEmail = emailController.text.trim();
      final newAvatarUrl = avatarUrlController.text.trim();

      // Lưu offline SQLite (isSync = 0 dirty)
      final userRecord = {
        'userId': currentId,
        'fullName': newFullName,
        'email': newEmail,
        'avatarUrl': newAvatarUrl,
        'clientUpdatedAt': DateTime.now().toIso8601String(),
        'isSync': 0, // Cần được push
      };

      await DatabaseHelper.instance.insertUser(userRecord);

      setState(() {
        fullName = newFullName;
        email = newEmail;
        avatarUrl = newAvatarUrl;
        isEditing = false;
        isSaving = false;
      });

      // Update widget.userData
      widget.userData['full_name'] = fullName;
      widget.userData['email'] = email;
      widget.userData['avatar_url'] = avatarUrl;

      _showSnack(
        'Đã cập nhật lưu cục bộ. Nhấn Đồng bộ để cập nhật lên Cloud.',
        isError: false,
      );

      // Auto-trigger sync optionally
      // SyncManager.pushData();
    } catch (e) {
      _showSnack('Lưu offline thất bại: $e');
      setState(() => isSaving = false);
    }
  }

  Future<void> _handleLogout({bool force = false}) async {
    if (!force) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
    }

    context.read<AuthProvider>().logout();
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
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isError
              ? const Color(0xFF64748B)
              : const Color(0xFF10B981),
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
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF0EA5D8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFF0EA5D8),
                              width: 2,
                            ),
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
                child: Icon(
                  icon,
                  color: enabled ? color : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: enabled
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF94A3B8),
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
