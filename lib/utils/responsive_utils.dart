// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

/// Breakpoints for responsive design.
///
/// Mobile:  < 600px
/// Tablet:  600px - 1023px
/// Desktop: >= 1024px
class Breakpoints {
  Breakpoints._();

  static const double mobile = 0;
  static const double tablet = 600;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
}

/// Device type based on screen width.
enum DeviceType { mobile, tablet, desktop }

/// Utility class for responsive design.
///
/// Usage:
/// ```dart
/// final responsive = ResponsiveUtils.of(context);
///
/// // Check device type
/// if (responsive.isMobile) { ... }
///
/// // Get responsive value
/// final columns = responsive.value(mobile: 2, tablet: 3, desktop: 4);
///
/// // Get responsive padding
/// final padding = responsive.padding;
/// ```
class ResponsiveUtils {
  final BuildContext context;
  late final Size _screenSize;
  late final double _width;
  late final double _height;
  late final EdgeInsets _padding;
  late final double _textScaleFactor;

  ResponsiveUtils._(this.context) {
    final mediaQuery = MediaQuery.of(context);
    _screenSize = mediaQuery.size;
    _width = _screenSize.width;
    _height = _screenSize.height;
    _padding = mediaQuery.padding;
    _textScaleFactor = mediaQuery.textScaler.scale(1.0);
  }

  /// Create a ResponsiveUtils instance.
  static ResponsiveUtils of(BuildContext context) => ResponsiveUtils._(context);

  // ---------------------------------------------------------------------------
  // GETTERS
  // ---------------------------------------------------------------------------

  /// Screen width in logical pixels.
  double get width => _width;

  /// Screen height in logical pixels.
  double get height => _height;

  /// Screen size.
  Size get screenSize => _screenSize;

  /// Safe area padding.
  EdgeInsets get safePadding => _padding;

  /// Text scale factor for accessibility.
  double get textScaleFactor => _textScaleFactor;

  /// Device type based on screen width.
  DeviceType get deviceType {
    if (_width >= Breakpoints.desktop) return DeviceType.desktop;
    if (_width >= Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  /// Is mobile device.
  bool get isMobile => deviceType == DeviceType.mobile;

  /// Is tablet device.
  bool get isTablet => deviceType == DeviceType.tablet;

  /// Is desktop device.
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// Is large text mode enabled (accessibility).
  bool get isLargeText => _textScaleFactor > 1.3;

  /// Is portrait orientation.
  bool get isPortrait => _height > _width;

  /// Is landscape orientation.
  bool get isLandscape => _width > _height;

  // ---------------------------------------------------------------------------
  // RESPONSIVE VALUES
  // ---------------------------------------------------------------------------

  /// Get a value based on device type.
  T value<T>({required T mobile, T? tablet, T? desktop}) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }

  /// Get responsive padding.
  EdgeInsets get padding => EdgeInsets.symmetric(
    horizontal: value(mobile: 16.0, tablet: 24.0, desktop: 32.0),
  );

  /// Get responsive horizontal padding value.
  double get horizontalPadding =>
      value(mobile: 16.0, tablet: 24.0, desktop: 32.0);

  /// Get responsive grid column count.
  int get gridColumns => value(mobile: 2, tablet: 3, desktop: 4);

  /// Get responsive card width for grids.
  double get cardWidth {
    final columns = gridColumns;
    final totalPadding = horizontalPadding * 2 + (columns - 1) * 16;
    return (_width - totalPadding) / columns;
  }

  /// Get responsive max content width (for centering on large screens).
  double get maxContentWidth =>
      value(mobile: double.infinity, tablet: 720.0, desktop: 1200.0);

  /// Get responsive font scale multiplier.
  double get fontScale {
    // Clamp text scale factor to prevent extreme scaling
    return _textScaleFactor.clamp(0.8, 1.5);
  }

  // ---------------------------------------------------------------------------
  // SCALED VALUES
  // ---------------------------------------------------------------------------

  /// Scale a value based on screen width (relative to 375px base).
  double scale(double value) {
    const baseWidth = 375.0;
    return value * (_width / baseWidth).clamp(0.8, 1.5);
  }

  /// Scale a font size respecting accessibility settings.
  double scaleFont(double fontSize) {
    return fontSize * fontScale;
  }
}

/// A widget that rebuilds when screen size changes.
///
/// Usage:
/// ```dart
/// ResponsiveBuilder(
///   builder: (context, responsive) {
///     return responsive.isMobile
///         ? MobileLayout()
///         : TabletLayout();
///   },
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveUtils responsive)
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = ResponsiveUtils.of(context);
        return builder(context, responsive);
      },
    );
  }
}

/// A widget that shows different content based on device type.
///
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileView(),
///   tablet: TabletView(),
///   desktop: DesktopView(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        switch (responsive.deviceType) {
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.mobile:
            return mobile;
        }
      },
    );
  }
}

/// Constrained box that limits max width on large screens.
///
/// Usage:
/// ```dart
/// ResponsiveContainer(
///   child: MyContent(),
/// )
/// ```
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool center;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils.of(context);
    final effectiveMaxWidth = maxWidth ?? responsive.maxContentWidth;

    Widget result = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      child: child,
    );

    if (center && effectiveMaxWidth != double.infinity) {
      result = Center(child: result);
    }

    if (padding != null) {
      result = Padding(padding: padding!, child: result);
    }

    return result;
  }
}

/// A responsive grid that adjusts columns based on screen size.
///
/// Usage:
/// ```dart
/// ResponsiveGrid(
///   children: items.map((item) => ItemCard(item)).toList(),
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils.of(context);
    final columns = responsive.value(
      mobile: mobileColumns ?? 2,
      tablet: tabletColumns ?? 3,
      desktop: desktopColumns ?? 4,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: childAspectRatio ?? 1,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}
