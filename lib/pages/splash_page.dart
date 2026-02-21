// lib/pages/splash_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_theme.dart';
import 'login_page.dart';
import 'user_shell.dart';
import 'merchant_shell.dart';
import 'admin_shell.dart';
import 'location_permission_page.dart';
import '../services/location_guard.dart';

/// Splash screen that shows while Firebase initializes
/// Automatically navigates to the appropriate screen based on auth state
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkAuthState();
  }

  void _setupAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  /// Save FCM token to user's Firestore document for push notifications
  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently fail - FCM is not critical
      debugPrint('Failed to save FCM token: $e');
    }
  }

  Future<void> _checkAuthState() async {
    // Minimum splash duration for better UX
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _navigateToLogin();
      return;
    }

    // User is logged in, get their role
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!mounted) return;

      if (!userDoc.exists) {
        _navigateToLogin();
        return;
      }

      final data = userDoc.data() ?? {};
      final role = (data['role'] ?? 'student').toString().trim().toLowerCase();

      // Save FCM token for push notifications
      _saveFcmToken(user.uid);

      Widget destination;
      if (role == 'admin') {
        destination = const AdminShell();
      } else if (role == 'staff') {
        destination = const MerchantShell();
      } else {
        destination = const UserShell();
      }

      // Wrap with LocationGuard (mock mode enabled for testing)
      destination = LocationGuard(
        useMock: true,
        mockLat: 15.158503947241618, // School center coordinates for testing
        mockLng: 120.59252284294321,
        child: destination,
      );

      // Show location permission page for students
      // (merchants/admins may need different handling)
      if (role == 'student') {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (_, __, ___) =>
                    LocationPermissionPage(destination: destination),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => destination,
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Lottie.asset(
            'assets/animation/cooking_splash.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
      ),
    );
  }
}
