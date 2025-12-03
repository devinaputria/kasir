import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kasir_kebab/services/produk_service.dart'; // Ganti dengan path app-mu
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/sidebar.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> with SingleTickerProviderStateMixin {
  final produkService = ProdukService();
  List<Map<String, dynamic>> allProducts = [];
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_filterProducts);
    loadProduk();
  }

  String getPublicUrl(String path) {
    if (path.isEmpty) return '';
    return Supabase.instance.client.storage.from('gambar').getPublicUrl(path);
  }

  Future<void> loadProduk() async {
    try {
      final data = await produkService.getAllProduk();
      if (mounted) {
        setState(() {
          allProducts = data
              .map(
                (p) => {
                  'id': p['id'],
                  'name': p['nama'],
                  'price': (p['harga'] as num).toStringAsFixed(0),
                  'image': p['gambar_url'] ?? '',
                  'category': p['kategori'] ?? 'Umum',
                  'stok': p['stok_saat_ini'] ?? 0, // FIX: Tambah stok di map
                },
              )
              .toList();
        });
        debugPrint('✅ Loaded ${allProducts.length} products');
      }
    } catch (e) {
      debugPrint('❌ Load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal load produk: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
      filtered = filtered.where((p) => p['name'].toLowerCase().contains(query)).toList();
    }

    return filtered;
  }

  void _filterProducts() {
    if (mounted) setState(() {});
  }

  Widget _buildImageWidget(String path) {
    if (path.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
      );
    }

    final publicUrl = getPublicUrl(path);
    return Image.network(
      publicUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9C00))),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
        );
      },
    );
  }

  // VALIDASI FUNGSI: Cek nama required, harga/stok numeric & required
  bool _validateForm(String nama, String hargaStr, String stokStr) {
    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama harus diisi!')));
      return false;
    }
    final double? harga = double.tryParse(hargaStr);
    if (harga == null || harga <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga harus angka positif!')));
      return false;
    }
    final int? stok = int.tryParse(stokStr);
    if (stok == null || stok < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok harus angka non-negatif!')));
      return false;
    }
    return true;
  }

  // CREATE: Add Produk
  void _showAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stokController = TextEditingController(text: '0'); // Default 0
    String selectedCategory = 'Kebab';
    Uint8List? pickedFileBytes;
    File? pickedFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Produk')),
                const SizedBox(height: 8),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: stokController,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['Kebab', 'Burger'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      if (kIsWeb) {
                        pickedFileBytes = await picked.readAsBytes();
                      } else {
                        pickedFile = File(picked.path);
                      }
                      setDialogState(() {});
                    }
                  },
                  child: const Text('Pilih Gambar (Opsional)'),
                ),
                const SizedBox(height: 8),
                // Preview
                if (pickedFileBytes != null)
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(pickedFileBytes!, height: 100, fit: BoxFit.cover))
                else if (pickedFile != null)
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(pickedFile!, height: 100, fit: BoxFit.cover))
                else
                  Container(
                    height: 100,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add_photo_alternate, color: Colors.grey, size: 50),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final nama = nameController.text.trim();
                final hargaStr = priceController.text.trim();
                final stokStr = stokController.text.trim();
                if (!_validateForm(nama, hargaStr, stokStr)) return;
                final harga = double.parse(hargaStr);
                final stok = int.parse(stokStr);
                try {
                  String? fileName;
                  if (pickedFile != null || pickedFileBytes != null) {
                    fileName = pickedFile != null
                        ? '${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.path.split('/').last}'
                        : '${DateTime.now().millisecondsSinceEpoch}.png';
                  }
                  await produkService.addProdukWithImage(
                    nama: nama,
                    harga: harga,
                    stokSaatIni: stok,
                    kategori: selectedCategory,
                    imageFile: pickedFile,
                    imageBytes: pickedFileBytes,
                    fileName: fileName,
                  );
                  await loadProduk(); // Auto refresh
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk ditambahkan!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal tambah: $e')));
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  // UPDATE: Edit Produk
  void _showEditDialog(int index) {
    final product = allProducts[index];
    final nameController = TextEditingController(text: product['name']);
    final priceController = TextEditingController(text: product['price']);
    final stokController = TextEditingController(text: product['stok'].toString()); // FIX: Load stok
    String selectedCategory = product['category'];
    Uint8List? pickedFileBytes;
    File? pickedFile;
    bool hasNewImage = false;
    bool removeImage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Produk'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Produk')),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: stokController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['Kebab', 'Burger'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setDialogState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    if (kIsWeb) pickedFileBytes = await picked.readAsBytes();
                    else pickedFile = File(picked.path);
                    setDialogState(() {
                      hasNewImage = true;
                      removeImage = false;
                    });
                  }
                },
                child: const Text('Ganti Gambar (Opsional)'),
              ),
              const SizedBox(height: 8),
              if (!hasNewImage && product['image'].isNotEmpty && !removeImage)
                TextButton.icon(
                  onPressed: () => setDialogState(() => removeImage = true),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
                ),
              if (hasNewImage)
                TextButton.icon(
                  onPressed: () => setDialogState(() {
                    hasNewImage = false;
                    pickedFileBytes = null;
                    pickedFile = null;
                    removeImage = false;
                  }),
                  icon: const Icon(Icons.cancel, color: Colors.orange),
                  label: const Text('Batal Gambar Baru', style: TextStyle(color: Colors.orange)),
                ),
              const SizedBox(height: 8),
              // Preview
              if (pickedFileBytes != null)
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(pickedFileBytes!, height: 100, fit: BoxFit.cover))
              else if (pickedFile != null)
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(pickedFile!, height: 100, fit: BoxFit.cover))
              else if (removeImage)
                Container(
                  height: 100,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                  child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.delete, color: Colors.red, size: 50),
                    Text('Gambar Dihapus', style: TextStyle(color: Colors.red)),
                  ]),
                )
              else if (product['image'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(getPublicUrl(product['image']), height: 100, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(
                    height: 100,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                  )),
                )
              else
                Container(
                  height: 100,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 50),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final nama = nameController.text.trim();
                final hargaStr = priceController.text.trim();
                final stokStr = stokController.text.trim();
                if (!_validateForm(nama, hargaStr, stokStr)) return;
                final harga = double.parse(hargaStr);
                final stok = int.parse(stokStr);
                try {
                  debugPrint(' Updating product ID: ${product['id']}'); // Debug
                  String? finalImagePath = product['image'];
                  if (removeImage) {
                    finalImagePath = null;
                    debugPrint(' Removing image in edit');
                  } else if (hasNewImage) {
                    String newFileName = pickedFile != null
                        ? '${DateTime.now().millisecondsSinceEpoch}_${pickedFile!.path.split('/').last}'
                        : '${DateTime.now().millisecondsSinceEpoch}.png';
                    if (kIsWeb && pickedFileBytes != null) {
                      final newPath = await produkService.uploadImageWeb(pickedFileBytes!, newFileName);
                      if (newPath != null) finalImagePath = newPath;
                    } else if (!kIsWeb && pickedFile != null) {
                      final newPath = await produkService.uploadImage(pickedFile!, newFileName);
                      if (newPath != null) finalImagePath = newPath;
                    }
                    if (finalImagePath == product['image']) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal upload gambar baru, gambar lama dipertahankan')),
                      );
                    }
                  }
                  await produkService.updateProduk(product['id'].toString(), {
                    'nama': nama,
                    'harga': harga,
                    'stok_saat_ini': stok, // FIX: Update stok
                    'kategori': selectedCategory,
                    'gambar_url': finalImagePath,
                  });
                  await loadProduk(); // Auto refresh
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk diupdate!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal update: $e')));
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  // DELETE: Hapus Produk
  void _showDeleteDialog(int index) {
    final product = allProducts[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text('Yakin hapus "${product['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await produkService.deleteProduk(product['id'].toString());
                await loadProduk(); // Auto refresh
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product['name']} dihapus!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7ECD3),
      appBar: AppBar(
        title: const Text("Produk", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFF9C00),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _showAddDialog),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search",
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFFF9C00),
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.orange[100]),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [Tab(text: "All"), Tab(text: "Kebab"), Tab(text: "Burger")],
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
                childAspectRatio: 0.75,
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
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4))],
                    border: Border.all(color: Colors.orange[100]!, width: 0.5),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          child: _buildImageWidget(item['image']),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF9C00)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Rp ${item['price']}",
                                    style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Stok: ${item['stok']}",
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () => _showEditDialog(globalIndex),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFFF9C00), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.edit, size: 14, color: const Color(0xFFFF9C00)),
                                          const SizedBox(width: 4),
                                          const Text("Edit", style: TextStyle(fontSize: 11, color: Color(0xFFFF9C00))),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showDeleteDialog(globalIndex),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.red, width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.delete, size: 14, color: Colors.red),
                                          const SizedBox(width: 4),
                                          const Text("Delete", style: TextStyle(fontSize: 11, color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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