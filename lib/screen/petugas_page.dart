import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main_layout.dart'; // Import MainLayout-mu (yang punya drawer Sidebar)

class PetugasBaruPage extends StatefulWidget {
  const PetugasBaruPage({super.key});

  @override
  State<PetugasBaruPage> createState() => _PetugasBaruPageState();
}

class _PetugasBaruPageState extends State<PetugasBaruPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noTelpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _registerPetugas() async {
    if (_formKey.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();
        final username = _usernameController.text.trim();
        final noTelp = _noTelpController.text.trim();

        // Insert user baru ke Supabase (signUp + tambah data phone/username di table profiles)
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (response.user != null) {
          // Sukses: Insert data tambahan ke table 'profiles' atau 'petugas'
          await supabase.from('profiles').insert({
            'id': response.user!.id,
            'username': username,
            'phone': noTelp,
            'role': 'petugas', // Role default
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Petugas baru berhasil didaftarkan!')),
          );
          // Clear form
          _usernameController.clear();
          _emailController.clear();
          _noTelpController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          // Opsional: Balik ke dashboard
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } on AuthException catch (e) {
        // Error Supabase
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout( // Wrap dengan MainLayout – ini yang bikin sidebar muncul
      title: "Petugas Baru",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Username
              const Text("Username",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Username",
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Username tidak boleh kosong" : null,
              ),
              const SizedBox(height: 15),

              // Email
              const Text("Email",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email",
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Email tidak boleh kosong" : null,
              ),
              const SizedBox(height: 15),

              // Nomor Telepon
              const Text("Nomor Telepon",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              TextFormField(
                controller: _noTelpController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "Nomor Telepon",
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Nomor telepon tidak boleh kosong" : null,
              ),
              const SizedBox(height: 15),

              // Password
              const Text("Password",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Password tidak boleh kosong" : null,
              ),
              const SizedBox(height: 15),

              // Validasi Password
              const Text("Validasi Password",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Validasi Password",
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF9C00))),
                ),
                validator: (value) {
                  if (value!.isEmpty) return "Validasi password tidak boleh kosong";
                  if (value != _passwordController.text) return "Password tidak cocok";
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // Button Registration
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _registerPetugas,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9C00),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Registration",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}