import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _customerController = TextEditingController();
  final List<Map<String, dynamic>> allProducts = List.from(sampleProducts);
  final List<Map<String, dynamic>> cart = []; // Keranjang sederhana: {'product': product, 'qty': int}
  String _paymentMethod = 'Tunai'; // Default metode bayar
  bool _kartuSelected = false; // Checkbox Kartu

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredProducts(int index) {
    switch (index) {
      case 0:
        return allProducts; // Semua (8 item)
      case 1:
        return allProducts.where((p) => p['category'] == 'Kebab').toList(); // 5 item
      case 2:
        return allProducts.where((p) => p['category'] == 'Burger').toList(); // 3 item
      default:
        return allProducts;
    }
  }

  void _addToCartWithQty(Map<String, dynamic> product) {
    final qtyController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah ${product['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Jumlah:'),
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
                setState(() {
                  // Cek kalau udah ada di cart, tambah qty
                  final existingIndex = cart.indexWhere(
                    (c) => c['product']['name'] == product['name'],
                  );
                  if (existingIndex != -1) {
                    cart[existingIndex]['qty'] = (cart[existingIndex]['qty'] as int) + qty;
                  } else {
                    cart.add({'product': product, 'qty': qty});
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product['name']} x$qty ditambahkan ke keranjang!')),
                );
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void showCartDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final subtotal = cart.fold<double>(0.0, (sum, c) {
              final product = c['product'];
              final priceStr = product['price'].toString().replaceAll('.', '');
              return sum + (double.tryParse(priceStr) ?? 0.0) * c['qty'];
            });
            final diskon = subtotal * 0.10; // 10% diskon
            final total = subtotal - diskon;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Keranjang Belanja'),
              content: SizedBox(
                width: double.maxFinite,
                height: 500, // Tinggi lebih besar biar muat semua
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Pelanggan
                    TextField(
                      controller: _customerController,
                      decoration: const InputDecoration(
                        labelText: "Nama Pelanggan",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 16),
                    // List Item
Expanded(
  child: cart.isEmpty
      ? const Center(
          child: Text(
            'Keranjang kosong',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
      : ListView.builder(
          itemCount: cart.length,
          itemBuilder: (context, index) {
            final c = cart[index];
            final item = c['product'];

            final pricePerItem =
                double.tryParse(item['price'].replaceAll('.', '')) ?? 0.0;
            final subtotalItem = pricePerItem * c['qty'];

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ICON
                  const Icon(Icons.restaurant_menu,
                      color: Color(0xFFFF9C00), size: 30),

                  const SizedBox(width: 12),

                  // NAMA & HARGA
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis, // TIDAK TURUN
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Rp ${item['price']} x ${c['qty']}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // TOMBOL + / -
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove,
                            color: Colors.orange, size: 18),
                        onPressed: () {
                          setState(() {
                            if (c['qty'] > 1) {
                              c['qty']--;
                            } else {
                              cart.removeAt(index);
                            }
                          });
                          setDialogState(() {});
                        },
                      ),

                      Text(
                        "${c['qty']}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),

                      IconButton(
                        icon: const Icon(Icons.add,
                            color: Colors.orange, size: 18),
                        onPressed: () {
                          setState(() {
                            c['qty']++;
                          });
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ),

                  // DELETE BUTTON
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        cart.removeAt(index);
                      });
                      setDialogState(() {});
                    },
                  )
                ],
              ),
            );
          },
        ),
),
                  // Subtotal, Diskon, Total
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Subtotal', style: TextStyle(fontSize: 14)),
                              Text('Rp ${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Diskon 10%', style: TextStyle(fontSize: 14)),
                              Text('- Rp ${diskon.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: Colors.green)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('Rp ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF9C00))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Metode Pembayaran
                    const Text('Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => setDialogState(() => _paymentMethod = 'Kartu'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _paymentMethod == 'Kartu' ? const Color(0xFFFF9C00) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.credit_card, color: Colors.white),
                                const SizedBox(height: 4),
                                Text('Kartu', style: TextStyle(color: _paymentMethod == 'Kartu' ? Colors.white : Colors.black)),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setDialogState(() => _paymentMethod = 'Tunai'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _paymentMethod == 'Tunai' ? const Color(0xFFFF9C00) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.attach_money, color: Colors.white), // FIX: Ganti Icons.cash ke Icons.attach_money
                                const SizedBox(height: 4),
                                Text('Tunai', style: TextStyle(color: _paymentMethod == 'Tunai' ? Colors.white : Colors.black)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9C00),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () => _showPaymentDialog(total, _paymentMethod),
                  child: const Text("Konfirmasi Pembayaran", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPaymentDialog(double total, String method) {
    final paymentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final payment = double.tryParse(paymentController.text) ?? 0.0;
            final kembalian = payment - total;
            return AlertDialog(
              title: Text('Bayar dengan $method'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total: Rp ${total.toStringAsFixed(0)}'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paymentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Jumlah Bayar",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() {}), // Update kembalian real-time
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kembalian: Rp ${kembalian < 0 ? 'Kurang ${(-kembalian).toStringAsFixed(0)}' : kembalian.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kembalian < 0 ? Colors.red : Colors.green),
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
                    if (kembalian < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bayar kurang!')),
                      );
                      return;
                    }
                    Navigator.pop(context); // Tutup payment dialog
                    _showReceiptDialog(kembalian, method); // Buka struk dialog
                  },
                  child: const Text('Bayar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showReceiptDialog(double kembalian, String method) {
    final customer = _customerController.text.isEmpty ? 'Walk-in' : _customerController.text;
    final subtotal = cart.fold<double>(0.0, (sum, c) {
      final product = c['product'];
      final priceStr = product['price'].toString().replaceAll('.', '');
      return sum + (double.tryParse(priceStr) ?? 0.0) * c['qty'];
    });
    final diskon = subtotal * 0.10;
    final total = subtotal - diskon;
    final bayar = total + kembalian; // Jumlah bayar user

    // Kode transaksi dummy (bisa ganti dengan timestamp real atau UUID dari Supabase)
    final kodeTransaksi = 'TX${DateTime.now().millisecondsSinceEpoch.toString().substring(6, 10)}';
    final tanggal = DateTime.now().toString().substring(0, 10); // Format YYYY-MM-DD

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFF8F5FF), // Lavender purple background
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Kebab Yuhuu',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kode Transaksi', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(kodeTransaksi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tanggal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(tanggal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pelanggan', style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 158, 158, 158))),
                          Text(customer, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // List Item
                ...cart.map((c) {
                  final item = c['product'];
                  final pricePerItem = double.tryParse(item['price'].toString().replaceAll('.', '')) ?? 0.0;
                  final subtotalItem = pricePerItem * c['qty'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.purple)),
                              Text('x ${c['qty']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Rp ${pricePerItem.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                            Text('Rp ${subtotalItem.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                // Subtotal, Diskon, Total, Bayar, Kembalian
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(fontSize: 14)),
                          Text('Rp ${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Diskon 10%', style: TextStyle(fontSize: 14)),
                          Text('- Rp ${diskon.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, color: Colors.green)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Rp ${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF9C00))),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Metode Pembayaran', style: TextStyle(fontSize: 14)),
                          Text(method, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Bayar', style: TextStyle(fontSize: 14)),
                          Text('Rp ${bayar.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kembalian', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text('Rp ${kembalian.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text('Terima kasih!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Logic cetak struk (bisa pake printing package atau share PDF)
                    print('Cetak struk untuk transaksi $kodeTransaksi'); // Placeholder
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Cetak Struk'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      cart.clear(); // Kosongkan cart setelah tutup
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaksi selesai!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tutup Struk'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(int index) {
    final product = allProducts[index];
    final nameController = TextEditingController(text: product['name']);
    final priceController = TextEditingController(text: product['price']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Produk', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF9C00))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nama Produk",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: "Harga",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9C00), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                setState(() {
                  allProducts[index] = {
                    "name": nameController.text,
                    "price": priceController.text,
                    "image": product['image'],
                    "category": product['category'],
                  };
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produk diupdate!')),
                );
              },
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(int index) {
    final product = allProducts[index];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Konfirmasi Hapus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text('Yakin hapus "${product['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                setState(() {
                  allProducts.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product['name']} dihapus!')),
                );
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7ECD3), // warna cream Figma
      appBar: AppBar(
        title: const Text("Kebab Yuhuu", style: TextStyle(fontWeight: FontWeight.bold)), // Match screenshot
        backgroundColor: const Color(0xFFFF9C00),
        elevation: 0, // Flat AppBar lebih modern
        leading: Builder( // Drawer icon
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [ // Cart badge di kanan
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
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${cart.fold<int>(0, (sum, c) => sum + (c['qty'] as int))}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Sidebar(
        onMenuTap: (menu) {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, "/$menu");
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            // Field "Walk-in customer" (match screenshot: rounded white box dengan icon user)
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
                        hintText: "Walk-in customer",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab kategori (match screenshot: orange buttons di bawah field)
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
                  Tab(text: "All"),
                  Tab(text: "Kebab"),
                  Tab(text: "Burger"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductGrid(_getFilteredProducts(0)), // FIX: Pass index spesifik biar All = 8 item
                  _buildProductGrid(_getFilteredProducts(1)), // Kebab = 5 item
                  _buildProductGrid(_getFilteredProducts(2)), // Burger = 3 item
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85, // Tinggi lebih proporsional biar gambar nggak kepotong
        crossAxisSpacing: 12,
        mainAxisSpacing: 15,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        final globalIndex = allProducts.indexOf(item); // Cari index global di allProducts buat edit/delete

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
            border: Border.all(color: Colors.orange[100]!, width: 0.5), // Border tipis oranye untuk aksen
          ),
          child: Column(
            children: [
              // GAMBAR PRODUK
              Expanded( // Expanded biar gambar isi ruang tersedia tanpa fixed height
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange[200]!, width: 1), // Border oranye tipis di image
                    ),
                    child: Image.asset(
                      item['image'],
                      width: double.infinity,
                      fit: BoxFit.contain, // Ganti ke BoxFit.contain biar gambar full tanpa potong
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // JUDUL
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9C00), // Aksen oranye untuk name
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 4),

              // PRICE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "Rp ${item['price']}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 6),

              // TOMBOL EDIT, DELETE, & ADD TO CART (tambah Beli biar kasir bisa langsung tambah)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  // BUTTON EDIT
                  GestureDetector(
                    onTap: () => _showEditDialog(globalIndex), // FIX: Panggil dialog edit dengan global index
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange[200]!.withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 12, color: Color(0xFFFF9C00)),
                          SizedBox(width: 2),
                          Text("Edit", style: TextStyle(fontSize: 10, color: Color(0xFFFF9C00))),
                        ],
                      ),
                    ),
                  ),

                  // BUTTON DELETE
                  GestureDetector(
                    onTap: () => _showDeleteDialog(globalIndex), // FIX: Panggil dialog delete dengan global index
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red[200]!.withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, size: 12, color: Colors.red),
                          SizedBox(width: 2),
                          Text("Delete", style: TextStyle(fontSize: 10, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),

                  // BUTTON ADD TO CART (sekarang pilih qty)
                  GestureDetector(
                    onTap: () => _addToCartWithQty(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9C00),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_shopping_cart, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text("Beli", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ================= SAMPLE DATA PRODUK (DITAMBAH 'CATEGORY') =================
final List<Map<String, dynamic>> sampleProducts = [
  {
    "name": "Kebab Sosis",
    "price": "15.000",
    "image": "assets/images/kebab_sosis.png",
    "category": "Kebab",
  },
  {
    "name": "Kebab Ayam",
    "price": "20.000",
    "image": "assets/images/kebab_ayam.png",
    "category": "Kebab",
  },
  {
    "name": "Kebab Daging",
    "price": "22.000",
    "image": "assets/images/kebab_daging.png",
    "category": "Kebab",
  },
  {
    "name": "Kebab Mini",
    "price": "15.000",
    "image": "assets/images/kebab_mini.png",
    "category": "Kebab",
  },
  {
    "name": "Kebab Sayur",
    "price": "13.000",
    "image": "assets/images/kebab_sayur.png",
    "category": "Kebab",
  },
  {
    "name": "Burger Daging",
    "price": "23.000",
    "image": "assets/images/burger_daging.png",
    "category": "Burger",
  },
  {
    "name": "Burger Ayam",
    "price": "20.000",
    "image": "assets/images/burger_ayam.png",
    "category": "Burger",
  },
  {
    "name": "Burger Spesial",
    "price": "25.000",
    "image": "assets/images/burger_spesial.png",
    "category": "Burger",
  },
];