import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  @override
  void initState() {
    super.initState();
    // Đợi frame đầu tiên hoàn tất rồi mới gọi provider để tránh lấy context quá sớm.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchRevenue();
      context.read<StoreProvider>().fetchOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy dữ liệu doanh thu và tổng quan từ StoreProvider để render toàn bộ màn hình.
    final store = context.watch<StoreProvider>();
    final revenueData = store.revenueData;
    final overview = store.overview;
    final totalRevenue = overview?['totalRevenue']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF5F8),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildGlassAppBar(context),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(totalRevenue),
                      const SizedBox(height: 24),
                      _buildLuminousWalletCard(totalRevenue),
                      const SizedBox(height: 24),
                      _buildGrowthChartSection(revenueData),
                      const SizedBox(height: 24),
                      _buildTransactionHistory(revenueData),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildGlassAppBar(BuildContext context) {
    // Thanh app bar có hiệu ứng kính mờ để phù hợp phong cách dashboard.
    return SliverAppBar(
      backgroundColor: const Color(0xFFFBF5F8).withOpacity(0.8),
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF8F2BAD)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Insights',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.bold,
          color: Color(0xFF8F2BAD),
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE37CFF), width: 2),
            ),
            child: const Icon(Icons.person, color: Color(0xFF8F2BAD)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection(String revenue) {
    // Khối tiêu đề lớn dùng để nhấn mạnh ngữ cảnh doanh thu của màn hình.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TỔNG QUAN TÀI CHÍNH',
          style: TextStyle(
            color: Color(0xFFB70049),
            fontWeight: FontWeight.w600,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Doanh thu',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF302E30),
                letterSpacing: -1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE37CFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.trending_up, color: Color(0xFF8F2BAD), size: 16),
                  SizedBox(width: 4),
                  Text(
                    '+12.5%',
                    style: TextStyle(color: Color(0xFF8F2BAD), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLuminousWalletCard(String balance) {
    // Card số dư chính, dùng gradient và bóng đổ để tạo điểm nhấn thị giác.
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8F2BAD), Color(0xFF811A9F)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F2BAD).withOpacity(0.15),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SỐ DƯ HIỆN TẠI',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$balance đ',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans'),
                      ),
                    ],
                  ),
                  Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8), size: 36),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF8F2BAD),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 4,
                      ),
                      child: const Text('Rút tiền', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onPressed: () {},
                    ),
                  )
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthChartSection(List<dynamic> data) {
    // Khu vực biểu đồ tăng trưởng theo thời gian.
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: const Color(0xFF302E30).withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biểu đồ tăng trưởng', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildChartToggleBtn('Tuần', false),
                  const SizedBox(width: 8),
                  _buildChartToggleBtn('Tháng', true),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: ChartPainter(data),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChartLabel('T2'), _ChartLabel('T3'), _ChartLabel('T4'),
              _ChartLabel('T5'), _ChartLabel('T6'), _ChartLabel('T7'), _ChartLabel('CN'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartToggleBtn(String label, bool isActive) {
    // Nút chọn phạm vi dữ liệu cho biểu đồ, hiện tại chỉ mô phỏng trạng thái active.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE37CFF) : const Color(0xFFECE6EA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? const Color(0xFF47005B) : const Color(0xFF5E5B5D),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTransactionHistory(List<dynamic> data) {
    // Danh sách các giao dịch gần nhất, giới hạn hiển thị 5 bản ghi.
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Lịch sử giao dịch', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: const Text('Xem tất cả', style: TextStyle(color: Color(0xFF8F2BAD), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.isEmpty)
           const Center(child: Padding(
             padding: EdgeInsets.all(16.0),
             child: Text('Chưa có lịch sử giao dịch', style: TextStyle(color: Colors.grey)),
           ))
        else
          ...data.take(5).map((item) {
            final id = item['id']?.toString() ?? '0000';
            final date = item['created_at']?.toString().substring(0, 10) ?? '';
            final amount = item['amount']?.toString() ?? '0';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTransactionCard('#$id', date, '+$amountđ'),
            );
          }),
      ],
    );
  }

  Widget _buildTransactionCard(String orderId, String date, String amount) {
    // Một dòng giao dịch riêng lẻ với mã đơn, ngày và số tiền.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFF302E30).withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC2CA).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_bag, color: Color(0xFFB70049)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đơn hàng $orderId', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(color: const Color(0xFF5E5B5D).withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_circle, color: Color(0xFF2BAD6B), size: 14),
                  const SizedBox(width: 2),
                  Text(amount, style: const TextStyle(color: Color(0xFF2BAD6B), fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 4),
              Text('HOÀN TẤT', style: TextStyle(color: const Color(0xFF5E5B5D).withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            ],
          )
        ],
      ),
    );
  }

}

class _ChartLabel extends StatelessWidget {
  final String text;
  const _ChartLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF5E5B5D).withOpacity(0.5),
        letterSpacing: 1,
      ),
    );
  }
}

class ChartPainter extends CustomPainter {
  final List<dynamic> data;
  ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    // Không có dữ liệu thì không cần vẽ gì.
    if (data.isEmpty) return;

    // scaleX chia đều các điểm theo chiều ngang.
    final scaleX = size.width / (data.length > 1 ? (data.length - 1) : 1);
    
    // Tìm giá trị lớn nhất để quy đổi dữ liệu sang trục Y của canvas.
    double maxAmount = 0;
    for (var item in data) {
      double amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
      if (amt > maxAmount) maxAmount = amt;
    }
    if (maxAmount == 0) maxAmount = 1;
    
    final scaleY = (size.height - 20) / maxAmount;

    final path = Path();
    
    // Vẽ đường biểu diễn doanh thu theo từng mốc dữ liệu.
    for (int i = 0; i < data.length; i++) {
      double amt = double.tryParse(data[i]['amount']?.toString() ?? '0') ?? 0;
      double x = i * scaleX;
      double y = size.height - (amt * scaleY);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Dùng cubicTo để đường cong mượt hơn thay vì nối thẳng từng điểm.
        double prevAmt = double.tryParse(data[i-1]['amount']?.toString() ?? '0') ?? 0;
        double prevX = (i-1) * scaleX;
        double prevY = size.height - (prevAmt * scaleY);
        
        path.cubicTo(
          (prevX + x) / 2, prevY,
          (prevX + x) / 2, y,
          x, y
        );
      }
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Lớp nền gradient dưới đường biểu đồ.
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE37CFF).withOpacity(0.3),
          const Color(0xFFE37CFF).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, gradientPaint);

    // Đường chính của biểu đồ.
    final linePaint = Paint()
      ..color = const Color(0xFF8F2BAD)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    canvas.drawPath(path, linePaint);

          // Đánh dấu điểm dữ liệu cuối cùng để người dùng dễ đọc xu hướng hiện tại.
    if (data.isNotEmpty) {
      double lastAmt = double.tryParse(data.last['amount']?.toString() ?? '0') ?? 0;
      final dotCenter = Offset(size.width, size.height - (lastAmt * scaleY));
      
      final dotPaint = Paint()..color = const Color(0xFF8F2BAD);
      final dotBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
        
      canvas.drawCircle(dotCenter, 6, dotPaint);
      canvas.drawCircle(dotCenter, 6, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
