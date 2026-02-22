import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../services/thermal_printer_service.dart';
import '../widgets/app_modal_dialog.dart';
import 'login_page.dart';
import 'printer_settings_page.dart';

class MerchantProfilePage extends StatefulWidget {
  const MerchantProfilePage({super.key});

  @override
  State<MerchantProfilePage> createState() => _MerchantProfilePageState();
}

class _MerchantProfilePageState extends State<MerchantProfilePage> {
  String? _storeId;
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final storeId = userDoc.data()?['storeId']?.toString();
    if (storeId == null || storeId.isEmpty) return;

    final storeDoc = await FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .get(const GetOptions(source: Source.server))
        .catchError(
          (_) =>
              FirebaseFirestore.instance
                  .collection('stores')
                  .doc(storeId)
                  .get(),
        );
    final data = storeDoc.data();
    if (data == null) return;

    final openStr = data['openingTime']?.toString();
    final closeStr = data['closingTime']?.toString();

    if (mounted) {
      setState(() {
        _storeId = storeId;
        if (openStr != null && openStr.contains(':')) {
          final parts = openStr.split(':');
          _openingTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
        if (closeStr != null && closeStr.contains(':')) {
          final parts = closeStr.split(':');
          _closingTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  Future<void> _pickTime({required bool isOpening}) async {
    final initial =
        isOpening
            ? (_openingTime ?? const TimeOfDay(hour: 8, minute: 0))
            : (_closingTime ?? const TimeOfDay(hour: 17, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null && _storeId != null) {
      final oldOpening = _openingTime;
      final oldClosing = _closingTime;
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
      // Save to Firestore
      try {
        final timeStr =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        final fieldName = isOpening ? 'openingTime' : 'closingTime';
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(_storeId)
            .update({fieldName: timeStr});
      } catch (e) {
        // Revert on failure
        if (mounted) {
          setState(() {
            _openingTime = oldOpening;
            _closingTime = oldClosing;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update operating hours: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Profile card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? AppColors.surfaceDark
                                  : const Color(0xFFF0F2FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                FirebaseAuth.instance.currentUser?.email ?? "",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Dark Mode Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              color:
                                  isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                "Dark Mode",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Consumer<ThemeService>(
                              builder: (context, themeService, _) {
                                return Switch(
                                  value: themeService.isDarkMode,
                                  onChanged: (_) => themeService.toggleTheme(),
                                  activeThumbColor: AppColors.primary,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Printer Settings
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrinterSettingsPage(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              StreamBuilder<PrinterStatus>(
                                stream: ThermalPrinterService().statusStream,
                                initialData: ThermalPrinterService().status,
                                builder: (context, snapshot) {
                                  final isConnected =
                                      snapshot.data == PrinterStatus.connected;
                                  return Icon(
                                    Iconsax.printer,
                                    color:
                                        isConnected
                                            ? AppColors.success
                                            : (isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimary),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Printer Settings",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                    StreamBuilder<PrinterStatus>(
                                      stream:
                                          ThermalPrinterService().statusStream,
                                      initialData:
                                          ThermalPrinterService().status,
                                      builder: (context, snapshot) {
                                        final isConnected =
                                            snapshot.data ==
                                            PrinterStatus.connected;
                                        final printer =
                                            ThermalPrinterService()
                                                .connectedPrinter;
                                        return Text(
                                          isConnected
                                              ? 'Connected: ${printer?.name ?? "Printer"}'
                                              : 'Not connected',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                isDark
                                                    ? AppColors
                                                        .textSecondaryDark
                                                    : AppColors.textSecondary,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Iconsax.arrow_right_3,
                                color:
                                    isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Operating Hours
                      if (_storeId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.clock,
                                    color:
                                        isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimary,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      "Operating Hours",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _pickTime(isOpening: true),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? AppColors.backgroundDark
                                                  : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                isDark
                                                    ? AppColors.borderDark
                                                    : AppColors.border,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Opens',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    isDark
                                                        ? AppColors
                                                            .textSecondaryDark
                                                        : AppColors
                                                            .textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _openingTime != null
                                                  ? _formatTimeOfDay(
                                                    _openingTime!,
                                                  )
                                                  : 'Set time',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    _openingTime != null
                                                        ? AppColors.primary
                                                        : (isDark
                                                            ? AppColors
                                                                .textTertiaryDark
                                                            : AppColors
                                                                .textTertiary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      '–',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _pickTime(isOpening: false),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? AppColors.backgroundDark
                                                  : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                isDark
                                                    ? AppColors.borderDark
                                                    : AppColors.border,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Closes',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    isDark
                                                        ? AppColors
                                                            .textSecondaryDark
                                                        : AppColors
                                                            .textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _closingTime != null
                                                  ? _formatTimeOfDay(
                                                    _closingTime!,
                                                  )
                                                  : 'Set time',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    _closingTime != null
                                                        ? AppColors.primary
                                                        : (isDark
                                                            ? AppColors
                                                                .textTertiaryDark
                                                            : AppColors
                                                                .textTertiary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      if (_storeId != null) const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? AppColors.surfaceDark : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color:
                            isDark
                                ? AppColors.borderDark
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  onPressed: () async {
                    final ok = await AppModalDialog.confirm(
                      context: context,
                      title: 'Log Out?',
                      message: 'Are you sure you want to log out?',
                      confirmLabel: 'Yes, Log Out',
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
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 28,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? AppColors.surfaceDark
                                              : Colors.white,
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
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(AppColors.primary),
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

                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    }
                  },
                  child: Text(
                    "Log Out",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
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
