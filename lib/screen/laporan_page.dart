import 'package:flutter/material.dart';
import '../main_layout.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String kategori = "Mingguan";

  @override
  Widget build(BuildContext context) {
    return MainLayout( // Wrap dengan MainLayout untuk sidebar
      title: "Laporan Penjualan", // Title untuk AppBar oranye
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== HEADER LAPORAN =====
            const Text(
              "Kebab Yuhuu\nLaporan Penjualan",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: Color(0xFFFF9C00), // Oranye seperti Figma
              ),
            ),
            const SizedBox(height: 20),

            // ===== Dropdown kategori =====
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9C00)), // Border oranye
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Kategori Laporan",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9C00)),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: kategori,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF9C00)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF9C00), width: 2),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Mingguan",
                        child: Text("Mingguan"),
                      ),
                      DropdownMenuItem(
                        value: "Bulanan",
                        child: Text("Bulanan"),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        kategori = v!;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ===== TANGGAL FILTER =====
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF9C00)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tanggal Mulai",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9C00)),
                  ),
                  const SizedBox(height: 5),
                  _inputTanggal(),

                  const SizedBox(height: 15),
                  const Text(
                    "Tanggal Akhir",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9C00)),
                  ),
                  const SizedBox(height: 5),
                  _inputTanggal(),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9C00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Terapkan Filter", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ===== RINGKASAN LAPORAN =====
            const Text(
              "Ringkasan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9C00),
              ),
            ),
            const SizedBox(height: 10),

            _summaryBox("Periode", "11 Okt 2025 - 17 Okt 2025"),
            _summaryBox("Total Transaksi", "15 Transaksi"),
            _summaryBox("Total Penjualan", "5.300.000"),
            _summaryBox("Total Pengeluaran", "-140.000"),
            _summaryBox("Laba Bersih", "5.160.000"),

            const SizedBox(height: 20),

            // ===== LIST TRANSAKSI =====
            const Text(
              "Laporan Mingguan",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9C00),
              ),
            ),
            const SizedBox(height: 10),

            _itemTransaksi(),
            _itemTransaksi(),

            const SizedBox(height: 20),

            // ===== TOMBOL CETAK =====
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF9C00)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Cetak Struk", style: TextStyle(color: Color(0xFFFF9C00))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9C00),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Cetak Laporan", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // WIDGET INPUT TANGGAL
  Widget _inputTanggal() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9C00)),
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_month, color: Color(0xFFFF9C00)),
          SizedBox(width: 10),
          Text("Pilih Tanggal", style: TextStyle(color: Color(0xFFFF9C00))),
        ],
      ),
    );
  }

  // RINGKASAN
  Widget _summaryBox(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9C00)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9C00))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // CARD TRANSAKSI
  Widget _itemTransaksi() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9C00)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Rija", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9C00))),
          const Text("1234"),
          const Text("19.50 15 Okt 2025"),
          const SizedBox(height: 8),
          const Text("Kebab Ayam\n1 x 20.000 = 20.000"),
          const SizedBox(height: 5),
          const Text("Kebab Sosis\n1 x 15.000 = 15.000"),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Total: 33.500",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9C00),
              ),
            ),
          )
        ],
      ),
    );
  }
}