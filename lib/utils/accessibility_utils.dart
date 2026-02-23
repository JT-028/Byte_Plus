// lib/utils/accessibility_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility-focused utilities and widgets.
///
/// These utilities help ensure the app is accessible to users with
/// visual impairments, motor disabilities, or other accessibility needs.

// =============================================================================
// CONSTANTS
// =============================================================================

/// Minimum touch target size as per WCAG guidelines (48x48 dp).
const double kMinTouchTarget = 48.0;

/// Minimum contrast ratio for normal text (4.5:1).
const double kMinContrastRatioNormal = 4.5;

/// Minimum contrast ratio for large text (3:1).
const double kMinContrastRatioLarge = 3.0;

// =============================================================================
// SEMANTIC WRAPPERS
// =============================================================================

/// Wraps a widget with semantic information for screen readers.
///
/// Usage:
/// ```dart
/// SemanticWrapper(
///   label: 'Add to cart button',
///   hint: 'Double tap to add item to cart',
///   isButton: true,
///   child: AddButton(),
/// )
/// ```
class SemanticWrapper extends StatelessWidget {
  final Widget child;
  final String? label;
  final String? hint;
  final String? value;
  final bool isButton;
  final bool isHeader;
  final bool isLink;
  final bool isImage;
  final bool isTextField;
  final bool isSlider;
  final bool isToggled;
  final bool? toggled;
  final bool excludeSemantics;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  const SemanticWrapper({
    super.key,
    required this.child,
    this.label,
    this.hint,
    this.value,
    this.isButton = false,
    this.isHeader = false,
    this.isLink = false,
    this.isImage = false,
    this.isTextField = false,
    this.isSlider = false,
    this.isToggled = false,
    this.toggled,
    this.excludeSemantics = false,
    this.onTap,
    this.onLongPress,
    this.onIncrease,
    this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    if (excludeSemantics) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: isButton,
      header: isHeader,
      link: isLink,
      image: isImage,
      textField: isTextField,
      slider: isSlider,
      toggled: isToggled ? toggled : null,
      onTap: onTap,
      onLongPress: onLongPress,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      child: child,
    );
  }
}

/// A button with proper semantic labeling and minimum touch target.
///
/// Usage:
/// ```dart
/// AccessibleButton(
///   label: 'Add to cart',
///   onPressed: () => addToCart(),
///   child: Icon(Icons.add),
/// )
/// ```
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double minSize;
  final EdgeInsetsGeometry? padding;

  const AccessibleButton({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onPressed,
    this.onLongPress,
    this.minSize = kMinTouchTarget,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      onLongPress: onLongPress,
      child: InkWell(
        onTap: onPressed,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(minSize / 2),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(8),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// A tappable card with proper semantic labeling.
///
/// Usage:
/// ```dart
/// AccessibleCard(
///   label: 'Coffee Shop - 4.5 stars - 500m away',
///   hint: 'Double tap to view menu',
///   onTap: () => openShop(),
///   child: ShopCard(),
/// )
/// ```
class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AccessibleCard({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: onTap != null,
      onTap: onTap,
      onLongPress: onLongPress,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      ),
    );
  }
}

/// An image with proper semantic labeling.
///
/// Usage:
/// ```dart
/// AccessibleImage(
///   image: NetworkImage(url),
///   label: 'Iced Latte - tall glass with coffee and milk',
/// )
/// ```
class AccessibleImage extends StatelessWidget {
  final ImageProvider image;
  final String label;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AccessibleImage({
    super.key,
    required this.image,
    required this.label,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      image: true,
      child: Image(
        image: image,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                ),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported),
              );
        },
      ),
    );
  }
}

// =============================================================================
// ACCESSIBILITY HELPERS
// =============================================================================

/// Helper class for accessibility-related utilities.
class AccessibilityHelper {
  AccessibilityHelper._();

  /// Check if accessibility features are enabled.
  static bool isAccessibilityEnabled(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.accessibleNavigation ||
        mediaQuery.boldText ||
        mediaQuery.textScaler.scale(1.0) > 1.0;
  }

  /// Check if bold text is enabled.
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Check if reduce motion is enabled.
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get appropriate animation duration based on reduce motion setting.
  static Duration getAnimationDuration(
    BuildContext context, {
    Duration normal = const Duration(milliseconds: 300),
    Duration reduced = Duration.zero,
  }) {
    return isReduceMotionEnabled(context) ? reduced : normal;
  }

  /// Get text scale factor.
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// Announce a message to screen readers.
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, Directionality.of(context));
  }

  /// Calculate luminance-based contrast ratio between two colors.
  static double calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();

    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA standards for normal text.
  static bool meetsContrastStandard(
    Color foreground,
    Color background, {
    bool isLargeText = false,
  }) {
    final ratio = calculateContrastRatio(foreground, background);
    return ratio >=
        (isLargeText ? kMinContrastRatioLarge : kMinContrastRatioNormal);
  }
}

// =============================================================================
// FOCUS MANAGEMENT
// =============================================================================

/// A widget that manages focus for accessibility.
///
/// Use this to ensure proper focus order and keyboard navigation.
class FocusableWidget extends StatefulWidget {
  final Widget child;
  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onFocusChange;

  const FocusableWidget({
    super.key,
    required this.child,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChange,
  });

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus != _hasFocus) {
      setState(() => _hasFocus = _focusNode.hasFocus);
      widget.onFocusChange?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      child: Container(
        decoration:
            _hasFocus
                ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
                : null,
        child: widget.child,
      ),
    );
  }
}

// =============================================================================
// SKIP NAVIGATION
// =============================================================================

/// A skip navigation link for keyboard users.
///
/// Usage at the top of your scaffold:
/// ```dart
/// SkipToContent(
///   label: 'Skip to main content',
///   focusNode: mainContentFocusNode,
/// )
/// ```
class SkipToContent extends StatelessWidget {
  final String label;
  final FocusNode focusNode;

  const SkipToContent({
    super.key,
    this.label = 'Skip to main content',
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      onTap: () => focusNode.requestFocus(),
      child: Focus(
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            if (!hasFocus) {
              return const SizedBox.shrink();
            }

            return Material(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(label),
              ),
            );
          },
        ),
      ),
    );
  }
}

