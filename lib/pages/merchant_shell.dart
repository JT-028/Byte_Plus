// lib/pages/merchant_shell.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'merchant_orders_page.dart';
import 'merchant_profile_page.dart';
import 'manage_menu_page.dart';
import 'analytics_page.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key});

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int selectedNav = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: IndexedStack(
        index: selectedNav,
        children: const [
          MerchantOrdersPage(),
          ManageMenuPage(),
          AnalyticsPage(),
          MerchantProfilePage(),
        ],
      ),
      bottomNavigationBar: _bottomNav(isDark),
    );
  }

  Widget _bottomNav(bool isDark) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(icon: Icons.receipt_long, index: 0, isDark: isDark),
          _navItem(icon: Icons.shopping_bag_outlined, index: 1, isDark: isDark),
          _navItem(icon: Icons.bar_chart_outlined, index: 2, isDark: isDark),
          _navItem(icon: Icons.person_outline, index: 3, isDark: isDark),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required int index,
    required bool isDark,
  }) {
    final active = selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => selectedNav = index),
      child: Icon(
        icon,
        size: 24,
        color:
            active
                ? AppColors.primary
                : (isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiary),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
