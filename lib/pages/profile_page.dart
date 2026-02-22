// lib/pages/profile_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import '../widgets/app_modal_dialog.dart';
import 'favorites_page.dart';
import 'personal_info_page.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
          builder: (context, snap) {
            final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};

            final displayName = (data['name'] ?? '').toString().trim();
            // Show the actual Firebase Auth email, not the Firestore one
            final email =
                (FirebaseAuth.instance.currentUser?.email ??
                        data['email'] ??
                        '')
                    .toString()
                    .trim();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerCard(
                  context,
                  isDark: isDark,
                  name: displayName.isEmpty ? "Unnamed User" : displayName,
                  email: email,
                ),
                const SizedBox(height: 14),

                _listTile(
                  context,
                  isDark: isDark,
                  icon: Icons.favorite_border,
                  title: "Favourites",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage()),
                    );
                  },
                ),
                _listTile(
                  context,
                  isDark: isDark,
                  icon: Icons.person_outline,
                  title: "Personal Info",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PersonalInfoPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Dark mode placeholder toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 22,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Dark Mode",
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Consumer<ThemeService>(
                        builder: (context, themeService, child) {
                          return Switch(
                            value: themeService.themeMode == ThemeMode.dark,
                            activeThumbColor:
                                isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                            onChanged: (_) {
                              themeService.toggleTheme();
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                _logoutButton(context, isDark),
                const SizedBox(height: 22),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _headerCard(
    BuildContext context, {
    required bool isDark,
    required String name,
    required String email,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF0F2FF),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : Colors.grey.shade300,
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

            if (ok != true) return;

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
                            color:
                                isDark ? AppColors.surfaceDark : Colors.white,
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
                                      const AlwaysStoppedAnimation<Color>(
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

            await FirebaseAuth.instance.signOut();
            if (!context.mounted) return;

            // Navigate to login (this will dismiss the loading overlay)
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
          child: Text(
            "Log Out",
            style: TextStyle(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
