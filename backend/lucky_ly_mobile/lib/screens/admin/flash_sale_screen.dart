import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FlashSaleScreen extends StatefulWidget {
  final String apiBaseUrl;
  final String accessToken;

  const FlashSaleScreen({
    super.key,
    required this.apiBaseUrl,
    required this.accessToken,
  });

  @override
  State<FlashSaleScreen> createState() => _FlashSaleScreenState();
}

class _FlashSaleScreenState extends State<FlashSaleScreen> {
  Widget build(BuildContext context) {
    return Stack(
      children: [
          // Fire Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFF512F).withValues(alpha: 0.2), const Color(0xFFDD2476).withValues(alpha: 0.1), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            top: 50, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF512F).withValues(alpha: 0.3)),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCountdownCard(),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sản phẩm Flash Sale', style: GoogleFonts.chakraPetch(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFFF512F).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                              child: Text('+ THÊM DEAL', style: GoogleFonts.chakraPetch(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFFF512F))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildProductCard('Combo Quà Tặng Yêu Thương', '85%', 85, '199.000đ', '99.000đ'),
                        const SizedBox(height: 16),
                        _buildProductCard('Hộp Nến Thơm Chill', '45%', 45, '150.000đ', '89.000đ'),
                        const SizedBox(height: 16),
                        _buildProductCard('Gấu Bông Len Handmade', '100%', 100, '250.000đ', '150.000đ', isSoldOut: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      );
  }

  Widget _buildCountdownCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFF512F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF512F).withValues(alpha: 0.4), width: 1.5),
            boxShadow: [BoxShadow(color: const Color(0xFFFF512F).withValues(alpha: 0.2), blurRadius: 20)],
          ),
          child: Column(
            children: [
              Text('THỜI GIAN KẾT THÚC SAU', style: GoogleFonts.beVietnamPro(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeBox('02'), const Text(' : ', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  _buildTimeBox('45'), const Text(' : ', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  _buildTimeBox('12'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_calendar, size: 20, color: Colors.white),
                  label: Text('Sửa khung giờ', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF512F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBox(String value) {
    return Container(
      width: 60, height: 60,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFFFF512F).withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))]),
      alignment: Alignment.center,
      child: Text(value, style: GoogleFonts.chakraPetch(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFFFF512F))),
    );
  }

  Widget _buildProductCard(String name, String percentText, int percentVal, String oldPrice, String salePrice, {bool isSoldOut = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              image: isSoldOut ? DecorationImage(image: const AssetImage('assets/images/soldout.png'), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.darken)) : null,
            ),
            child: const Icon(Icons.card_giftcard, color: Colors.white54, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(salePrice, style: GoogleFonts.chakraPetch(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFFFF512F))),
                    const SizedBox(width: 8),
                    Text(oldPrice, style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white54, decoration: TextDecoration.lineThrough)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                        child: LayoutBuilder(
                          builder: (cnt, constraints) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * (percentVal / 100),
                                decoration: BoxDecoration(
                                  color: isSoldOut ? Colors.grey : const Color(0xFFFF512F),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(isSoldOut ? 'HẾT HÀNG' : 'Đã bán $percentText', style: GoogleFonts.robotoMono(fontSize: 11, color: isSoldOut ? Colors.grey : const Color(0xFFFF512F), fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
