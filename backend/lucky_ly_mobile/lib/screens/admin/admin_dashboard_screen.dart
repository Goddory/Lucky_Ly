import 'package:flutter/material.dart';
import '../../app_theme.dart';
import 'users_management_screen.dart';
import 'statistics_screen.dart';
import 'theme_management_screen.dart';
import 'marketing_dashboard_screen.dart';

/// AdminDashboardScreen - Màn hình tổng quan cho khu vực quản trị hệ thống
/// 
/// Chức năng chính:
/// - Hiển thị hero header với trạng thái Admin
/// - Cung cấp lối vào nhanh tới các module quản trị
/// - Điều hướng sang các màn hình quản lý người dùng, thống kê, theme và marketing
/// 
/// Input:
/// - apiBaseUrl: URL gốc của backend API
/// - accessToken: JWT token của admin để truyền sang các màn hình con
/// 
/// Bố cục:
/// - Header lớn ở trên cùng
/// - Danh sách card chức năng ở phần nội dung chính
class AdminDashboardScreen extends StatelessWidget {
  /// Base URL của API server
  final String apiBaseUrl;

  /// Access token của admin để gọi API ở các màn hình con
  final String accessToken;

  /// Constructor của dashboard admin
  const AdminDashboardScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  Widget build(BuildContext context) {
    /// Lấy theme hiện tại để đồng bộ màu sắc giao diện
    final theme = AppTheme.of(context);

    return Scaffold(
      /// Nền tổng thể của màn hình
      backgroundColor: theme.bg,
      body: Column(
        children: [
          /// Phần hero header ở trên cùng
          _buildHeroHeader(context),
          Expanded(
            child: SingleChildScrollView(
              /// Padding cho khu vực danh sách card
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              /// Hiệu ứng scroll bám tự nhiên
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Tiêu đề khu vực tổng quan
                  Text(
                    'Tổng quan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Card điều hướng tới màn hình quản lý người dùng
                  _buildAdminCard(
                    context: context,
                    title: 'Quản lý Người dùng',
                    subtitle: 'Xem danh sách, khóa/mở khóa tài khoản',
                    icon: Icons.people_alt_outlined,
                    color: const Color(0xFF0EA5D8),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UsersManagementScreen(
                          apiBaseUrl: apiBaseUrl,
                          accessToken: accessToken,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Card điều hướng tới màn hình thống kê
                  _buildAdminCard(
                    context: context,
                    title: 'Báo cáo và Thống kê',
                    subtitle: 'Theo dõi lưu lượng truy cập và giao dịch',
                    icon: Icons.analytics_outlined,
                    color: const Color(0xFF10B981),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatisticsScreen(
                          apiBaseUrl: apiBaseUrl,
                          accessToken: accessToken,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Card điều hướng tới màn hình quản lý theme toàn hệ thống
                  _buildAdminCard(
                    context: context,
                    title: 'Quản lý Giao diện',
                    subtitle: 'Đổi theme toàn hệ thống cho tất cả user',
                    icon: Icons.color_lens_outlined,
                    color: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ThemeManagementScreen(
                          apiBaseUrl: apiBaseUrl,
                          accessToken: accessToken,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// Card điều hướng tới dashboard marketing
                  _buildAdminCard(
                    context: context,
                    title: 'Marketing & Khuyến mãi',
                    subtitle: 'Voucher, Flash sale, Xác thực SV, Phân cụm KH',
                    icon: Icons.campaign_outlined,
                    color: const Color(0xFFEC4899),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarketingDashboardScreen(
                          apiBaseUrl: apiBaseUrl,
                          accessToken: accessToken,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Xây dựng hero header lớn cho dashboard admin
  /// 
  /// Thành phần:
  /// - Nút back để quay về màn trước
  /// - Badge "Admin" xác nhận quyền truy cập
  /// - Icon shield và tiêu đề lớn của khu vực quản trị
  Widget _buildHeroHeader(BuildContext context) {
    final theme = AppTheme.of(context);

    return Container(
      /// Header full-width với gradient thương hiệu
      width: double.infinity,
      decoration: BoxDecoration(
        /// Gradient chính của theme
        gradient: theme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            /// Bóng đổ nhẹ để header nổi bật
            color: const Color(0xFF0EA5D8).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        /// Không cần padding dưới vì phần body sẽ tiếp nối bên dưới
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              Row(
                children: [
                  /// Nút quay lại
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        /// Nền mờ để nút back nổi trên gradient
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

                  /// Badge hiển thị vai trò Admin
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      /// Nền badge đồng nhất với header
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_user,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              /// Khối tiêu đề chính của dashboard
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// Icon shield đại diện cho khu vực quản trị
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      /// Nền trắng để icon nổi bật trên gradient
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          /// Đổ bóng nhẹ cho icon
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF0EA5D8),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),

                  /// Tiêu đề và mô tả ngắn của màn hình quản trị
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản trị hệ thống',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Theo dõi và thiết lập hoạt động Lucky Ly',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
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

  /// Xây dựng một card chức năng trên dashboard admin
  /// 
  /// Tham số:
  /// - context: BuildContext để lấy theme
  /// - title: Tiêu đề card
  /// - subtitle: Mô tả ngắn
  /// - icon: Icon đại diện cho module
  /// - color: Màu nhấn của card
  /// - onTap: Hành động điều hướng khi bấm vào card
  /// 
  /// Thiết kế:
  /// - Card bo góc lớn
  /// - Icon màu nhấn ở bên trái
  /// - Text mô tả ở giữa
  /// - Chevron bên phải gợi ý điều hướng
  Widget _buildAdminCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = AppTheme.of(context);

    return AnimatedInteractiveScale(
      /// Hiệu ứng phóng/thu khi chạm để tạo cảm giác tương tác
      onTap: onTap,
      child: Container(
        /// Padding rộng để card thoáng và dễ bấm
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          /// Màu nền card theo theme hiện tại
          color: theme.card,
          borderRadius: BorderRadius.circular(20),
          /// Shadow mềm để card nổi trên nền
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              /// Khối icon nhấn mạnh module
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                /// Nền nhạt theo màu module
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),

            /// Phần text mô tả của card
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.textLight),
          ],
        ),
      ),
    );
  }
}
