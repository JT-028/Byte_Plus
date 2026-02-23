// lib/widgets/category_chip.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Category chip/pill for filtering
///
/// Used in:
/// - Dashboard category filter (All, Drinks, Burger, etc.)
/// - Store page menu categories (Popular, Seasonal, Milk Tea, etc.)

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const CategoryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final backgroundColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surface;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : backgroundColor,
          borderRadius: AppRadius.chipRadius,
          border:
              isSelected
                  ? null
                  : Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.textOnPrimary : textColor,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.textOnPrimary : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal scrollable category chip list
class CategoryChipList extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final EdgeInsetsGeometry? padding;

  const CategoryChipList({
    super.key,
    required this.categories,
    required this.selectedIndex,
    this.onSelected,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return CategoryChip(
            label: categories[index],
            isSelected: selectedIndex == index,
            onTap: () => onSelected?.call(index),
          );
        },
      ),
    );
  }
}

/// Tab-style category selector (used in store page sticky header)
class CategoryTabBar extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final EdgeInsetsGeometry? padding;

  const CategoryTabBar({
    super.key,
    required this.categories,
    required this.selectedIndex,
    this.onSelected,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final textColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xl),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected?.call(index),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  categories[index],
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? primaryColor : textColor,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AnimatedContainer(
                  duration: AppAnimations.fast,
                  height: 2.5,
                  width: isSelected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(AppRadius.round),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Toggle tabs (Active Orders / Past Orders style)
class ToggleTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const ToggleTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final backgroundColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onSelected?.call(index),
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
              child: Text(
                tabs[index],
                style: AppTextStyles.labelMedium.copyWith(
                  color:
                      isSelected
                          ? AppColors.textOnPrimary
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

