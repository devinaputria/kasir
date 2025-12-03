import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main_layout.dart';

class StokPage extends StatefulWidget {
  const StokPage({super.key});

  @override
  State<StokPage> createState() => _StokPageState();
}

class _StokPageState extends State<StokPage> {
  late final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> products = [];
  bool _isLoading = true;
  String? _selectedProduct;
  final TextEditingController _jumlahController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    final response = await supabase.from('produk').select('id, nama, stok_saat_ini');
    if (mounted) {
      setState(() {
        products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final response = await supabase.from('stok_barang').select('id_produk, riwayat_perubahan, terakhir_diedit');
    List<Map<String, dynamic>> history = [];
    for (var item in List<Map<String, dynamic>>.from(response)) {
      if (item['riwayat_perubahan'] != null && item['riwayat_perubahan'].isNotEmpty) {
        List<String> lines = item['riwayat_perubahan'].split('\n');
        String lastLine = lines.last.trim();
        RegExp reg = RegExp(r':\s*([+-]?\d+)\s+for\s+(.+)$');
        Match? match = reg.firstMatch(lastLine);
        if (match != null) {
          String change = match.group(1)!;
          String product = match.group(2)!;
          history.add({
            'product': product,
            'change': change,
            'date': item['terakhir_diedit'],
          });
        }
      }
    }
    // Sort by date descending
    history.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    return history;
  }

  Widget _buildHistoryListTile(Map<String, dynamic> h) {
    bool isAdd = h['change'].startsWith('+') || (h['change'] == '0');
    Color badgeColor = isAdd ? Colors.green : Colors.red;
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      title: Text(
        h['product'],
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          h['change'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _updateStok() async {
    if (_selectedProduct == null || _jumlahController.text.isEmpty) return;
    try {
      final prodId = int.parse(_selectedProduct!);
      final prod = products.firstWhere((p) => p['id'] == prodId);
      int currentStok = prod['stok_saat_ini'];
      int jumlah = int.parse(_jumlahController.text);
      int newStok = currentStok + jumlah;
      // Update produk
      await supabase.from('produk').update({'stok_saat_ini': newStok}).eq('id', prodId);
      // Update/insert stok_barang
      final existing = await supabase.from('stok_barang').select('*').eq('id_produk', prodId).maybeSingle();
      String sign = jumlah >= 0 ? '+' : '';
      String riwayatEntry = '${DateTime.now().toIso8601String()}: $sign$jumlah for ${prod['nama']}';
      if (existing != null) {
        String oldRiwayat = existing['riwayat_perubahan'] ?? '';
        String newRiwayat = oldRiwayat.isEmpty ? riwayatEntry : '$oldRiwayat\n$riwayatEntry';
        await supabase.from('stok_barang').update({
          'stok_barang': newStok,
          'terakhir_diedit': DateTime.now().toIso8601String(),
          'diedit_oleh': 'admin', // TODO: Replace with current user email
          'riwayat_perubahan': newRiwayat,
        }).eq('id', existing['id']);
      } else {
        await supabase.from('stok_barang').insert({
          'id_produk': prodId,
          'stok_barang': newStok,
          'terakhir_diedit': DateTime.now().toIso8601String(),
          'diedit_oleh': 'admin', // TODO: Replace with current user email
          'riwayat_perubahan': riwayatEntry,
        });
      }
      // Refresh
      await _fetchProducts();
      // Clear
      _jumlahController.clear();
      setState(() {
        _selectedProduct = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stok diupdate!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: "Manajemen Stok",
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header table
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: Text("Produk", style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Center(child: Text("Stok", style: TextStyle(fontWeight: FontWeight.bold)))),
                          ],
                        ),
                      ),
                      // Dynamic stok rows
                      ...products.map((p) => _buildStokRow(p['nama'], p['stok_saat_ini'].toString())),
                    ],
                  ),
          ),
          // Button Riwayat
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchHistory(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Dialog(child: Center(child: CircularProgressIndicator()));
                        }
                        List<Map<String, dynamic>> hist = snapshot.data ?? [];
                        List<Widget> tiles = hist.map((h) => _buildHistoryListTile(h)).toList();
                        if (tiles.isEmpty) {
                          tiles = [const ListTile(title: Text("Belum ada riwayat perubahan stok."))];
                        }
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Riwayat Perubahan Stok",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    children: tiles,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF9C00),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      "Tutup",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9C00),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Riwayat Perubahan Stok", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (products.isNotEmpty && _selectedProduct == null) {
            setState(() {
              _selectedProduct = products.first['id'].toString();
            });
          }
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Adjustment Stok Manual"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: _selectedProduct,
                    isExpanded: true,
                    items: products.map((p) => DropdownMenuItem<String>(
                      value: p['id'].toString(),
                      child: Text(p['nama']),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProduct = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _jumlahController,
                    keyboardType: TextInputType.numberWithOptions(signed: true),
                    decoration: const InputDecoration(
                      labelText: "Jumlah",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _jumlahController.clear();
                  },
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updateStok();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9C00)),
                  child: const Text("Update Stok"),
                ),
              ],
            ),
          );
        },
        backgroundColor: const Color(0xFFFF9C00),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Update Stok", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildStokRow(String produk, String stok) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(produk)),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(stok, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}