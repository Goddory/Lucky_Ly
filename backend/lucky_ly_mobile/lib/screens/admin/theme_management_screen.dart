import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../providers/theme_provider.dart';

class ThemeManagementScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;

  const ThemeManagementScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<ThemeManagementScreen> createState() => _ThemeManagementScreenState();
}

class _ThemeManagementScreenState extends State<ThemeManagementScreen> {
  AppThemeType _selectedTheme = AppThemeType.defaultTheme;
  bool _isInitialized = false;
  bool _isSaving = false;

  final List<_ThemeOption> _themes = const [
    _ThemeOption(
      type: AppThemeType.defaultTheme,
      name: 'Mặc định',
      description: 'Theme xanh premium mặc định của ứng dụng.',
      colors: [Color(0xFF008D9A), Color(0xFF005A64)],
      icon: Icons.phone_android,
    ),
    _ThemeOption(
      type: AppThemeType.tet,
      name: 'Tết Nguyên Đán',
      description: 'Sắc đỏ may mắn và vàng tài lộc.',
      colors: [Color(0xFFDC2626), Color(0xFFFBBF24)],
      icon: Icons.celebration,
    ),
    _ThemeOption(
      type: AppThemeType.valentine,
      name: 'Valentine',
      description: 'Gam hồng tím dành cho dịp lễ tình nhân.',
      colors: [Color(0xFFE84393), Color(0xFF9B59B6)],
      icon: Icons.favorite,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncInitialTheme();
    });
  }

  Future<void> _syncInitialTheme() async {
    final provider = context.read<ThemeProvider>();
    await provider.syncThemeFromServer(
      apiBaseUrl: widget.apiBaseUrl,
      accessToken: widget.accessToken,
    );

    if (!mounted) return;
    setState(() {
      _selectedTheme = provider.currentTheme;
      _isInitialized = true;
    });
  }

  Future<void> _saveTheme() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    final provider = context.read<ThemeProvider>();
    final success = await provider.updateThemeAsAdmin(
      theme: _selectedTheme,
      apiBaseUrl: widget.apiBaseUrl,
      accessToken: widget.accessToken,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _showSnack('Đã cập nhật theme hệ thống cho toàn bộ người dùng.', false);
      Navigator.pop(context);
      return;
    }

    _showSnack(provider.lastError ?? 'Không thể cập nhật theme lúc này.', true);
  }

  void _showSnack(String message, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = AppTheme.of(context);
    final provider = context.watch<ThemeProvider>();

    if (!_isInitialized && provider.isSyncing) {
      return Scaffold(
        backgroundColor: appTheme.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: appTheme.bg,
      body: Column(
        children: [
          _buildHeroHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              children: [
                Text(
                  'Chọn Theme Hệ thống',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: appTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thay đổi sẽ áp dụng cho toàn bộ người dùng khi đồng bộ theme.',
                  style: TextStyle(color: appTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ..._themes.map((theme) => _buildThemeCard(theme, appTheme)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveTheme,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: appTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Lưu cấu hình',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final appTheme = AppTheme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: appTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.primary.withValues(alpha: 0.3),
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
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _HeaderIconBubble(),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản lý Theme',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Thay đổi màu sắc hệ thống chung',
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

  Widget _buildThemeCard(_ThemeOption option, AppTheme appTheme) {
    final isSelected = _selectedTheme == option.type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = option.type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? appTheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? AppTheme.glowShadow(appTheme.primary)
              : AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: option.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(option.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? appTheme.primary : appTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: TextStyle(fontSize: 12, color: appTheme.textMuted),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: appTheme.primary, size: 28)
            else
              Icon(Icons.circle_outlined, color: appTheme.divider, size: 28),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  final AppThemeType type;
  final String name;
  final String description;
  final List<Color> colors;
  final IconData icon;

  const _ThemeOption({
    required this.type,
    required this.name,
    required this.description,
    required this.colors,
    required this.icon,
  });
}

class _HeaderIconBubble extends StatelessWidget {
  const _HeaderIconBubble();

  @override
  Widget build(BuildContext context) {
    return Container(
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
        Icons.color_lens_outlined,
        color: Color(0xFFF59E0B),
        size: 32,
      ),
    );
  }
}
