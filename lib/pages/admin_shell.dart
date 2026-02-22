// lib/pages/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../pages/login_page.dart';
import '../pages/admin/admin_dashboard_page.dart';
import '../pages/admin/admin_users_page.dart';
import '../pages/admin/admin_stores_page.dart';
import '../pages/admin/admin_password_requests_page.dart';
import '../pages/admin/admin_geofence_settings_page.dart';
import '../widgets/app_modal_dialog.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  final _auth = FirebaseAuth.instance;
  User get _user => _auth.currentUser!;

  final List<Widget> _pages = const [
    AdminDashboardPage(),
    AdminUsersPage(),
    AdminStoresPage(),
    AdminPasswordRequestsPage(),
    AdminGeofenceSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on home tab (Dashboard), go back to home
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }

        // On home tab - show logout confirmation
        await _logout();
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: _buildAppBar(isDark),
        drawer: _buildDrawer(isDark),
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: _buildBottomNav(isDark),
      ),
    );
  }

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Iconsax.shield_tick,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'BytePlus Admin',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: isDark ? AppColors.textPrimaryDark : Colors.white,
            ),
          ),
        ],
      ),
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: Icon(
                Iconsax.menu_1,
                color: isDark ? AppColors.textPrimaryDark : Colors.white,
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
      ),
      actions: [
        // Pending requests badge
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('passwordRequests')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
          builder: (context, snap) {
            final count = snap.data?.docs.length ?? 0;
            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    Iconsax.notification,
                    color: isDark ? AppColors.textPrimaryDark : Colors.white,
                  ),
                  onPressed: () => setState(() => _selectedIndex = 3),
                ),
                if (count > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count > 9 ? '9+' : count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Drawer _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Profile header
            FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user.uid)
                      .get(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(
                            Iconsax.shield_tick,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data['name']?.toString() ?? 'Admin',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data['email']?.toString() ?? _user.email ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Administrator',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Nav items
            _drawerItem(
              icon: Iconsax.home_2,
              label: 'Dashboard',
              index: 0,
              isDark: isDark,
            ),
            _drawerItem(
              icon: Iconsax.people,
              label: 'Manage Users',
              index: 1,
              isDark: isDark,
            ),
            _drawerItem(
              icon: Iconsax.shop,
              label: 'Manage Stores',
              index: 2,
              isDark: isDark,
            ),
            _drawerItem(
              icon: Iconsax.key,
              label: 'Password Requests',
              index: 3,
              isDark: isDark,
              showBadge: true,
            ),
            _drawerItem(
              icon: Iconsax.location,
              label: 'Geofence Settings',
              index: 4,
              isDark: isDark,
            ),

            const Spacer(),

            // Logout
            Divider(color: isDark ? AppColors.borderDark : AppColors.border),
            ListTile(
              leading: const Icon(Iconsax.logout, color: AppColors.error),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _logout,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
    bool showBadge = false,
  }) {
    final isSelected = _selectedIndex == index;

    return ListTile(
      leading: Stack(
        children: [
          Icon(
            icon,
            color:
                isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
          ),
          if (showBadge)
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('passwordRequests')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 9 ? '9+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      title: Text(
        label,
        style: TextStyle(
          color:
              isSelected
                  ? AppColors.primary
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
      tileColor:
          isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Iconsax.home_2, 'Dashboard', 0, isDark),
              _navItem(Iconsax.people, 'Users', 1, isDark),
              _navItem(Iconsax.shop, 'Stores', 2, isDark),
              _navItemWithBadge(Iconsax.key, 'Requests', 3, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, bool isDark) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItemWithBadge(
    IconData icon,
    String label,
    int index,
    bool isDark,
  ) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color:
                      isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary),
                  size: 22,
                ),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('passwordRequests')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                  builder: (context, snap) {
                    final count = snap.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Logout?',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      cancelLabel: 'Cancel',
    );

    if (ok == true) {
      // Show loading overlay with animation
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        builder:
            (context) => PopScope(
              canPop: false,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Logging out',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                            decoration: TextDecoration.none,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      );

      // Wait a bit for visual feedback
      await Future.delayed(const Duration(milliseconds: 800));

      await _auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }
}
