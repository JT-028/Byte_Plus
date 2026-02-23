// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Status badge for displaying order status
///
/// Usage:
/// ```dart
/// StatusBadge(status: OrderStatus.preparing)
/// StatusBadge.custom(label: 'New', color: Colors.blue)
/// ```

enum OrderStatus { toDo, preparing, ready, done, cancelled }

class StatusBadge extends StatelessWidget {
  final OrderStatus? status;
  final String? customLabel;
  final Color? customColor;
  final Color? customTextColor;
  final bool isCompact;

  const StatusBadge({super.key, required this.status, this.isCompact = false})
    : customLabel = null,
      customColor = null,
      customTextColor = null;

  const StatusBadge.custom({
    super.key,
    required String label,
    required Color color,
    Color? textColor,
    this.isCompact = false,
  }) : status = null,
       customLabel = label,
       customColor = color,
       customTextColor = textColor;

  String get _label {
    if (customLabel != null) return customLabel!;
    switch (status!) {
      case OrderStatus.toDo:
        return 'New';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.done:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get _compactLabel {
    if (customLabel != null) return customLabel!;
    switch (status!) {
      case OrderStatus.toDo:
        return 'New';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.done:
        return 'Done';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get _backgroundColor {
    if (customColor != null) return customColor!;
    switch (status!) {
      case OrderStatus.toDo:
        return AppColors.infoLight;
      case OrderStatus.preparing:
        return AppColors.warningLight;
      case OrderStatus.ready:
        return AppColors.successLight;
      case OrderStatus.done:
        return AppColors.surfaceVariant;
      case OrderStatus.cancelled:
        return AppColors.errorLight;
    }
  }

  Color get _textColor {
    if (customTextColor != null) return customTextColor!;
    switch (status!) {
      case OrderStatus.toDo:
        return AppColors.info;
      case OrderStatus.preparing:
        return AppColors.warning;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.done:
        return AppColors.textSecondary;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.sm : AppSpacing.md,
        vertical: isCompact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Text(
        isCompact ? _compactLabel : _label,
        style: (isCompact ? AppTextStyles.caption : AppTextStyles.labelSmall)
            .copyWith(color: _textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Required / Optional badge for product customization
class RequiredBadge extends StatelessWidget {
  final bool isRequired;

  const RequiredBadge({super.key, required this.isRequired});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isRequired ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Text(
        isRequired ? 'Required' : 'Optional',
        style: AppTextStyles.caption.copyWith(
          color: isRequired ? AppColors.textOnPrimary : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Completed badge for sections (like Size selection)
class CompletedBadge extends StatelessWidget {
  const CompletedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppRadius.round),
      ),
      child: Text(
        'Completed',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Order status to OrderStatus enum converter
OrderStatus orderStatusFromString(String status) {
  switch (status.toLowerCase().replaceAll('-', '').replaceAll(' ', '')) {
    case 'todo':
      return OrderStatus.toDo;
    case 'inprogress':
    case 'preparing':
      return OrderStatus.preparing;
    case 'ready':
      return OrderStatus.ready;
    case 'done':
    case 'completed':
      return OrderStatus.done;
    case 'cancelled':
    case 'canceled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.toDo;
  }
}

