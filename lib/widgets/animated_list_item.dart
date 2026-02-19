// lib/widgets/animated_list_item.dart
import 'package:flutter/material.dart';

/// A widget that animates its child with a staggered fade and slide effect.
///
/// Usage in a ListView:
/// ```dart
/// ListView.builder(
///   itemCount: items.length,
///   itemBuilder: (context, index) {
///     return AnimatedListItem(
///       index: index,
///       child: MyItemWidget(items[index]),
///     );
///   },
/// )
/// ```
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;
  final Duration animationDuration;
  final Offset slideOffset;
  final Curve curve;
  final bool animate;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 400),
    this.slideOffset = const Offset(0, 0.1),
    this.curve = Curves.easeOutCubic,
    this.animate = true,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.animate) {
      // Stagger the animation based on index
      Future.delayed(widget.staggerDelay * widget.index, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

/// A widget that fades in its child with optional scale animation.
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool fadeIn;
  final bool scaleIn;
  final double initialScale;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.fadeIn = true,
    this.scaleIn = false,
    this.initialScale = 0.95,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _scaleAnimation = Tween<double>(
      begin: widget.initialScale,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Widget result = Opacity(
          opacity: widget.fadeIn ? _fadeAnimation.value : 1,
          child: widget.child,
        );

        if (widget.scaleIn) {
          result = Transform.scale(scale: _scaleAnimation.value, child: result);
        }

        return result;
      },
    );
  }
}

/// Slide direction for SlideInWidget
enum SlideDirection { left, right, up, down }

/// A widget that slides in from a direction.
class SlideInWidget extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double distance;

  const SlideInWidget({
    super.key,
    required this.child,
    this.direction = SlideDirection.up,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.distance = 30,
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case SlideDirection.left:
        return Offset(-widget.distance, 0);
      case SlideDirection.right:
        return Offset(widget.distance, 0);
      case SlideDirection.up:
        return Offset(0, widget.distance);
      case SlideDirection.down:
        return Offset(0, -widget.distance);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _slideAnimation = Tween<Offset>(
      begin: _getBeginOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(opacity: _fadeAnimation.value, child: widget.child),
        );
      },
    );
  }
}
