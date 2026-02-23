// lib/widgets/app_modal_dialog.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modal dialog type that determines the icon and color scheme
enum AppModalType { success, error, warning, info, confirm }

/// Button configuration for modal dialogs
class ModalButton {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color? backgroundColor;
  final Color? textColor;

  const ModalButton({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.backgroundColor,
    this.textColor,
  });
}

/// A beautiful modal dialog widget matching the app's design system.
///
/// Features:
/// - Dark overlay background
/// - Centered white rounded card
/// - Colored icon circle at top
/// - Title and optional message
/// - Up to 2 action buttons (primary and secondary)
///
/// Usage:
/// ```dart
/// AppModalDialog.show(
///   context: context,
///   type: AppModalType.success,
///   title: 'Order Successful!',
///   message: 'Your order has been placed.',
///   primaryButton: ModalButton(
///     label: 'View My Order',
///     onPressed: () => Navigator.pop(context),
///     isPrimary: true,
///   ),
///   secondaryButton: ModalButton(
///     label: 'Back to Home',
///     onPressed: () => Navigator.pop(context),
///   ),
/// );
/// ```
class AppModalDialog extends StatelessWidget {
  final AppModalType type;
  final String title;
  final String? message;
  final ModalButton? primaryButton;
  final ModalButton? secondaryButton;
  final Widget? customContent;
  final bool barrierDismissible;

  const AppModalDialog({
    super.key,
    required this.type,
    required this.title,
    this.message,
    this.primaryButton,
    this.secondaryButton,
    this.customContent,
    this.barrierDismissible = true,
  });

  /// Shows the modal dialog with a dark overlay
  static Future<T?> show<T>({
    required BuildContext context,
    required AppModalType type,
    required String title,
    String? message,
    ModalButton? primaryButton,
    ModalButton? secondaryButton,
    Widget? customContent,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AppModalDialog(
          type: type,
          title: title,
          message: message,
          primaryButton: primaryButton,
          secondaryButton: secondaryButton,
          customContent: customContent,
          barrierDismissible: barrierDismissible,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  /// Quick success dialog
  static Future<void> success({
    required BuildContext context,
    required String title,
    String? message,
    String primaryLabel = 'OK',
    VoidCallback? onPrimaryPressed,
    String? secondaryLabel,
    VoidCallback? onSecondaryPressed,
  }) {
    return show(
      context: context,
      type: AppModalType.success,
      title: title,
      message: message,
      primaryButton: ModalButton(
        label: primaryLabel,
        onPressed: onPrimaryPressed ?? () => Navigator.pop(context),
        isPrimary: true,
      ),
      secondaryButton:
          secondaryLabel != null
              ? ModalButton(
                label: secondaryLabel,
                onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
              )
              : null,
    );
  }

  /// Quick error dialog
  static Future<void> error({
    required BuildContext context,
    required String title,
    String? message,
    String buttonLabel = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      type: AppModalType.error,
      title: title,
      message: message,
      primaryButton: ModalButton(
        label: buttonLabel,
        onPressed: onPressed ?? () => Navigator.pop(context),
        isPrimary: true,
      ),
    );
  }

  /// Quick warning dialog
  static Future<void> warning({
    required BuildContext context,
    required String title,
    String? message,
    String buttonLabel = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      type: AppModalType.warning,
      title: title,
      message: message,
      primaryButton: ModalButton(
        label: buttonLabel,
        onPressed: onPressed ?? () => Navigator.pop(context),
        isPrimary: true,
      ),
    );
  }

  /// Quick info dialog
  static Future<void> info({
    required BuildContext context,
    required String title,
    String? message,
    String buttonLabel = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      type: AppModalType.info,
      title: title,
      message: message,
      primaryButton: ModalButton(
        label: buttonLabel,
        onPressed: onPressed ?? () => Navigator.pop(context),
        isPrimary: true,
      ),
    );
  }

  /// Confirmation dialog with Yes/No or custom buttons
  static Future<bool?> confirm({
    required BuildContext context,
    required String title,
    String? message,
    String confirmLabel = 'Yes',
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) {
    return show<bool>(
      context: context,
      type: isDanger ? AppModalType.warning : AppModalType.confirm,
      title: title,
      message: message,
      barrierDismissible: false,
      primaryButton: ModalButton(
        label: confirmLabel,
        onPressed: () => Navigator.pop(context, true),
        isPrimary: true,
        backgroundColor: isDanger ? AppColors.error : null,
      ),
      secondaryButton: ModalButton(
        label: cancelLabel,
        onPressed: () => Navigator.pop(context, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon circle
                _buildIconCircle(),

                const SizedBox(height: 20),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _getTitleColor(),
                  ),
                ),

                // Message (optional)
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],

                // Custom content (optional)
                if (customContent != null) ...[
                  const SizedBox(height: 16),
                  customContent!,
                ],

                const SizedBox(height: 24),

                // Buttons
                _buildButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconCircle() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getIconBackgroundColor().withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(_getIcon(), color: Colors.white, size: 36),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case AppModalType.success:
        return Icons.check_rounded;
      case AppModalType.error:
        return Icons.close_rounded;
      case AppModalType.warning:
        return Icons.warning_rounded;
      case AppModalType.info:
        return Icons.info_outline_rounded;
      case AppModalType.confirm:
        return Icons.help_outline_rounded;
    }
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case AppModalType.success:
        return AppColors.primary;
      case AppModalType.error:
        return AppColors.error;
      case AppModalType.warning:
        return AppColors.warning;
      case AppModalType.info:
        return AppColors.info;
      case AppModalType.confirm:
        return AppColors.primary;
    }
  }

  Color _getTitleColor() {
    switch (type) {
      case AppModalType.success:
        return AppColors.primary;
      case AppModalType.error:
        return AppColors.error;
      case AppModalType.warning:
        return AppColors.warning;
      case AppModalType.info:
        return AppColors.info;
      case AppModalType.confirm:
        return AppColors.textPrimary;
    }
  }

  Widget _buildButtons(BuildContext context) {
    final buttons = <Widget>[];

    // Primary button
    if (primaryButton != null) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: primaryButton!.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  primaryButton!.backgroundColor ?? _getIconBackgroundColor(),
              foregroundColor: primaryButton!.textColor ?? Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              primaryButton!.label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    // Secondary button
    if (secondaryButton != null) {
      buttons.add(const SizedBox(height: 12));
      buttons.add(
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: secondaryButton!.onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              secondaryButton!.label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}

