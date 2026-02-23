// lib/utils/snackbar_utils.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Utility class for showing animated snackbars with consistent styling.
///
/// Usage:
/// ```dart
/// AppSnackbar.success(context, 'Item added to cart!');
/// AppSnackbar.error(context, 'Something went wrong');
/// AppSnackbar.info(context, 'Processing order...');
/// ```
class AppSnackbar {
  AppSnackbar._();

  /// Show a success snackbar (green)
  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.success,
      duration: duration,
    );
  }

  /// Show an error snackbar (red)
  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: AppColors.error,
      duration: duration,
    );
  }

  /// Show a warning snackbar (orange)
  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: AppColors.warning,
      duration: duration,
    );
  }

  /// Show an info snackbar (blue)
  static void info(BuildContext context, String message, {Duration? duration}) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: AppColors.primary,
      duration: duration,
    );
  }

  /// Show a custom snackbar
  static void custom(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    _show(
      context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor ?? AppColors.primary,
      textColor: textColor,
      duration: duration,
      action: action,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    IconData? icon,
    required Color backgroundColor,
    Color? textColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor ?? Colors.white, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: duration ?? const Duration(seconds: 3),
      action: action,
      dismissDirection: DismissDirection.horizontal,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

/// A toast-like notification that appears at the top of the screen.
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;

  /// Show a toast notification
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    _currentEntry?.remove();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder:
          (context) => _ToastWidget(
            message: message,
            icon: icon,
            backgroundColor:
                backgroundColor ??
                (isDark ? AppColors.surfaceDark : AppColors.surface),
            textColor:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            duration: duration,
            onDismiss: () {
              _currentEntry?.remove();
              _currentEntry = null;
            },
          ),
    );

    overlay.insert(_currentEntry!);
  }

  /// Show a success toast
  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppColors.success,
    );
  }

  /// Show an error toast
  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: AppColors.error,
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

