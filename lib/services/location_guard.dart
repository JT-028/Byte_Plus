// lib/services/location_guard.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import '../theme/app_theme.dart';

class LocationGuard extends StatefulWidget {
  final Widget child;

  const LocationGuard({super.key, required this.child});

  @override
  State<LocationGuard> createState() => _LocationGuardState();
}

class _LocationGuardState extends State<LocationGuard> {
  bool _inside = false;
  bool _loading = true;
  String? _error;
  Timer? _timer;
  Map<String, dynamic>? _cfg;
  bool _isExemptUser = false; // Admin/staff are exempt from location checks

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    setState(() => _loading = true);

    try {
      // ✅ Check if user is admin or staff (exempt from location restrictions)
      await _checkUserRole();

      if (_isExemptUser) {
        debugPrint(
          '[LocationGuard] User is admin/staff - exempt from location checks',
        );
        setState(() {
          _inside = true;
          _loading = false;
        });
        return;
      }

      // Load geofence settings from Firestore
      final cfg =
          await FirebaseFirestore.instance
              .collection('geofence')
              .doc('campus')
              .get();

      if (!cfg.exists) {
        // No geofence settings configured - allow access
        debugPrint(
          '[LocationGuard] No geofence settings found - allowing access',
        );
        setState(() {
          _inside = true;
          _loading = false;
        });
        return;
      }

      _cfg = cfg.data();

      // Check if geofence is enabled
      final isGeofenceEnabled = _cfg?['enabled'] ?? false;
      if (!isGeofenceEnabled) {
        debugPrint('[LocationGuard] Geofence is disabled - allowing access');
        setState(() {
          _inside = true;
          _loading = false;
        });
        return;
      }

      // Ensure location permissions
      await _ensurePermissions();

      // ✅ Check immediately once at startup
      await _checkLocation();

      // ✅ Start 15s polling while app is open
      _startForegroundCheck();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Check if the current user is admin or staff
  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _isExemptUser = false;
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!userDoc.exists) {
        _isExemptUser = false;
        return;
      }

      final data = userDoc.data() ?? {};
      final role = (data['role'] ?? 'student').toString().trim().toLowerCase();

      // Admin and staff are exempt from location restrictions
      _isExemptUser = (role == 'admin' || role == 'staff');
    } catch (e) {
      debugPrint('[LocationGuard] Error checking user role: $e');
      _isExemptUser = false;
    }
  }

  void _startForegroundCheck() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkLocation(),
    );
  }

  Future<void> _checkLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint(
        "[LocationGuard] Current coordinates: (${pos.latitude}, ${pos.longitude})",
      );

      // ✅ Use Firestore settings (campus geofence)
      double lat = (_cfg?['latitude'] ?? 0).toDouble();
      double lng = (_cfg?['longitude'] ?? 0).toDouble();
      double radius = (_cfg?['radius'] ?? 500.0).toDouble();

      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        lat,
        lng,
      );
      debugPrint(
        "[LocationGuard] Distance from allowed zone: ${distance.toStringAsFixed(2)} m (radius: $radius m)",
      );

      setState(() => _inside = distance <= radius);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _ensurePermissions() async {
    // On web, permission_handler is not supported
    // The browser will automatically ask for permission when getCurrentPosition is called
    if (kIsWeb) {
      // Just check if location services are available
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationGuard] Location services disabled on web');
      }
      return;
    }

    // Mobile platforms: use permission_handler
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.locationWhenInUse.request();
    }

    if (await Permission.locationAlways.isDenied) {
      await Permission.locationAlways.request();
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        body: Center(
          child: Lottie.asset(
            'assets/animation/cooking_splash.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            repeat: true,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            "⚠️ Error: $_error",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (!_inside) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Lottie animation
                Lottie.asset(
                  'assets/animation/restricted.json',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                  repeat: true,
                ),
                const SizedBox(height: 34),
                // Title
                Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Description
                Text(
                  'You are outside the allowed campus area. Please move within the campus boundary to access the app.',
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _loading = true);
                      _checkLocation().then((_) {
                        setState(() => _loading = false);
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

