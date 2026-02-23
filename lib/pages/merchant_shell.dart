// lib/pages/merchant_shell.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/app_modal_dialog.dart';
import '../services/notification_service.dart';
import '../services/thermal_printer_service.dart';
import 'merchant_orders_page.dart';
import 'merchant_profile_page.dart';
import 'manage_menu_page.dart';
import 'analytics_page.dart';
import 'login_page.dart';
import 'printer_settings_page.dart';
import 'order_reports_page.dart';
import 'notifications_page.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key});

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int selectedNav = 0;
  final _auth = FirebaseAuth.instance;
  // ignore: unused_field
  final ThermalPrinterService _printerService = ThermalPrinterService();

  User get _user => _auth.currentUser!;
  String? _storeName;
  String? _storeLogo;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on home tab (Orders), go back to home
        if (selectedNav != 0) {
          setState(() => selectedNav = 0);
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
      elevation: 0,
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
      title: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(_user.uid).get(),
        builder: (context, userSnap) {
          if (!userSnap.hasData || !userSnap.data!.exists) {
            return Text(
              'BytePlus Merchant',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? AppColors.textPrimaryDark : Colors.white,
              ),
            );
          }

          final userData = userSnap.data!.data() as Map<String, dynamic>;
          final storeId = userData['storeId']?.toString() ?? '';

          if (storeId.isEmpty) {
            return Text(
              'BytePlus Merchant',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? AppColors.textPrimaryDark : Colors.white,
              ),
            );
          }

          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('stores')
                    .doc(storeId)
                    .get(),
            builder: (context, storeSnap) {
              if (storeSnap.hasData && storeSnap.data!.exists) {
                final storeData =
                    storeSnap.data!.data() as Map<String, dynamic>;
                _storeName = storeData['name']?.toString();
                _storeLogo = storeData['logoUrl']?.toString();
              }

              return Row(
                children: [
                  if (_storeLogo != null && _storeLogo!.isNotEmpty)
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _storeLogo!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Icon(
                                Iconsax.shop,
                                color: AppColors.primary,
                                size: 18,
                              ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Iconsax.shop,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      _storeName ?? 'My Store',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color:
                            isDark ? AppColors.textPrimaryDark : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      actions: [
        // Notification bell
        StreamBuilder<int>(
          stream: NotificationService.getUnreadCount(_user.uid),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return Stack(
              children: [
                IconButton(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      ),
                  icon: Icon(
                    Iconsax.notification,
                    color: isDark ? AppColors.textPrimaryDark : Colors.white,
                  ),
                  tooltip: 'Notifications',
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile header
              FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user.uid)
                        .get(),
                builder: (context, userSnap) {
                  final userData =
                      userSnap.data?.data() as Map<String, dynamic>? ?? {};
                  final storeId = userData['storeId']?.toString() ?? '';

                  return FutureBuilder<DocumentSnapshot?>(
                    future:
                        storeId.isNotEmpty
                            ? FirebaseFirestore.instance
                                .collection('stores')
                                .doc(storeId)
                                .get()
                            : Future<DocumentSnapshot?>.value(null),
                    builder: (context, storeSnap) {
                      final storeData =
                          storeSnap.data?.data() as Map<String, dynamic>? ?? {};
                      final storeName =
                          storeData['name']?.toString() ?? 'My Store';
                      final storeLogo = storeData['logoUrl']?.toString();

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? AppColors.primaryDark
                                  : AppColors.primary,
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child:
                                    storeLogo != null && storeLogo.isNotEmpty
                                        ? Image.network(
                                          storeLogo,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const Center(
                                                child: Icon(
                                                  Iconsax.shop,
                                                  color: AppColors.primary,
                                                  size: 28,
                                                ),
                                              ),
                                        )
                                        : const Center(
                                          child: Icon(
                                            Iconsax.shop,
                                            color: AppColors.primary,
                                            size: 28,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              storeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userData['email']?.toString() ??
                                  _user.email ??
                                  '',
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
                                'Merchant',
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
                  );
                },
              ),

              const SizedBox(height: 12),

              // Nav items
              _drawerItem(
                icon: Iconsax.receipt_item,
                label: 'Orders',
                index: 0,
                isDark: isDark,
              ),
              _drawerItem(
                icon: Iconsax.menu_board,
                label: 'Manage Menu',
                index: 1,
                isDark: isDark,
              ),
              _drawerItem(
                icon: Iconsax.chart,
                label: 'Analytics',
                index: 2,
                isDark: isDark,
              ),
              _drawerItem(
                icon: Iconsax.user,
                label: 'Profile',
                index: 3,
                isDark: isDark,
              ),

              const Divider(height: 32),

              // Quick actions
              ListTile(
                leading: Icon(
                  Iconsax.document_text,
                  color:
                      isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
                title: Text(
                  'Order Reports',
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderReportsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Iconsax.printer,
                  color:
                      isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
                title: Text(
                  'Printer Settings',
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrinterSettingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Iconsax.notification,
                  color:
                      isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
                title: Text(
                  'Notifications',
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = selectedNav == index;

    return ListTile(
      leading: Icon(
        icon,
        color:
            isSelected
                ? AppColors.primary
                : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary),
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
        setState(() => selectedNav = index);
        Navigator.pop(context);
      },
      tileColor:
          isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _logout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Log Out?',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Yes, Log Out',
      cancelLabel: 'Cancel',
    );

    if (ok != true) return;

    // Show loading overlay
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

    await Future.delayed(const Duration(milliseconds: 800));
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
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
      child: Row(
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
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => selectedNav = index),
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
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
        ),
      ),
    );
  }
}
