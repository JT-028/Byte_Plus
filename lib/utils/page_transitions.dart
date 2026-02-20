// lib/utils/page_transitions.dart
import 'package:flutter/material.dart';

/// Custom page route with fade transition.
///
/// Usage:
/// ```dart
/// Navigator.push(context, FadeRoute(page: MyPage()));
/// ```
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;

  FadeRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           return FadeTransition(
             opacity: CurvedAnimation(parent: animation, curve: curve),
             child: child,
           );
         },
       );
}

/// Custom page route with slide transition.
///
/// Usage:
/// ```dart
/// Navigator.push(context, SlideRoute(page: MyPage()));
/// ```
class SlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;
  final SlideRouteDirection direction;

  SlideRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.direction = SlideRouteDirection.right,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           Offset begin;
           switch (direction) {
             case SlideRouteDirection.right:
               begin = const Offset(1, 0);
             case SlideRouteDirection.left:
               begin = const Offset(-1, 0);
             case SlideRouteDirection.up:
               begin = const Offset(0, 1);
             case SlideRouteDirection.down:
               begin = const Offset(0, -1);
           }

           return SlideTransition(
             position: Tween<Offset>(
               begin: begin,
               end: Offset.zero,
             ).animate(CurvedAnimation(parent: animation, curve: curve)),
             child: child,
           );
         },
       );
}

enum SlideRouteDirection { right, left, up, down }

/// Custom page route with scale and fade transition.
///
/// Usage:
/// ```dart
/// Navigator.push(context, ScaleFadeRoute(page: MyPage()));
/// ```
class ScaleFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;
  final double initialScale;

  ScaleFadeRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOutCubic,
    this.initialScale = 0.9,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: curve,
           );

           return FadeTransition(
             opacity: curvedAnimation,
             child: ScaleTransition(
               scale: Tween<double>(
                 begin: initialScale,
                 end: 1.0,
               ).animate(curvedAnimation),
               child: child,
             ),
           );
         },
       );
}

/// Custom page route with shared axis transition (Material Design).
///
/// Usage:
/// ```dart
/// Navigator.push(context, SharedAxisRoute(page: MyPage()));
/// ```
class SharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;
  final SharedAxisType type;

  SharedAxisRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.type = SharedAxisType.horizontal,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: curve,
           );

           final slideIn = Tween<Offset>(
             begin: _getBeginOffset(type),
             end: Offset.zero,
           ).animate(curvedAnimation);

           final slideOut = Tween<Offset>(
             begin: Offset.zero,
             end: _getEndOffset(type),
           ).animate(CurvedAnimation(parent: secondaryAnimation, curve: curve));

           return SlideTransition(
             position: slideIn,
             child: SlideTransition(
               position: slideOut,
               child: FadeTransition(opacity: curvedAnimation, child: child),
             ),
           );
         },
       );

  static Offset _getBeginOffset(SharedAxisType type) {
    switch (type) {
      case SharedAxisType.horizontal:
        return const Offset(0.3, 0);
      case SharedAxisType.vertical:
        return const Offset(0, 0.3);
      case SharedAxisType.scaled:
        return Offset.zero;
    }
  }

  static Offset _getEndOffset(SharedAxisType type) {
    switch (type) {
      case SharedAxisType.horizontal:
        return const Offset(-0.3, 0);
      case SharedAxisType.vertical:
        return const Offset(0, -0.3);
      case SharedAxisType.scaled:
        return Offset.zero;
    }
  }
}

enum SharedAxisType { horizontal, vertical, scaled }

/// Custom page route with bottom sheet-like slide up.
///
/// Usage:
/// ```dart
/// Navigator.push(context, SlideUpRoute(page: MyPage()));
/// ```
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final Curve curve;
  @override
  final bool fullscreenDialog;

  SlideUpRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeOutCubic,
    this.fullscreenDialog = true,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         fullscreenDialog: fullscreenDialog,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: curve,
           );

           return SlideTransition(
             position: Tween<Offset>(
               begin: const Offset(0, 1),
               end: Offset.zero,
             ).animate(curvedAnimation),
             child: child,
           );
         },
       );
}

/// Extension methods for easier navigation with custom transitions
extension NavigatorExtensions on NavigatorState {
  /// Push with fade transition
  Future<T?> pushFade<T extends Object?>(Widget page) {
    return push(FadeRoute<T>(page: page));
  }

  /// Push with slide transition
  Future<T?> pushSlide<T extends Object?>(
    Widget page, {
    SlideRouteDirection direction = SlideRouteDirection.right,
  }) {
    return push(SlideRoute<T>(page: page, direction: direction));
  }

  /// Push with scale and fade transition
  Future<T?> pushScaleFade<T extends Object?>(Widget page) {
    return push(ScaleFadeRoute<T>(page: page));
  }

  /// Push with slide up transition (like bottom sheet)
  Future<T?> pushSlideUp<T extends Object?>(Widget page) {
    return push(SlideUpRoute<T>(page: page));
  }
}
