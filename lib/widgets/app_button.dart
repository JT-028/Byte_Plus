// lib/widgets/app_button.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable button component with multiple variants
///
/// Variants:
/// - `AppButton.primary` - Filled blue button
/// - `AppButton.secondary` - Filled orange button
/// - `AppButton.outline` - Outlined button
/// - `AppButton.text` - Text-only button
/// - `AppButton.icon` - Icon button with optional label

enum AppButtonVariant { primary, secondary, outline, text, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final Widget? child;

  const AppButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.child,
  });

  // Named constructors for common variants
  const AppButton.primary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.child,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.child,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.child,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.child,
  }) : variant = AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.child,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _getHeight(),
      child: _buildButton(context, isDark),
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 48;
      case AppButtonSize.large:
        return 56;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTextStyles.labelSmall;
      case AppButtonSize.medium:
        return AppTextStyles.labelMedium;
      case AppButtonSize.large:
        return AppTextStyles.labelLarge;
    }
  }

  Widget _buildButton(BuildContext context, bool isDark) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isDark ? AppColors.primaryLight : AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
            elevation: 0,
          ),
          child: _buildContent(AppColors.textOnPrimary),
        );

      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.textOnPrimary,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
            elevation: 0,
          ),
          child: _buildContent(AppColors.textOnPrimary),
        );

      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.primaryLight : AppColors.primary,
            side: BorderSide(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
            padding: _getPadding(),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          child: _buildContent(
            isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        );

      case AppButtonVariant.text:
        return TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor:
                isDark ? AppColors.primaryLight : AppColors.primary,
            padding: _getPadding(),
          ),
          child: _buildContent(
            isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        );

      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.textOnPrimary,
            padding: _getPadding(),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
            elevation: 0,
          ),
          child: _buildContent(AppColors.textOnPrimary),
        );
    }
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (child != null) {
      return child!;
    }

    if (icon != null && label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: size == AppButtonSize.small ? 16 : 20),
          const SizedBox(width: 8),
          Text(label!, style: _getTextStyle()),
        ],
      );
    }

    if (icon != null) {
      return Icon(icon, size: size == AppButtonSize.small ? 16 : 20);
    }

    return Text(label ?? '', style: _getTextStyle());
  }
}

/// Circular Icon Button with tap scale animation
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final String? semanticLabel;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.iconSize = 22,
    this.semanticLabel,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: widget.semanticLabel,
      button: true,
      enabled: widget.onPressed != null,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(scale: _scaleAnimation.value, child: child);
          },
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color:
                  widget.backgroundColor ??
                  (isDark ? AppColors.surfaceVariantDark : AppColors.surface),
              shape: BoxShape.circle,
              boxShadow: AppShadows.small,
            ),
            child: Icon(
              widget.icon,
              size: widget.iconSize,
              color:
                  widget.iconColor ??
                  (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
