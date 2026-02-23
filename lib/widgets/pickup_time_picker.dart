// lib/widgets/pickup_time_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// A custom time picker dialog matching the app's design system.
/// Shows a wheel-style picker for hours and minutes.
class PickupTimePicker extends StatefulWidget {
  final DateTime? initialTime;

  const PickupTimePicker({super.key, this.initialTime});

  /// Shows the pickup time picker and returns the selected DateTime
  static Future<DateTime?> show(BuildContext context, {DateTime? initialTime}) {
    return showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PickupTimePicker(initialTime: initialTime);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<PickupTimePicker> createState() => _PickupTimePickerState();
}

class _PickupTimePickerState extends State<PickupTimePicker> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _selectedHour;
  late int _selectedMinute;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();

    final initial =
        widget.initialTime ?? _today.add(const Duration(minutes: 30));
    _selectedHour = initial.hour;
    _selectedMinute = initial.minute;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onSetTime() {
    final selectedDateTime = DateTime(
      _today.year,
      _today.month,
      _today.day,
      _selectedHour,
      _selectedMinute,
    );
    Navigator.pop(context, selectedDateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),

              // Title
              Text(
                'Set your pick up time',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Date display
              Text(
                'Today, ${DateFormat('MMM dd, yyyy').format(_today)}',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Time picker wheels
              SizedBox(
                height: 150,
                child: Stack(
                  children: [
                    // Selection highlight
                    Center(
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? AppColors.surfaceVariantDark
                                  : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Wheel pickers
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hours wheel
                        SizedBox(
                          width: 70,
                          child: ListWheelScrollView.useDelegate(
                            controller: _hourController,
                            itemExtent: 44,
                            perspective: 0.005,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() => _selectedHour = index);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 24,
                              builder: (context, index) {
                                final isSelected = index == _selectedHour;
                                return Center(
                                  child: Text(
                                    index.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: isSelected ? 22 : 18,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                      color:
                                          isSelected
                                              ? (isDark
                                                  ? AppColors.textPrimaryDark
                                                  : AppColors.textPrimary)
                                              : (isDark
                                                  ? AppColors.textTertiaryDark
                                                  : AppColors.textTertiary),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Colon separator
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color:
                                  isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),

                        // Minutes wheel
                        SizedBox(
                          width: 70,
                          child: ListWheelScrollView.useDelegate(
                            controller: _minuteController,
                            itemExtent: 44,
                            perspective: 0.005,
                            diameterRatio: 1.5,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() => _selectedMinute = index);
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 60,
                              builder: (context, index) {
                                final isSelected = index == _selectedMinute;
                                return Center(
                                  child: Text(
                                    index.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: isSelected ? 22 : 18,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                      color:
                                          isSelected
                                              ? (isDark
                                                  ? AppColors.textPrimaryDark
                                                  : AppColors.textPrimary)
                                              : (isDark
                                                  ? AppColors.textTertiaryDark
                                                  : AppColors.textTertiary),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Set Time button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _onSetTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Set Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
