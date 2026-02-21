// lib/pages/location_permission_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_theme.dart';
import '../widgets/app_modal_dialog.dart';

/// A beautiful location permission request page that explains why location
/// is needed for campus geofencing and requests the permission.
class LocationPermissionPage extends StatefulWidget {
  final Widget destination;

  const LocationPermissionPage({super.key, required this.destination});

  @override
  State<LocationPermissionPage> createState() => _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage>
    with SingleTickerProviderStateMixin {
  bool _isRequesting = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkExistingPermission();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check if permission is already granted and skip if so
  Future<void> _checkExistingPermission() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      if (status.isGranted) {
        _proceedToApp();
      }
    } catch (e) {
      // On web, permission_handler may not work correctly
      // We'll proceed to show the permission page anyway
      debugPrint('Permission check failed: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isRequesting = true);

    try {
      // On web, use Geolocator's permission handling directly
      if (kIsWeb) {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          _proceedToApp();
        } else if (permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          await AppModalDialog.warning(
            context: context,
            title: 'Permission Blocked',
            message:
                'Location permission is blocked. Please enable it in your browser settings.',
          );
          setState(() => _isRequesting = false);
        } else {
          // Permission denied
          if (!mounted) return;
          await AppModalDialog.warning(
            context: context,
            title: 'Permission Denied',
            message:
                'Location access is needed to verify you are on campus. Some features may be restricted.',
          );
          _proceedToApp();
        }
        return;
      }

      // Native platforms: use permission_handler
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        final shouldOpenSettings = await AppModalDialog.confirm(
          context: context,
          title: 'Location Services Disabled',
          message:
              'Location services are turned off. Would you like to enable them in settings?',
          confirmLabel: 'Open Settings',
          cancelLabel: 'Not Now',
        );

        if (shouldOpenSettings == true) {
          await Geolocator.openLocationSettings();
        }
        setState(() => _isRequesting = false);
        return;
      }

      // Request location permission
      var status = await Permission.locationWhenInUse.request();

      if (status.isGranted) {
        // Optionally request "always" permission for better geofencing
        // await Permission.locationAlways.request();
        _proceedToApp();
      } else if (status.isPermanentlyDenied) {
        if (!mounted) return;
        final shouldOpenSettings = await AppModalDialog.confirm(
          context: context,
          title: 'Permission Required',
          message:
              'Location permission is required for campus access. Please enable it in app settings.',
          confirmLabel: 'Open Settings',
          cancelLabel: 'Cancel',
        );

        if (shouldOpenSettings == true) {
          await openAppSettings();
        }
        setState(() => _isRequesting = false);
      } else {
        // Permission denied but not permanently
        if (!mounted) return;
        await AppModalDialog.warning(
          context: context,
          title: 'Permission Denied',
          message:
              'Location access is needed to verify you are on campus. Some features may be restricted.',
        );
        // Still proceed but with limited access
        _proceedToApp();
      }
    } catch (e) {
      if (!mounted) return;
      await AppModalDialog.error(
        context: context,
        title: 'Error',
        message: 'Failed to request location permission: $e',
      );
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  void _proceedToApp() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => widget.destination,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _skipForNow() async {
    final shouldSkip = await AppModalDialog.confirm(
      context: context,
      title: 'Skip Location Access?',
      message:
          'Without location access, you won\'t be able to place orders outside campus. Continue anyway?',
      confirmLabel: 'Continue',
      cancelLabel: 'Go Back',
    );

    if (shouldSkip == true) {
      _proceedToApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Location icon with animated ring
                  _buildLocationIcon(isDark),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    'Enable Location',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'BytePlus needs access to your location to verify you\'re on campus. This enables our geofencing feature for secure campus-only ordering.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Benefits list
                  _buildBenefitItem(
                    icon: Icons.security_rounded,
                    text: 'Secure campus-only access',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem(
                    icon: Icons.location_on_rounded,
                    text: 'Order only when on campus',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem(
                    icon: Icons.lock_outline_rounded,
                    text: 'Your data stays private',
                    isDark: isDark,
                  ),

                  const Spacer(flex: 2),

                  // Enable button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed:
                          _isRequesting ? null : _requestLocationPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _isRequesting
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                              : const Text(
                                'Enable Location',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip button
                  TextButton(
                    onPressed: _isRequesting ? null : _skipForNow,
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationIcon(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
          ),
        ),
        // Middle ring
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.15),
          ),
        ),
        // Inner circle with icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
