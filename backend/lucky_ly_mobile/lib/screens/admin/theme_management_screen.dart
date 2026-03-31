import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import 'package:lucky_ly_mobile/widgets/custom_loading.dart';

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

  // Khai báo bảng màu cơ bản
  static const Color primary = Color(0xFF952CB1);
  static const Color primaryContainer = Color(0xFFF1A6FF);
  static const Color tertiary = Color(0xFFBD0055);
  static const Color onSurface = Color(0xFF45274B);
  static const Color onSurfaceVariant = Color(0xFF75547A);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color outlineVariant = Color(0xFFCCA5D0);

  late final List<_ThemeOption> _themes;

  @override
  void initState() {
    super.initState();
    _themes = [
      _ThemeOption(
        type: AppThemeType.defaultTheme,
        name: 'Mặc định',
        description: 'Giao diện nguyên bản tối giản, tập trung vào hiệu suất công việc.',
        icon: Icons.smartphone,
        iconColor: primary,
        iconBgColor: const Color(0xFFFEDEFF), // surface-container-high
      ),
      _ThemeOption(
        type: AppThemeType.tet,
        name: 'Tết Nguyên Đán',
        description: 'Sắc đỏ may mắn mang không khí lễ hội truyền thống Việt Nam.',
        icon: Icons.filter_vintage,
        iconColor: Colors.red.shade600,
        iconBgColor: Colors.red.shade50,
      ),
      _ThemeOption(
        type: AppThemeType.valentine,
        name: 'Valentine',
        description: 'Không gian lãng mạn với tông màu tím-hồng tinh tế, sang trọng.',
        icon: Icons.favorite,
        iconColor: Colors.pink.shade600,
        iconBgColor: Colors.pink.shade50,
      ),
    ];

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
        content: Row(
          children: [
            Icon(isError ? Icons.error : Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final isPageLoading = !_isInitialized && provider.isSyncing;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      body: isPageLoading
          ? const Center(child: CustomLoading(size: 80))
          : Stack(
              children: [
                // 1. Decorative Floating Icons (Background)
                Positioned(
                  top: -40,
                  right: -40,
                  child: Transform.rotate(
                    angle: 0.2, // ~12 độ
                    child: Icon(Icons.auto_awesome, size: 200, color: primary.withValues(alpha: 0.03)),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.4,
                  left: -80,
                  child: Transform.rotate(
                    angle: -0.2, // ~ -12 độ
                    child: Icon(Icons.redeem, size: 240, color: tertiary.withValues(alpha: 0.03)),
                  ),
                ),

                // 2. Main Scrollable Content
                ListView(
                  padding: const EdgeInsets.only(top: 100, bottom: 60, left: 24, right: 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHeroHeader(),
                    const SizedBox(height: 32),
                    ..._themes.map((theme) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildThemeCard(theme),
                        )),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),

                // 3. Top App Bar (Glassmorphism)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                      child: Container(
                        height: MediaQuery.of(context).padding.top + 60,
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 24, right: 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          boxShadow: [
                            BoxShadow(color: onSurface.withValues(alpha: 0.06), blurRadius: 32, offset: const Offset(0, 12))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back, color: primary),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Theme Settings',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6B21A8)),
                                ),
                              ],
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryContainer, width: 2),
                                image: const DecorationImage(
                                  image: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150'), // Admin Profile Placeholder
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bỏ mock Bottom Nav vì ThemeSettings chỉ là màn hình con (Push Screen)
              ],
            ),
    );
  }

  // --- Thành phần Hero Header ---
  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: onSurface.withValues(alpha: 0.06), blurRadius: 32, offset: const Offset(0, 12))
        ],
      ),
      child: Stack(
        children: [
          // Lớp nền Gradient mờ ảo
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9333EA).withValues(alpha: 0.1), // purple-600
                    const Color(0xFFF472B6).withValues(alpha: 0.1), // pink-400
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Nội dung text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF7E22CE), Color(0xFFEC4899)], // purple-700 to pink-500
                ).createShader(bounds),
                child: const Text(
                  'Quản lý Theme',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thay đổi màu sắc hệ thống chung',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: onSurfaceVariant.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget Component: Theme Card ---
  Widget _buildThemeCard(_ThemeOption option) {
    final bool isActive = _selectedTheme == option.type;
    return GestureDetector(
      onTap: () {
        if (!_isSaving) {
          setState(() {
            _selectedTheme = option.type;
          });
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? primary.withValues(alpha: 0.5) : outlineVariant.withValues(alpha: 0.2),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(color: onSurface.withValues(alpha: 0.12), blurRadius: 32, offset: const Offset(0, 12)),
                      BoxShadow(color: primary.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 2) // Mô phỏng shadow ring
                    ]
                  : [BoxShadow(color: onSurface.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                // Theme Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: option.iconBgColor, shape: BoxShape.circle),
                  child: Icon(option.icon, color: option.iconColor, size: 32),
                ),
                const SizedBox(width: 20),
                
                // Theme Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
                      const SizedBox(height: 4),
                      Text(option.description, style: const TextStyle(fontSize: 14, color: onSurfaceVariant, height: 1.4)),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Radio / Check Indicator
                isActive
                    ? Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF9333EA), Color(0xFFF472B6)], // purple-600 to pink-400
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      )
                    : Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: outlineVariant, width: 2),
                        ),
                      ),
              ],
            ),
          ),
          
          // Badge "Đang dùng"
          if (isActive)
            Positioned(
              top: -12,
              right: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primary, primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: const Text(
                  'ĐANG CHỌN',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Thành phần Save Button ---
  Widget _buildSaveButton() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7E22CE), Color(0xFFEC4899)], // purple-700 to pink-500
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: primary.withValues(alpha: 0.25), blurRadius: 32, offset: const Offset(0, 12))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isSaving ? null : _saveTheme,
              child: Center(
                child: _isSaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        'Lưu cấu hình',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Thay đổi sẽ có hiệu lực ngay lập tức cho toàn bộ người dùng hệ thống.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: onSurfaceVariant.withValues(alpha: 0.6)),
        ),
      ],
    );
  }
}

class _ThemeOption {
  final AppThemeType type;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _ThemeOption({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}
