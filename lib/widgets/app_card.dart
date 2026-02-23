// lib/widgets/app_card.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable card component with consistent styling
///
/// Variants:
/// - `AppCard` - Default card with shadow
/// - `AppCard.outlined` - Card with border, no shadow
/// - `AppCard.flat` - Card without shadow or border

enum AppCardVariant { elevated, outlined, flat }

class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.width,
    this.height,
  });

  /// Card with outline border
  const AppCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.width,
    this.height,
  }) : variant = AppCardVariant.outlined;

  /// Flat card without shadow or border
  const AppCard.flat({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.width,
    this.height,
  }) : variant = AppCardVariant.flat;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBackgroundColor =
        backgroundColor ?? (isDark ? AppColors.surfaceDark : AppColors.surface);
    final effectiveBorderRadius = borderRadius ?? AppRadius.cardRadius;

    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Material(
        color: effectiveBackgroundColor,
        borderRadius: effectiveBorderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveBorderRadius,
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: effectiveBorderRadius,
              border:
                  variant == AppCardVariant.outlined
                      ? Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      )
                      : null,
              boxShadow:
                  variant == AppCardVariant.elevated ? AppShadows.card : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Selection Card - used for options like "Pick up now" / "Pick up later"
class AppSelectionCard extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppSelectionCard({
    super.key,
    required this.child,
    this.isSelected = false,
    this.onTap,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Container(
      margin: margin,
      child: Material(
        color:
            isSelected
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.08))
                : backgroundColor,
        borderRadius: AppRadius.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardRadius,
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: isSelected ? primaryColor : borderColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// List Tile Card - for menu items like "Favourites", "Personal Info"
class AppListTileCard extends StatelessWidget {
  final IconData? leadingIcon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const AppListTileCard({
    super.key,
    this.leadingIcon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: iconColor ?? textColor, size: 22),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}

