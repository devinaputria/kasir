import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/sidebar.dart';
import '../services/produk_service.dart'; // sesuaikan path

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage>
    with SingleTickerProviderStateMixin {
  final ProdukService produkService = ProdukService();
  List<Map<String, dynamic>> allProducts = [];
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  /* -------------------------------------------------- */
  /*  L I F E C Y C L E  &  H E L P E R                */
  /* -------------------------------------------------- */
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_filterProducts);
    loadProduk();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadProduk() async {
    try {
      final data = await produkService.getAllProduk();
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
      });
      debugPrint('✅ Loaded ${allProducts.length} products');
    } catch (e) {
      debugPrint('❌ Load error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal load produk: $e')));
    }
  }

  void _filterProducts() => setState(() {});

  List<Map<String, dynamic>> _getFilteredProducts(int index) {
    List<Map<String, dynamic>> filtered = [];
    switch (index) {
      case 0:
        filtered = allProducts;
        break;
      case 1:
        filtered = allProducts.where((p) => p['category'] == 'Kebab').toList();
        break;
      case 2:
        filtered = allProducts.where((p) => p['category'] == 'Burger').toList();
        break;
      default:
        filtered = allProducts;
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered =
          filtered.where((p) => p['name'].toLowerCase().contains(query)).toList();
    }
    return filtered;
  }

  /* -------------------------------------------------- */
  /*  W I D G E T   B U T T O N  (E D I T / D E L)     */
  /* -------------------------------------------------- */
  Widget _editButton(int index) => InkWell(
        onTap: () => _showEditDialog(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: const Color(0xFFFF9C00)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 14, color: Color(0xFFFF9C00)),
              SizedBox(width: 4),
              Text('Edit', style: TextStyle(fontSize: 11, color: Color(0xFFFF9C00))),
            ],
          ),
        ),
      );

  Widget _deleteButton(int index) => InkWell(
        onTap: () => _showDeleteDialog(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red[50],
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete, size: 14, color: Colors.red),
              SizedBox(width: 4),
              Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red)),
            ],
          ),
        ),
      );

  /* -------------------------------------------------- */
  /*  I M A G E   W I D G E T                          */
  /* -------------------------------------------------- */
  Widget _buildImageWidget(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
      );
    }
    return Image.network(
      path,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, loadingProgress) =>
          loadingProgress == null ? child : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
      ),
    );
  }

  /* -------------------------------------------------- */
  /*  V A L I D A S I                                  */
  /* -------------------------------------------------- */
  bool _validateForm(String nama, String hargaStr, String stokStr) {
    if (nama.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nama harus diisi!')));
      return false;
    }
    final harga = double.tryParse(hargaStr);
    if (harga == null || harga <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Harga harus angka positif!')));
      return false;
    }
    final stok = int.tryParse(stokStr);
    if (stok == null || stok < 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Stok harus angka non-negatif!')));
      return false;
    }
    return true;
  }

  /* -------------------------------------------------- */
  /*  A D D   P R O D U K                              */
  /* -------------------------------------------------- */
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stokCtrl = TextEditingController(text: '0');
    String kategori = 'Kebab';

    File? pickedFile;
    Uint8List? pickedBytes;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          scrollable: true,                 // ➜ dialog otomatis pakai SingleChildScrollView
contentPadding: EdgeInsets.zero,  // ➜ kita kontrol sendiri padding-nya
          title: const Text('Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk')),
                const SizedBox(height: 8),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')),
                const SizedBox(height: 8),
                TextField(controller: stokCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: kategori,
                  items: ['Kebab', 'Burger'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => kategori = v!),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final res = await picker.pickImage(source: ImageSource.gallery);
                    if (res != null) {
                      if (kIsWeb) {
                        pickedBytes = await res.readAsBytes();
                      } else {
                        pickedFile = File(res.path);
                      }
                      setState(() {});
                    }
                  },
                  child: const Text('Pilih Gambar (Opsional)'),
                ),
                const SizedBox(height: 8),
                if (pickedBytes != null)
                  Image.memory(pickedBytes!, height: 100, fit: BoxFit.cover)
                else if (pickedFile != null)
                  Image.file(pickedFile!, height: 100, fit: BoxFit.cover)
                else
                  Container(
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.add_photo_alternate, color: Colors.grey, size: 50),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final nama = nameCtrl.text.trim();
                final hargaStr = priceCtrl.text.trim();
                final stokStr = stokCtrl.text.trim();
                if (!_validateForm(nama, hargaStr, stokStr)) return;
                final harga = double.parse(hargaStr);
                final stok = int.parse(stokStr);
                try {
                  String? fileName;
                  if (pickedFile != null || pickedBytes != null) {
                    fileName = pickedFile != null
                        ? '${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.path.split('/').last}'
                        : '${DateTime.now().millisecondsSinceEpoch}.png';
                  }
                  await produkService.addProdukWithImage(
                    nama: nama,
                    harga: harga,
                    stokSaatIni: stok,
                    kategori: kategori,
                    imageBytes: pickedBytes,
                    fileName: fileName,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Produk ditambahkan!')));
                  await loadProduk();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Gagal tambah: $e')));
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------- */
  /*  E D I T   P R O D U K                            */
  /* -------------------------------------------------- */
  void _showEditDialog(int index) {
    final product = allProducts[index];
    final nameCtrl = TextEditingController(text: product['name']);
    final priceCtrl = TextEditingController(text: product['price']);
    final stokCtrl = TextEditingController(text: product['stok'].toString());
    String kategori = product['category'];

    File? pickedFile;
    Uint8List? pickedBytes;
    bool removeImage = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Edit Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama')),
                const SizedBox(height: 8),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga')),
                const SizedBox(height: 8),
                TextField(controller: stokCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: kategori,
                  items: ['Kebab', 'Burger'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => kategori = v!),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final res = await picker.pickImage(source: ImageSource.gallery);
                    if (res != null) {
                      if (kIsWeb) {
                        pickedBytes = await res.readAsBytes();
                      } else {
                        pickedFile = File(res.path);
                      }
                      setState(() => removeImage = false);
                    }
                  },
                  child: const Text('Ganti Gambar (opsional)'),
                ),
                const SizedBox(height: 8),
                if (pickedBytes != null)
                  Image.memory(pickedBytes!, height: 100, fit: BoxFit.cover)
                else if (pickedFile != null)
                  Image.file(pickedFile!, height: 100, fit: BoxFit.cover)
                else if (!removeImage && product['image'].isNotEmpty)
                  Image.network(product['image'], height: 100, fit: BoxFit.cover)
                else
                  Container(height: 100, color: Colors.grey[300], child: const Icon(Icons.image_not_supported, color: Colors.grey)),
                TextButton(
                  onPressed: () => setState(() {
                    removeImage = true;
                    pickedFile = null;
                    pickedBytes = null;
                  }),
                  child: const Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final nama = nameCtrl.text.trim();
                final harga = double.tryParse(priceCtrl.text) ?? 0;
                final stok = int.tryParse(stokCtrl.text) ?? 0;
                if (nama.isEmpty || harga <= 0 || stok < 0) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Data tidak valid')));
                  return;
                }
                try {
                  await produkService.updateProdukWithImage(
                    id: product['id'].toString(),
                    nama: nama,
                    harga: harga,
                    stok: stok,
                    kategori: kategori,
                    imageFile: kIsWeb ? null : pickedFile,
                    imageBytes: kIsWeb ? pickedBytes : null,
                    removeImage: removeImage,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Produk di-update')));
                  await loadProduk();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Gagal update: $e')));
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  /* -------------------------------------------------- */
  /*  D E L E T E   P R O D U K                        */
  /* -------------------------------------------------- */
  void _showDeleteDialog(int index) {
    final product = allProducts[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        scrollable: true,                 // ➜ dialog otomatis pakai SingleChildScrollView
contentPadding: EdgeInsets.zero,  // ➜ kita kontrol sendiri padding-nya
        title: const Text('Konfirmasi Hapus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Yakin hapus "${product['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await produkService.deleteProduk(product['id'].toString());
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('${product['name']} dihapus!')));
                await loadProduk();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------- */
  /*  B U I L D                                        */
  /* -------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7ECD3),
      appBar: AppBar(
        title: const Text('Produk', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF9C00),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddDialog,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFF9C00)),
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    return RefreshIndicator(
      onRefresh: loadProduk,
      child: products.isEmpty
          ? const Center(child: Text('Tidak ada produk', style: TextStyle(fontSize: 16)))
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 15,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];
                final globalIndex = allProducts.indexOf(item);
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        child: SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: _buildImageWidget(item['image']),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9C00),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${item['price']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Stok: ${item['stok']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _editButton(globalIndex),
                                _deleteButton(globalIndex),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}