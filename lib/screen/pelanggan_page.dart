import 'package:flutter/material.dart';
import '../models/pelanggan_model.dart';
import '../services/pelanggan_service.dart';
import '../widgets/sidebar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PelangganPage extends StatefulWidget {
  const PelangganPage({super.key});

  @override
  State<PelangganPage> createState() => _PelangganPageState();
}

class _PelangganPageState extends State<PelangganPage> {
  final PelangganService pelangganService = PelangganService();
  List<Pelanggan> customers = [];
  RealtimeChannel? _channel;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final data = await pelangganService.getAllPelanggan();
      setState(() => customers = data);
    } catch (e) {
      _showSnack("Gagal memuat pelanggan: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = pelangganService.listenPelanggan(() => _fetchAll());
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------------------------
  // VALIDATORS
  // ---------------------------
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama pelanggan harus diisi';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Nama pelanggan minimal 2 karakter';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
      return 'Nama hanya boleh huruf dan spasi';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email opsional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor telepon harus diisi';
    }
    final trimmed = value.trim();
    if (trimmed.length < 8) {
      return 'Nomor telepon minimal 8 karakter';
    }
    final phoneRegex = RegExp(r'^\+?\d{8,15}$');
    if (!phoneRegex.hasMatch(trimmed)) {
      return 'Nomor telepon hanya boleh angka (contoh: 081234567890 atau +6281234567890)';
    }
    return null;
  }

  // ---------------------------
  // DIALOG TAMBAH / EDIT
  // ---------------------------
  void _showAddEditDialog({Pelanggan? item}) {
    final isEdit = item != null;

    final nameCtrl = TextEditingController(text: item?.nama ?? "");
    final emailCtrl = TextEditingController(text: item?.email ?? "");
    final phoneCtrl = TextEditingController(text: item?.phone ?? "");

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Edit Pelanggan" : "Tambah Pelanggan"),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nama Pelanggan",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email (Opsional)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Nomor Telepon",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: _validatePhone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) {
                _showSnack("Harap perbaiki kesalahan input");
                return;
              }

              final nama = nameCtrl.text.trim();
              final email = emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim();
              final phone = phoneCtrl.text.trim();

              Navigator.pop(context);

              try {
                if (isEdit) {
                  final updated = item.copyWith(
                    nama: nama,
                    email: email,
                    phone: phone,
                  );
                  await pelangganService.updatePelanggan(item.id!, updated);
                  _showSnack("Pelanggan berhasil diupdate");
                } else {
                  final newItem = Pelanggan(
                    nama: nama,
                    email: email,
                    phone: phone,
                  );
                  await pelangganService.addPelanggan(newItem);
                  _showSnack("Pelanggan berhasil ditambahkan");
                }
                await _fetchAll();
              } catch (e) {
                _showSnack("Gagal menyimpan: $e");
              } finally {
                nameCtrl.dispose();
                emailCtrl.dispose();
                phoneCtrl.dispose();
              }
            },
            child: Text(isEdit ? "Update" : "Tambah"),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // HAPUS
  // ---------------------------
  void _confirmDelete(Pelanggan item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus pelanggan?"),
        content: Text("Hapus ${item.nama}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await pelangganService.deletePelanggan(item.id!);
                _showSnack("Pelanggan dihapus");
                await _fetchAll();
              } catch (e) {
                _showSnack("Gagal hapus: $e");
              }
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // BUILD CARD PELANGGAN
  // ---------------------------
  Widget _buildCard(Pelanggan p) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC045),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFFFF9C00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (p.email != null && p.email!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.email!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                if (p.phone != null && p.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    p.phone!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _showAddEditDialog(item: p),
                icon: const Icon(Icons.edit, size: 20, color: Color(0xFFFF9C00)),
                tooltip: "Edit",
              ),
              IconButton(
                onPressed: () => _confirmDelete(p),
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                tooltip: "Hapus",
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // BUILD PAGE
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Pelanggan"),
        backgroundColor: const Color(0xFFFF9C00),
        foregroundColor: Colors.white,
      ),
      drawer: Sidebar(
        onMenuTap: (route) {
          Navigator.pushNamed(context, route);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
        backgroundColor: const Color(0xFFFF9C00),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9C00)))
          : RefreshIndicator(
              onRefresh: _fetchAll,
              color: const Color(0xFFFF9C00),
              child: customers.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("Belum ada pelanggan"),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: customers.length,
                      itemBuilder: (context, index) => _buildCard(customers[index]),
                    ),
            ),
    );
  }
}