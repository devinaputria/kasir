import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Sidebar extends StatelessWidget {
  final Function(String) onMenuTap;

  const Sidebar({super.key, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 400;

          return Container(
            width: isSmallScreen ? constraints.maxWidth * 0.8 : 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER PROFILE
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: isSmallScreen ? 25 : 28,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          child: Icon(Icons.person,
                              size: isSmallScreen ? 28 : 32,
                              color: Colors.white),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hello Devina!",
                                style: TextStyle(
                                    fontSize: isSmallScreen ? 15 : 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                "RPL Student",
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: isSmallScreen ? 11 : 13),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white30, thickness: 1),

                  // MENU LIST
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildMenuItem(context, Icons.dashboard, "Dashboard", "dashboard"),
                        _buildMenuItem(context, Icons.shopping_cart, "Kasir", "kasir"),
                        _buildMenuItem(context, Icons.inventory_2, "Produk", "produk"),
                        _buildMenuItem(context, Icons.people, "Pelanggan", "pelanggan"),
                        _buildMenuItem(context, Icons.store, "Stok", "stok"),
                        _buildMenuItem(context, Icons.receipt_long, "Laporan", "laporan"),
                        _buildMenuItem(context, Icons.badge, "Petugas", "petugas"),

                        SizedBox(height: isSmallScreen ? 8 : 10),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 15 : 18),
                          child: Text("Pengaturan",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isSmallScreen ? 11 : 13)),
                        ),

                        _buildMenuItem(context, Icons.person_outline, "Profil", "profil"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String key) {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return InkWell(
      onTap: () => _handleMenuTap(context, key),
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 10,
            vertical: isSmallScreen ? 3 : 4),
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 15,
            vertical: isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: isSmallScreen ? 20 : 22),
            SizedBox(width: isSmallScreen ? 12 : 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _handleMenuTap(BuildContext context, String key) async {
    Navigator.pop(context); // Tutup drawer

    switch (key) {
      case "dashboard":
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case "kasir":
        Navigator.pushReplacementNamed(context, '/kasir');
        break;
      case "produk":
        Navigator.pushReplacementNamed(context, '/produk');
        break;
      case "pelanggan":
        Navigator.pushReplacementNamed(context, '/pelanggan');
        break;
      case "stok":
        Navigator.pushReplacementNamed(context, '/stok');
        break;
      case "laporan":
        Navigator.pushReplacementNamed(context, '/laporan');
        break;
      case "petugas":
        Navigator.pushReplacementNamed(context, '/petugas');
        break;

      case "profil":
        Navigator.pushReplacementNamed(context, '/profil');
        break;
    }
  }
}