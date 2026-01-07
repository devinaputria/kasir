import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/sidebar.dart';
import '../services/produk_service.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});
  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage>
    with SingleTickerProviderStateMixin {
  /* -------------------------------------------------- */
  /*  D A T A   S T A T E                              */
  /* -------------------------------------------------- */
  late TabController _tabController;
  final TextEditingController _customerController = TextEditingController();
  final ProdukService _produkService = ProdukService();
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> cart = [];
  String _paymentMethod = 'Tunai';
  bool _isLoading = true;

  /* -------------------------------------------------- */
  /*  L I F E C Y C L E                                */
  /* -------------------------------------------------- */
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  /* -------------------------------------------------- */
  /*  P R O D U K   L O A D                            */
  /* -------------------------------------------------- */
  Future<void> _loadProducts() async {
    try {
      final data = await _produkService.getAllProduk();
      if (!mounted) return;
      setState(() {
        allProducts = data.map((p) {
          return {
            'id': p['id'],
            'name': p['nama'],
            'price': (p['harga'] as num).toStringAsFixed(0),
            'image': p['gambar_url'] ?? '',
            'category': p['kategori'] ?? 'Umum',
            'stok': p['stok_saat_ini'] ?? 0,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal load produk: $e')));
      setState(() => _isLoading = false);
    }
  }

  /* -------------------------------------------------- */
  /*  F I L T E R   P R O D U K                        */
  /* -------------------------------------------------- */
  List<Map<String, dynamic>> _getFilteredProducts(int index) {
    switch (index) {
      case 0:
        return allProducts;
      case 1:
        return allProducts.where((p) => p['category'] == 'Kebab').toList();
      case 2:
        return allProducts.where((p) => p['category'] == 'Burger').toList();
      default:
        return allProducts;
    }
  }

  /* -------------------------------------------------- */
  /*  K E R A N J A N G                                */
  /* -------------------------------------------------- */
  void _addToCartWithQty(Map<String, dynamic> product) {
    final qtyController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Tambah ${product['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Jumlah'),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '1'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text) ?? 1;
              if (qty > (product['stok'] ?? 0)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stok tidak cukup!')),
                );
                Navigator.pop(context);
                return;
              }
              setState(() {
                final i = cart.indexWhere(
                  (c) => c['product']['id'] == product['id'],
                );
                if (i != -1) {
                  cart[i]['qty'] += qty;
                } else {
                  cart.add({'product': product, 'qty': qty});
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product['name']} x$qty ditambahkan')),
              );
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------- */
  /*  K E R A N J A N G   D I A L O G                  */
  /* -------------------------------------------------- */
  void showCartDialog() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setDialogState) {
          final subtotal = cart.fold<double>(0, (sum, c) {
            final h = double.parse(c['product']['price'].toString());
            return sum + h * c['qty'];
          });
          final diskon = subtotal * 0.10;
          final total = subtotal - diskon;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Keranjang Belanja'),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: Column(
                children: [
                  TextField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Pelanggan',
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: cart.isEmpty
                        ? const Center(child: Text('Keranjang kosong'))
                        : ListView.builder(
                            itemCount: cart.length,
                            itemBuilder: (_, i) {
                              final c = cart[i];
                              final p = c['product'];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.fastfood,
                                      color: Color(0xFFFF9C00),
                                      size: 28,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            p['name'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Rp ${p['price']} x ${c['qty']}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () => setState(() {
                                            if (c['qty'] > 1) {
                                              c['qty']--;
                                            } else {
                                              cart.removeAt(i);
                                            }
                                            setDialogState(() {});
                                          }),
                                        ),
                                        Text('${c['qty']}'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () => setState(() {
                                            c['qty']++;
                                            setDialogState(() {});
                                          }),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () => setState(() {
                                            cart.removeAt(i);
                                            setDialogState(() {});
                                          }),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('Rp ${subtotal.toStringAsFixed(0)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Diskon 10%'),
                      Text(
                        '- Rp ${diskon.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9C00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['Tunai', 'Kartu'].map((m) {
                      final isSelected = _paymentMethod == m;
                      return GestureDetector(
                        onTap: () => setDialogState(() => _paymentMethod = m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF9C00)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                m == 'Tunai' ? Icons.money : Icons.credit_card,
                                color: Colors.white,
                              ),
                              Text(
                                m,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9C00),
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: () => _showPaymentDialog(total, _paymentMethod),
                child: const Text(
                  'Konfirmasi Pembayaran',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /* -------------------------------------------------- */
  /*  P A Y M E N T   D I A L O G                      */
  /* -------------------------------------------------- */
  void _showPaymentDialog(double total, String method) {
    final payController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) {
          final pay = double.tryParse(payController.text) ?? 0;
          final change = pay - total;
          return AlertDialog(
            title: Text('Bayar dengan $method'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total: Rp ${total.toStringAsFixed(0)}'),
                TextField(
                  controller: payController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Jumlah Bayar'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kembalian: Rp ${change < 0 ? 'Kurang ${(-change).toStringAsFixed(0)}' : change.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: change < 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (change < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pembayaran kurang!')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await _simpanTransaksi(total, change, method);
                },
                child: const Text('Bayar'),
              ),
            ],
          );
        },
      ),
    );
  }

  /* -------------------------------------------------- */
  /*  S A V E   T R A N S A C T I O N   &   S T R U K  */
  /* -------------------------------------------------- */
  Future<void> _simpanTransaksi(
    double total,
    double change,
    String method,
  ) async {
    final subtotal = cart.fold<double>(0, (sum, c) {
      final h = double.parse(c['product']['price'].toString());
      return sum + h * c['qty'];
    });
    final diskon = subtotal * 0.10;
    final customer = _customerController.text.trim().isEmpty
        ? 'Walk-in'
        : _customerController.text.trim();
    final kode = 'TX${DateTime.now().millisecondsSinceEpoch % 100000}';

    try {
      await _produkService.simpanTransaksi(
        kodeTransaksi: kode,
        namaPelanggan: customer,
        total: total,
        diskon: diskon,
        bayar: total + change,
        kembalian: change,
        metodeBayar: method,
        cart: cart,
      );

      // Langsung tampilkan struk ke user
      await _showStrukDialog(
        kode,
        customer,
        subtotal,
        diskon,
        total + change,
        change,
        method,
      );

      if (!mounted) return;
      setState(() => cart.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaksi berhasil!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal transaksi: $e')));
    }
  }

  /* -------------------------------------------------- */
  /*  S T R U K   D I A L O G  (UI PREVIEW + CETAK)     */
  /*  Tanpa menyimpan file ke folder                   */
  /* -------------------------------------------------- */
  Future<void> _showStrukDialog(
    String kode,
    String customer,
    double subtotal,
    double diskon,
    double bayar,
    double kembalian,
    String method,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Kebab Yuhuu',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Kode: $kode'),
              pw.Text('Tanggal: ${DateTime.now().toString().substring(0, 10)}'),
              pw.Text('Pelanggan: $customer'),
              pw.Divider(),
              ...cart.map((c) {
                final p = c['product'];
                final h = double.parse(p['price'].toString());
                final sub = h * c['qty'];
                final name = (p['name'] as String).replaceAll('\n', ' ');
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        '${name} x${c['qty']}',
                        maxLines: 1,
                        overflow: pw.TextOverflow.clip,
                      ),
                    ),
                    pw.Text('Rp ${sub.toStringAsFixed(0)}'),
                  ],
                );
              }).toList(),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal'),
                  pw.Text('Rp ${subtotal.toStringAsFixed(0)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Diskon 10%'),
                  pw.Text('- Rp ${diskon.toStringAsFixed(0)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Rp ${(subtotal - diskon).toStringAsFixed(0)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bayar'),
                  pw.Text('Rp ${bayar.toStringAsFixed(0)}'),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Kembalian',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'Rp ${kembalian.toStringAsFixed(0)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Center(
                child: pw.Text(
                  'Terima kasih!',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Tampilkan preview + tombol cetak/keluar
    final bytes = await pdf.save();
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Struk Transaksi'),
                centerTitle: true,
                backgroundColor: const Color(0xFFFF9C00), // ➜ ORANGE
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: PdfPreview(
                  build: (_) => bytes,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.print),
                        label: const Text('Cetak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9C00), // ➜ ORANGE
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await Printing.layoutPdf(onLayout: (_) => bytes);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share),
                        label: const Text('Bagikan'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFF9C00)),
                          foregroundColor: const Color(
                            0xFFFF9C00,
                          ), // ➜ ORANGE BORDER & TEXT
                        ),
                        onPressed: () async {
                          await Printing.sharePdf(
                            bytes: bytes,
                            filename: 'struk_$kode.pdf',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  
  }

  /* -------------------------------------------------- */
  /*  B U I L D   G R I D   P R O D U K                */
  /* -------------------------------------------------- */
  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 15,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.orange[100]!, width: 0.5),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: SizedBox(
                    height: 100, // ⬅️ SAMA PERSIS
                    width: double.infinity,
                    child: item['image'].isNotEmpty
                        ? Image.network(
                            item['image'],
                            fit: BoxFit.cover, // ⬅️ SAMA PERILAKUNYA
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9C00),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Rp ${item['price']}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _addToCartWithQty(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9C00),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_shopping_cart,
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        'Beli',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  /* -------------------------------------------------- */
  /*  B U I L D   S C A F F O L D                      */
  /* -------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7ECD3),
      appBar: AppBar(
        title: const Text(
          'Kebab Yuhuu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF9C00),
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: showCartDialog,
              ),
              if (cart.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cart.fold<int>(0, (sum, c) => sum + (c['qty'] as int))}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Sidebar(
        onMenuTap: (menu) {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/$menu');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFFFF9C00), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _customerController,
                      decoration: const InputDecoration(
                        hintText: 'Walk-in customer',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF9C00),
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.orange[100],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Kebab'),
                  Tab(text: 'Burger'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductGrid(_getFilteredProducts(0)),
                  _buildProductGrid(_getFilteredProducts(1)),
                  _buildProductGrid(_getFilteredProducts(2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
