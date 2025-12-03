import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kebab Yuhuu"),
        backgroundColor: const Color(0xFFFF9C00),
        foregroundColor: Colors.white,
      ),

      // ==== SIDEBAR TETAP ====
      drawer: Sidebar(
        onMenuTap: (menu) {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, "/$menu");
        },
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== STAT CARDS =====
            const Row(
              children: [
                Expanded(
                  child: Card(
                    color: Color(0xFFFFF3E0),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.trending_up, color: Color(0xFFFF9C00), size: 40),
                          SizedBox(height: 8),
                          Text("Penjualan hari", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text("Rp 500.000", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF9C00))),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Color(0xFFFFF3E0),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2, color: Color(0xFFFF9C00), size: 40),
                          SizedBox(height: 8),
                          Text("Total stok", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text("200", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF9C00))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Row(
              children: [
                Expanded(
                  child: Card(
                    color: Color(0xFFFFF3E0),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.person_add, color: Color(0xFFFF9C00), size: 40),
                          SizedBox(height: 8),
                          Text("Pelanggan baru", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text("25", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF9C00))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ===== CHART PENJUALAN =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Penjualan (7 hari terakhir)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: BarChartPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("Sen"),
                      Text("Sel"),
                      Text("Rab"),
                      Text("Kam"),
                      Text("Jum"),
                      Text("Sab"),
                      Text("Min"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== TRANSAKSI TERBARU =====
            const Text(
              "Transaksi Terbaru",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildTransactionCard("TRX-001", "Rija", "Rp 33.000"),
            _buildTransactionCard("TRX-002", "Selly", "Rp 50.000"),
            _buildTransactionCard("TRX-003", "Riko", "Rp 100.000"),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(String trx, String name, String amount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9C00),
            shape: BoxShape.circle,
          ),
          child: Text(
            trx.substring(4, 7), // TRX-001 -> 001
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(trx),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9C00))),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Custom Bar Chart Painter
class BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bars = [20, 40, 60, 30, 50, 70, 40]; // Dummy data 7 hari
    final barWidth = size.width / bars.length - 8; // Spacing
    final maxBarHeight = size.height - 20;

    for (int i = 0; i < bars.length; i++) {
      final barHeight = (bars[i] / bars.reduce((a, b) => a > b ? a : b)) * maxBarHeight;
      final bar = Rect.fromLTWH(i * (barWidth + 8) + 4, size.height - barHeight - 20, barWidth, barHeight);
      canvas.drawRect(bar, Paint()..color = const Color(0xFFFF9C00));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}