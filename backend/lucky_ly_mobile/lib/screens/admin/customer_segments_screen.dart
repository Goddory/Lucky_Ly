import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app_theme.dart';
import 'push_campaign_screen.dart';

/// CustomerSegmentsScreen - Màn hình CRM phân tích phân khúc khách hàng
/// 
/// Chức năng chính:
/// - Tải dữ liệu phân cụm K-Means từ backend
/// - Hiển thị danh sách cluster và các chỉ số trung bình
/// - Hiển thị danh sách khách hàng có nguy cơ rời bỏ (churn)
/// - Điều hướng sang màn hình gửi chiến dịch marketing
/// 
/// Dữ liệu đầu vào từ API thường gồm:
/// - clusters: danh sách nhóm khách hàng
/// - churn_users: danh sách user có nguy cơ churn
/// - total_churn: tổng số user churn
/// - churn_rate: tỷ lệ churn
class CustomerSegmentsScreen extends StatefulWidget {
  /// Base URL của API server
  final String apiBaseUrl;

  /// JWT token để gọi API admin
  final String accessToken;

  /// Constructor của màn hình phân khúc khách hàng
  const CustomerSegmentsScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<CustomerSegmentsScreen> createState() => _CustomerSegmentsScreenState();
}

class _CustomerSegmentsScreenState extends State<CustomerSegmentsScreen> {
  /// Cờ loading khi đang tải dữ liệu từ backend
  bool _loading = true;

  /// Dữ liệu thô trả về từ API sau khi decode JSON
  Map<String, dynamic> _data = {};

  /// Bộ màu chủ đạo dùng cho giao diện CRM
  static const Color primary = Color(0xFF952CB1);
  /// Màu nền nhấn cho các khối glass UI
  static const Color primaryContainer = Color(0xFFF1A6FF);
  /// Màu nền tổng thể
  static const Color background = Color(0xFFFFF7FB);
  /// Màu nền phụ cho các container mờ
  static const Color surfaceContainerLow = Color(0xFFFFEFFC);

  /// initState: tự động tải dữ liệu phân khúc khi màn hình mở
  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

  /// Gọi API để tải dữ liệu phân khúc khách hàng
  /// 
  /// API: GET /api/promotions/segments
  /// 
  /// Quy trình:
  /// 1. Gửi request với Authorization header
  /// 2. Nếu status 200 → decode JSON và lưu vào _data
  /// 3. Nếu lỗi → chỉ tắt loading để UI không bị kẹt
  /// 
  /// Ghi chú:
  /// - Hàm này dùng cho pull-to-refresh nữa
  /// - Không throw exception ra ngoài, chỉ setState cập nhật UI
  Future<void> _loadSegments() async {
    try {
      final res = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/promotions/segments'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _data = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    /// Tách các trường dữ liệu từ response API
    final clusters = (_data['clusters'] as List?) ?? [];
    final churnUsers = (_data['churn_users'] as List?) ?? [];
    final totalChurn = _data['total_churn'] ?? 0;
    final churnRate = _data['churn_rate'] ?? 0;

    return Scaffold(
      /// Nền tổng thể của màn hình CRM
      backgroundColor: background,
      body: Stack(
        children: [
          /// Nền gradient nhẹ tạo hiệu ứng glass/CRM dashboard
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [background, surfaceContainerLow, primaryContainer.withValues(alpha: 0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          /// Các khối tròn mờ trang trí phía trên để tạo chiều sâu
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),

          /// Khối tròn trang trí phía dưới
          Positioned(
            top: 400, left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryContainer.withValues(alpha: 0.3)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                /// Thanh app bar kính mờ ở phía trên
                _buildGlassAppBar(),
                Expanded(
                  /// Khi đang loading thì hiển thị progress indicator
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: primary))
                      : RefreshIndicator(
                          /// Kéo xuống để làm mới dữ liệu segment
                          color: primary,
                          backgroundColor: Colors.white,
                          onRefresh: _loadSegments,
                          child: SingleChildScrollView(
                            /// Cho phép scroll linh hoạt trên toàn bộ nội dung
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Phần tiêu đề phân cụm K-Means
                                _buildSectionHeader(
                                  titleVi: 'Phân cụm K-Means',
                                  titleEn: 'K-Means Clusters',
                                  subtitle: 'Phân nhóm dựa trên chi tiêu, hoạt động, thông tin ví',
                                ),
                                const SizedBox(height: 20),

                                /// Render từng cluster card từ danh sách clusters
                                ...clusters.map<Widget>((c) => _buildClusterCard(c)),

                                const SizedBox(height: 32),

                                /// Khu vực hiển thị khách hàng có nguy cơ rời bỏ
                                Row(
                                  children: [
                                    Expanded(
                                      /// Header của khu vực churn
                                      child: _buildSectionHeader(
                                        titleVi: 'Khách hàng rời bỏ',
                                        titleEn: 'Churn Risk',
                                        subtitle: 'Inactive >30 ngày & Ví <50k',
                                      ),
                                    ),

                                    /// Badge hiển thị tổng số churn và tỷ lệ churn
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.shade100.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                                      ),
                                      child: Text(
                                        '$totalChurn users · $churnRate%',
                                        style: const TextStyle(
                                          fontFamily: 'PlusJakartaSans',
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                /// Chỉ hiển thị tối đa 20 user churn đầu tiên
                                ...churnUsers.take(20).map<Widget>((u) => _buildChurnRow(u)),

                                /// Thông báo thêm từ backend nếu có
                                if (_data['message'] != null) ...[
                                  const SizedBox(height: 24),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      /// Hiệu ứng kính mờ cho message box
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline, color: primary),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(_data['message'], style: const TextStyle(
                                                fontFamily: 'PlusJakartaSans',
                                                fontSize: 13, color: primary, fontWeight: FontWeight.w600,
                                              )),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),

      /// Nút nổi để điều hướng sang màn hình gửi chiến dịch
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PushCampaignScreen(
                apiBaseUrl: widget.apiBaseUrl,
                accessToken: widget.accessToken,
              ),
            ),
          );
        },
        backgroundColor: primary,
        elevation: 8,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: const Text('GỬI THÔNG BÁO', style: TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  /// Xây dựng app bar kính mờ cho màn hình CRM
  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        /// Làm mờ background phía sau để tạo hiệu ứng glass
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: primary)),
              const SizedBox(width: 8),
              const Text(
                'CRM & KHÁCH HÀNG',
                style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.bold, color: primary),
              ),
              const Spacer(),
              const Icon(Icons.hub_outlined, color: primary),
            ],
          ),
        ),
      ),
    );
  }

  /// Xây dựng tiêu đề cho từng section
  /// 
  /// Dùng cho cả phần K-Means và Churn Risk
  Widget _buildSectionHeader({
    required String titleVi,
    required String titleEn,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 4, height: 24, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(titleVi, style: const TextStyle(
              fontFamily: 'PlusJakartaSans', fontSize: 20, fontWeight: FontWeight.bold, color: primary,
            )),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(titleEn, style: const TextStyle(
            fontFamily: 'PlusJakartaSans', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 1.5,
          )),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(
          fontFamily: 'PlusJakartaSans', fontSize: 13, color: Colors.black87,
        )),
      ],
    );
  }

  /// Xây dựng card hiển thị một cluster khách hàng
  /// 
  /// Dữ liệu cluster thường gồm:
  /// - id, name, count
  /// - avg_spending, avg_age, student_pct
  /// - avg_days_inactive, avg_wallet, voucher_usage_rate
  /// 
  /// Mỗi cluster dùng màu và icon khác nhau để dễ phân biệt
  Widget _buildClusterCard(Map<String, dynamic> cluster) {
    final colors = [primary, const Color(0xFF6366F1), const Color(0xFF14B8A6)];
    final icons = [Icons.memory, Icons.data_usage, Icons.timeline];
    final idx = cluster['id'] ?? 0;
    final color = colors[idx % colors.length];
    final icon = icons[idx % icons.length];

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6), // Tinted glass
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cluster['name'] ?? 'Cluster $idx', style: TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 18, fontWeight: FontWeight.bold, color: color,
                        )),
                        const SizedBox(height: 4),
                        Text('POPULATION: ${cluster['count'] ?? 0} USERS', style: const TextStyle(
                          fontFamily: 'PlusJakartaSans', fontSize: 11, color: Colors.black54, letterSpacing: 1.0, fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildMetricRow([
                _MetricItem('Chi tiêu TB', '\$${cluster['avg_spending'] ?? 0}', 'AVG SPEND', color),
                _MetricItem('Tuổi TB', '${cluster['avg_age'] ?? 0}', 'AVG AGE', color),
                _MetricItem('Tỷ lệ SV', '${cluster['student_pct'] ?? 0}%', 'STUDENT %', color),
              ]),
              const SizedBox(height: 16),
              _buildMetricRow([
                _MetricItem('Dừng HĐ', '${cluster['avg_days_inactive'] ?? 0}d', 'INACTIVE', color),
                _MetricItem('Số dư ví', '\$${cluster['avg_wallet'] ?? 0}', 'WALLET', color),
                _MetricItem('Dùng Voucher', '${cluster['voucher_usage_rate'] ?? 0}%', 'VOUCHER USED', color),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  /// Hiển thị một hàng metrics gồm nhiều chỉ số của cluster
  /// 
  /// Dùng để trình bày:
  /// - Giá trị chính (value)
  /// - Nhãn tiếng Việt (labelVi)
  /// - Nhãn tiếng Anh (labelEn)
  Widget _buildMetricRow(List<_MetricItem> items) {
    return Row(
      children: items.map((item) => Expanded(
        child: Column(
          children: [
            Text(item.value, style: TextStyle(
              fontFamily: 'PlusJakartaSans', fontSize: 20, fontWeight: FontWeight.bold, color: item.color,
            )),
            const SizedBox(height: 4),
            Text(item.labelVi, style: const TextStyle(
              fontFamily: 'PlusJakartaSans', fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600
            ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(item.labelEn, style: const TextStyle(
              fontFamily: 'PlusJakartaSans', fontSize: 9, color: Colors.black54, letterSpacing: 0.5, fontWeight: FontWeight.bold,
            ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      )).toList(),
    );
  }

  /// Xây dựng một dòng trong danh sách khách hàng churn
  /// 
  /// Mỗi row hiển thị:
  /// - User ID
  /// - Tag STUDENT nếu là sinh viên
  /// - Số ngày inactive và số dư ví
  /// - Nhãn cluster/churn ở bên phải
  Widget _buildChurnRow(Map<String, dynamic> user) {
    final bool isStudent = user['is_student'] == true;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: Colors.redAccent.withValues(alpha: 0.05), blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${user['user_id']}'.padLeft(2, '0'),
                  style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'USER_${user['user_id']}',
                          style: const TextStyle(fontFamily: 'PlusJakartaSans', fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        const SizedBox(width: 8),
                        if (isStudent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                            ),
                            child: const Text('STUDENT', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 8, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'INACTIVE: ${user['days_inactive']}d  |  WALLET: \$${user['wallet']}',
                      style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(user['cluster'] ?? 'CHURN', style: const TextStyle(
                  fontFamily: 'PlusJakartaSans', fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model nhỏ để lưu một metric trong cluster card
/// 
/// Bao gồm:
/// - labelVi: nhãn tiếng Việt
/// - value: giá trị hiển thị
/// - labelEn: nhãn tiếng Anh
/// - color: màu nhấn cho giá trị
class _MetricItem {
  final String labelVi;
  final String value;
  final String labelEn;
  final Color color;
  const _MetricItem(this.labelVi, this.value, this.labelEn, this.color);
}
