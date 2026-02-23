// lib/pages/splash_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_theme.dart';
import '../services/notification_service.dart';
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
    await NotificationService.saveFcmToken(uid);
  }

  /// Check if location permission is already granted
  Future<bool> _checkLocationPermission() async {
    try {
      // On web, use Geolocator (permission_handler not supported)
      if (kIsWeb) {
        final permission = await Geolocator.checkPermission();
        return permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
      }

      // Mobile platforms: use permission_handler
      final status = await Permission.locationWhenInUse.status;
      return status.isGranted;
    } catch (e) {
      // On error, assume permission not granted
      return false;
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

      // Check if account has been deleted by admin
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'deleted') {
        // Sign out the user and show message
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        // Show error dialog then navigate to login
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Account Disabled'),
                content: const Text(
                  'Your account has been disabled by an administrator. Please contact support if you believe this is an error.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        if (mounted) _navigateToLogin();
        return;
      }

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

      // Wrap with LocationGuard for geofence enforcement
      destination = LocationGuard(child: destination);

      // For students, check if location permission is already granted
      // Only show LocationPermissionPage if permission is NOT granted
      if (role == 'student') {
        final hasLocationPermission = await _checkLocationPermission();

        if (hasLocationPermission) {
          // Permission already granted, go directly to destination
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
        } else {
          // Permission not granted, show location permission page
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
        }
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

