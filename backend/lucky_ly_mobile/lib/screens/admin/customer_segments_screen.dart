import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import 'push_campaign_screen.dart';

class CustomerSegmentsScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;

  const CustomerSegmentsScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<CustomerSegmentsScreen> createState() => _CustomerSegmentsScreenState();
}

class _CustomerSegmentsScreenState extends State<CustomerSegmentsScreen> {
  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _loadSegments();
  }

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
    final clusters = (_data['clusters'] as List?) ?? [];
    final churnUsers = (_data['churn_users'] as List?) ?? [];
    final totalChurn = _data['total_churn'] ?? 0;
    final churnRate = _data['churn_rate'] ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          // E-commerce vibrant gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFE512E), Color(0xFFF09819), Color(0xFFFFB88C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Abstract floating glowing orbs for Liquid Glass aesthetics
          Positioned(
            top: -80, right: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          Positioned(
            top: 400, left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF512F).withValues(alpha: 0.3)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildGlassAppBar(),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : RefreshIndicator(
                          color: const Color(0xFFFE512E),
                          backgroundColor: Colors.white,
                          onRefresh: _loadSegments,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cluster section header
                                _buildSectionHeader(
                                  titleVi: 'Phân cụm K-Means',
                                  titleEn: 'K-Means Clusters',
                                  subtitle: 'Phân nhóm dựa trên chi tiêu, hoạt động, thông tin ví',
                                ),
                                const SizedBox(height: 20),
                                ...clusters.map<Widget>((c) => _buildClusterCard(c)),

                                const SizedBox(height: 32),

                                // Churn section
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSectionHeader(
                                        titleVi: 'Khách hàng rời bỏ',
                                        titleEn: 'Churn Risk',
                                        subtitle: 'Inactive >30 ngày & Ví <50k',
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.shade100.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                                      ),
                                      child: Text(
                                        '$totalChurn users · $churnRate%',
                                        style: GoogleFonts.robotoMono(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                ...churnUsers.take(20).map<Widget>((u) => _buildChurnRow(u)),

                                if (_data['message'] != null) ...[
                                  const SizedBox(height: 24),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline, color: Colors.white),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(_data['message'], style: GoogleFonts.beVietnamPro(
                                                fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600,
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
        backgroundColor: const Color(0xFF6B48FF),
        elevation: 8,
        icon: const Icon(Icons.campaign, color: Colors.white),
        label: Text('GỬI THÔNG BÁO', style: GoogleFonts.chakraPetch(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
          ),
          child: Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
              const SizedBox(width: 8),
              Text(
                'CRM & KHÁCH HÀNG',
                style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              const Icon(Icons.hub_outlined, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

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
            Container(width: 4, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(titleVi, style: GoogleFonts.chakraPetch(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
            )),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(titleEn, style: GoogleFonts.robotoMono(
            fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1.5,
          )),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: GoogleFonts.beVietnamPro(
          fontSize: 13, color: Colors.white.withValues(alpha: 0.9),
        )),
      ],
    );
  }

  Widget _buildClusterCard(Map<String, dynamic> cluster) {
    final colors = [const Color(0xFF00FFCC), const Color(0xFFFF00FF), const Color(0xFFFFB800)];
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
            color: color.withValues(alpha: 0.15), // Tinted glass
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
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
                      color: color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cluster['name'] ?? 'Cluster $idx', style: GoogleFonts.chakraPetch(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                        )),
                        const SizedBox(height: 4),
                        Text('POPULATION: ${cluster['count'] ?? 0} USERS', style: GoogleFonts.robotoMono(
                          fontSize: 11, color: Colors.white.withValues(alpha: 0.9), letterSpacing: 1.0, fontWeight: FontWeight.w600,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildMetricRow([
                _MetricItem('Chi tiêu TB', '\$${cluster['avg_spending'] ?? 0}', 'AVG SPEND'),
                _MetricItem('Tuổi TB', '${cluster['avg_age'] ?? 0}', 'AVG AGE'),
                _MetricItem('Tỷ lệ SV', '${cluster['student_pct'] ?? 0}%', 'STUDENT %'),
              ]),
              const SizedBox(height: 16),
              _buildMetricRow([
                _MetricItem('Dừng HĐ', '${cluster['avg_days_inactive'] ?? 0}d', 'INACTIVE'),
                _MetricItem('Số dư ví', '\$${cluster['avg_wallet'] ?? 0}', 'WALLET'),
                _MetricItem('Dùng Voucher', '${cluster['voucher_usage_rate'] ?? 0}%', 'VOUCHER USED'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(List<_MetricItem> items) {
    return Row(
      children: items.map((item) => Expanded(
        child: Column(
          children: [
            Text(item.value, style: GoogleFonts.chakraPetch(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
            )),
            const SizedBox(height: 4),
            Text(item.labelVi, style: GoogleFonts.beVietnamPro(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600
            ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(item.labelEn, style: GoogleFonts.robotoMono(
              fontSize: 9, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 0.5, fontWeight: FontWeight.bold,
            ), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      )).toList(),
    );
  }

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
            color: Colors.redAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: Colors.redAccent.withValues(alpha: 0.1), blurRadius: 10)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.25),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${user['user_id']}'.padLeft(2, '0'),
                  style: GoogleFonts.chakraPetch(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
                          style: GoogleFonts.chakraPetch(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        if (isStudent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: Text('STUDENT', style: GoogleFonts.robotoMono(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'INACTIVE: ${user['days_inactive']}d  |  WALLET: \$${user['wallet']}',
                      style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
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
                child: Text(user['cluster'] ?? 'CHURN', style: GoogleFonts.chakraPetch(
                  fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricItem {
  final String labelVi;
  final String value;
  final String labelEn;
  const _MetricItem(this.labelVi, this.value, this.labelEn);
}
