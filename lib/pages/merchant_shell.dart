// lib/pages/merchant_shell.dart
import 'package:flutter/material.dart';

import 'merchant_orders_page.dart';
import 'merchant_profile_page.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key});

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  static const Color kBrandBlue = Color(0xFF1F41BB);

  int selectedNav = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedNav,
        children: const [
          MerchantOrdersPage(),
          _PlaceholderPage(title: "Menu (Coming soon)"),
          _PlaceholderPage(title: "Analytics (Coming soon)"),
          MerchantProfilePage(), // ✅ real profile with logout
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _bottomNav() {
    return Container(
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(icon: Icons.receipt_long, index: 0),
          _navItem(icon: Icons.shopping_bag_outlined, index: 1),
          _navItem(icon: Icons.bar_chart_outlined, index: 2),
          _navItem(icon: Icons.person_outline, index: 3),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required int index}) {
    final active = selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => selectedNav = index),
      child: Icon(
        icon,
        size: 24,
        color: active ? kBrandBlue : Colors.grey,
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
