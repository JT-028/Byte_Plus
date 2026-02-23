// lib/widgets/quantity_selector.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Quantity selector with +/- buttons
///
/// Usage:
/// ```dart
/// QuantitySelector(
///   quantity: 1,
///   onChanged: (newQty) => setState(() => quantity = newQty),
/// )
/// ```

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int minQuantity;
  final int maxQuantity;
  final ValueChanged<int>? onChanged;
  final bool compact;

  const QuantitySelector({
    super.key,
    required this.quantity,
    this.minQuantity = 1,
    this.maxQuantity = 99,
    this.onChanged,
    this.compact = false,
  });

  void _decrement() {
    if (quantity > minQuantity) {
      onChanged?.call(quantity - 1);
    }
  }

  void _increment() {
    if (quantity < maxQuantity) {
      onChanged?.call(quantity + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final iconColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    if (compact) {
      return _buildCompact(borderColor, backgroundColor, textColor, iconColor);
    }

    return _buildStandard(borderColor, backgroundColor, textColor, iconColor);
  }

  Widget _buildStandard(
    Color borderColor,
    Color backgroundColor,
    Color textColor,
    Color iconColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove,
            onTap: quantity > minQuantity ? _decrement : null,
            iconColor: iconColor,
            isLeft: true,
          ),
          Container(
            width: 44,
            alignment: Alignment.center,
            child: Text(
              quantity.toString(),
              style: AppTextStyles.labelLarge.copyWith(color: textColor),
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onTap: quantity < maxQuantity ? _increment : null,
            iconColor: iconColor,
            isLeft: false,
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(
    Color borderColor,
    Color backgroundColor,
    Color textColor,
    Color iconColor,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactButton(
          icon: Icons.remove,
          onTap: quantity > minQuantity ? _decrement : null,
          borderColor: borderColor,
          iconColor: iconColor,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            quantity.toString(),
            style: AppTextStyles.labelLarge.copyWith(color: textColor),
          ),
        ),
        _buildCompactButton(
          icon: Icons.add,
          onTap: quantity < maxQuantity ? _increment : null,
          borderColor: borderColor,
          iconColor: iconColor,
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color iconColor,
    required bool isLeft,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.horizontal(
        left: isLeft ? const Radius.circular(AppRadius.round) : Radius.zero,
        right: !isLeft ? const Radius.circular(AppRadius.round) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? iconColor : iconColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildCompactButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color borderColor,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.round),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppRadius.round),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? iconColor : iconColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}

/// Add to cart quantity selector (larger, for product pages)
class ProductQuantitySelector extends StatelessWidget {
  final int quantity;
  final int minQuantity;
  final int maxQuantity;
  final ValueChanged<int>? onChanged;

  const ProductQuantitySelector({
    super.key,
    required this.quantity,
    this.minQuantity = 1,
    this.maxQuantity = 99,
    this.onChanged,
  });

  void _decrement() {
    if (quantity > minQuantity) {
      onChanged?.call(quantity - 1);
    }
  }

  void _increment() {
    if (quantity < maxQuantity) {
      onChanged?.call(quantity + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final backgroundColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCircleButton(
          icon: Icons.remove,
          onTap: quantity > minQuantity ? _decrement : null,
          backgroundColor: backgroundColor,
          iconColor: primaryColor,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            quantity.toString(),
            style: AppTextStyles.heading3.copyWith(color: textColor),
          ),
        ),
        _buildCircleButton(
          icon: Icons.add,
          onTap: quantity < maxQuantity ? _increment : null,
          backgroundColor: backgroundColor,
          iconColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    final isDecrease = icon == Icons.remove;
    return Semantics(
      label: isDecrease ? 'Decrease quantity' : 'Increase quantity',
      hint: isDecrease ? 'Double tap to decrease' : 'Double tap to increase',
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: onTap != null ? iconColor : iconColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

/// Small add button (used in product grid cards)
class AddButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showQuantity;
  final int quantity;
  final String? semanticLabel;

  const AddButton({
    super.key,
    this.onTap,
    this.showQuantity = false,
    this.quantity = 0,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryLight : AppColors.primary;

    if (showQuantity && quantity > 0) {
      return Semantics(
        label: '$quantity in cart',
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              quantity.toString(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    // Use a larger hit target while keeping visual size smaller
    return Semantics(
      label: semanticLabel ?? 'Add to cart',
      hint: 'Double tap to add item to cart',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 18, color: primaryColor),
            ),
          ),
        ),
      ),
    );
  }
}

