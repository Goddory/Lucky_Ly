import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../app_theme.dart';
import 'flash_sale_screen.dart';

class VoucherManagementScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;

  const VoucherManagementScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<VoucherManagementScreen> createState() => _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  bool _loading = true;
  List<dynamic> _promotions = [];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse('${widget.apiBaseUrl}/api/promotions'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (res.statusCode == 200) {
        setState(() {
          _promotions = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _createPromotion() async {
    final titleCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '10');
    String discountType = 'Percent';
    String targetGroup = 'Student';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.5), width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48, height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('TẠO VOUCHER MỚI', style: GoogleFonts.chakraPetch(
                      fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFFFE512E),
                    )),
                    const SizedBox(height: 20),
                    _buildField('Tên chiến dịch', titleCtrl),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown(
                          'Loại giảm', discountType, ['Percent', 'Fixed'],
                          (v) => setSheetState(() => discountType = v!),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('Giá trị', discountCtrl, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown(
                          'Nhóm', targetGroup, ['Student', 'All'],
                          (v) => setSheetState(() => targetGroup = v!),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: _buildField('Số lượng', countCtrl, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFE512E), Color(0xFFF09819)],
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFFE512E).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))
                          ]
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            if (titleCtrl.text.isEmpty || discountCtrl.text.isEmpty) return;
                            try {
                              final res = await http.post(
                                Uri.parse('${widget.apiBaseUrl}/api/promotions'),
                                headers: {
                                  'Authorization': 'Bearer ${widget.accessToken}',
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({
                                  'title': titleCtrl.text,
                                  'discount_type': discountType,
                                  'discount_value': int.tryParse(discountCtrl.text) ?? 10,
                                  'target_group': targetGroup,
                                  'voucher_count': int.tryParse(countCtrl.text) ?? 10,
                                }),
                              );
                              if (res.statusCode == 201) {
                                Navigator.pop(ctx, true);
                              }
                            } catch (_) {}
                          },
                          child: Text('PHÁT HÀNH VOUCHER', style: GoogleFonts.chakraPetch(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    if (result == true) _loadPromotions();
  }

  Future<void> _deletePromotion(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa Voucher?', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
        content: Text('Tất cả voucher do chiến dịch này phát hành sẽ bị thu hồi và xóa hẵn.', style: GoogleFonts.beVietnamPro()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: Colors.grey.shade600))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Xóa ngay', style: GoogleFonts.beVietnamPro(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      await http.delete(
        Uri.parse('${widget.apiBaseUrl}/api/promotions/$id'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      _loadPromotions();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            top: -50, right: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          Positioned(
            bottom: 150, left: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF512F).withValues(alpha: 0.4)),
            ),
          ),

          SafeArea(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  _buildGlassAppBar(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Vouchers
                        Stack(
                          children: [
                            Column(
                              children: [
                                if (!_loading && _promotions.isNotEmpty) _buildUsageChart(),
                                Expanded(
                                  child: _loading
                                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                      : _promotions.isEmpty
                                          ? _buildEmptyState()
                                          : RefreshIndicator(
                                              color: const Color(0xFFFE512E),
                                              backgroundColor: Colors.white,
                                              onRefresh: _loadPromotions,
                                              child: ListView.builder(
                                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                                                itemCount: _promotions.length,
                                                itemBuilder: (ctx, i) => _buildPromotionCard(_promotions[i]),
                                              ),
                                            ),
                                ),
                              ],
                            ),
                            Positioned(
                              bottom: 16, right: 16,
                              child: FloatingActionButton.extended(
                                onPressed: _createPromotion,
                                backgroundColor: Colors.white,
                                elevation: 8,
                                icon: const Icon(Icons.confirmation_number, color: Color(0xFFFE512E)),
                                label: Text('TẠO VOUCHER', style: GoogleFonts.chakraPetch(color: const Color(0xFFFE512E), fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            )
                          ],
                        ),
                        
                        // Tab 2: Flash Sale
                        FlashSaleScreen(apiBaseUrl: widget.apiBaseUrl, accessToken: widget.accessToken),
                      ],
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

  Widget _buildGlassAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
                    const SizedBox(width: 8),
                    Text(
                      'KHUYẾN MÃI & GIỜ VÀNG',
                      style: GoogleFonts.chakraPetch(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Spacer(),
                    const Icon(Icons.local_fire_department, color: Colors.white),
                  ],
                ),
              ),
              TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                labelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: 'VOUCHER'),
                  Tab(text: 'FLASH SALE'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsageChart() {
    int totalIssued = 0;
    int totalUsed = 0;
    for (var p in _promotions) {
      totalIssued += int.tryParse(p['voucher_count']?.toString() ?? '0') ?? 0;
      totalUsed += int.tryParse(p['used_count']?.toString() ?? '0') ?? 0;
    }
    int unused = totalIssued - totalUsed;
    if (unused < 0) unused = 0;

    if (totalIssued == 0) return const SizedBox.shrink();

    double usedPercent = (totalUsed / totalIssued) * 100;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80, height: 80,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 24,
                startDegreeOffset: -90,
                sections: [
                  PieChartSectionData(
                    value: totalUsed.toDouble(),
                    color: Colors.greenAccent,
                    radius: 14,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: unused.toDouble(),
                    color: Colors.white.withValues(alpha: 0.4),
                    radius: 12,
                    showTitle: false,
                  ),
                ]
              )
            )
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tỉ lệ sử dụng', style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${usedPercent.toStringAsFixed(1)}%', style: GoogleFonts.chakraPetch(color: Colors.greenAccent, fontSize: 32, fontWeight: FontWeight.bold)),
                Text('$totalUsed / $totalIssued Voucher đã dùng', style: GoogleFonts.robotoMono(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.sell_outlined, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text('Chưa phát hành Voucher nào', style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Cấp phát ngay để kích cầu doanh số!', style: GoogleFonts.beVietnamPro(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promo) {
    final voucherCount = promo['voucher_count'] ?? 0;
    final usedCount = promo['used_count'] ?? 0;
    final discType = promo['discount_type'] ?? '';
    final discVal = promo['discount_value'] ?? 0;
    final discLabel = discType == 'Percent' ? 'GIẢM $discVal%' : 'GIẢM ${discVal}Đ';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), // Frosted glass light
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ticket/Voucher badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFB75E), Color(0xFFED8F03)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.deepOrange.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Text(discLabel, style: GoogleFonts.chakraPetch(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16,
                      )),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        promo['target_audience'] == 'Student' ? 'ONLY STUDENT' : 'ALL USERS',
                        style: GoogleFonts.robotoMono(
                          color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _deletePromotion(promo['id']),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(promo['name'] ?? 'Siêu Phẩm Khuyến Mãi', style: GoogleFonts.beVietnamPro(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2,
                )),
                const SizedBox(height: 16),
                
                // Progress dashed line divider
                Row(
                  children: List.generate(
                    30, (index) => Expanded(
                      child: Container(
                        color: index % 2 == 0 ? Colors.white.withValues(alpha: 0.5) : Colors.transparent,
                        height: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Stats glass row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Đã phát hành', style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_activity, size: 16, color: Colors.white),
                            const SizedBox(width: 6),
                            Text('$voucherCount VÉ', style: GoogleFonts.robotoMono(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Đã sử dụng', style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('$usedCount VÉ', style: GoogleFonts.robotoMono(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.beVietnamPro(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold)))).toList(),
      onChanged: onChanged,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.beVietnamPro(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
