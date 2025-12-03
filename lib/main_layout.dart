import 'package:flutter/material.dart';
import 'widgets/sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final String title;
  final bool showAppBar;
  final Widget? floatingActionButton; // Tambahan parameter ini untuk FAB

  const MainLayout({
    super.key,
    required this.body,
    required this.title,
    this.showAppBar = true,
    this.floatingActionButton, // Optional FAB
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              backgroundColor: const Color(0xFFFF9C00),
              foregroundColor: Colors.white,
            )
          : null,

      drawer: Sidebar(
        onMenuTap: (menu) {
          Navigator.pop(context); // tutup sidebar
          Navigator.pushReplacementNamed(context, "/$menu");
        },
      ),

      body: body,
      floatingActionButton: floatingActionButton, // Pass FAB ke Scaffold
    );
  }
}