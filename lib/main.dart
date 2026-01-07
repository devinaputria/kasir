import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screen/login_page.dart';
import 'screen/profil_page.dart';
import 'screen/dashboard_page.dart';
import 'screen/kasir_page.dart';
import 'screen/produk_page.dart';
import 'screen/pelanggan_page.dart';
import 'screen/stok_page.dart';
import 'screen/laporan_page.dart';
import 'screen/petugas_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://tyahqyqcezoufnhurior.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR5YWhxeXFjZXpvdWZuaHVyaW9yIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyNjg4MjMsImV4cCI6MjA3Njg0NDgyM30.OY3vdSwucLl9VekVteFuAXl5mWl4yIEBkmROkQ4mMsQ",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // PENTING: mulai dari login route
      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginPage(),
        '/profil': (context) => const ProfilPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/kasir': (context) => const KasirPage(),
        '/produk': (context) => const ProdukPage(),
        '/pelanggan': (context) => const PelangganPage(),
        '/stok': (context) => const StokPage(),
        '/laporan': (context) => const LaporanPage(),
        '/petugas': (context) => const PetugasBaruPage(),
      },
    );
  }
}
