// lib/widgets/loading_overlay.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A loading overlay that covers the entire screen.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     MainContent(),
///     if (isLoading) const LoadingOverlay(),
///   ],
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool dismissible;
  final VoidCallback? onDismiss;
  final Color? backgroundColor;
  final Widget? customLoader;

  const LoadingOverlay({
    super.key,
    this.message,
    this.dismissible = false,
    this.onDismiss,
    this.backgroundColor,
    this.customLoader,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: dismissible ? onDismiss : null,
      child: Container(
        color: backgroundColor ?? (isDark ? Colors.black54 : Colors.black45),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              customLoader ??
                  PulsingLoader(
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A pulsing circular loader animation.
class PulsingLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;

  const PulsingLoader({
    super.key,
    this.size = 48,
    this.color,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<PulsingLoader> createState() => _PulsingLoaderState();
}

class _PulsingLoaderState extends State<PulsingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 1,
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
    final color =
        widget.color ?? (isDark ? AppColors.primaryLight : AppColors.primary);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A simple dots loader animation.
class DotsLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;

  const DotsLoader({
    super.key,
    this.size = 8,
    this.color,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<DotsLoader> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(vsync: this, duration: widget.duration);
    });

    _animations =
        _controllers.map((controller) {
          return Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          );
        }).toList();

    // Start staggered animation
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        widget.color ?? (isDark ? AppColors.primaryLight : AppColors.primary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -4 * _animations[index].value),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// A heart pulse animation for favorites.
class HeartPulse extends StatefulWidget {
  final bool isActive;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onTap;

  const HeartPulse({
    super.key,
    required this.isActive,
    this.size = 24,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.grey,
    this.onTap,
  });

  @override
  State<HeartPulse> createState() => _HeartPulseState();
}

class _HeartPulseState extends State<HeartPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(HeartPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap?.call();
        if (!widget.isActive) {
          _controller.forward(from: 0);
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Icon(
              widget.isActive ? Icons.favorite : Icons.favorite_border,
              size: widget.size,
              color:
                  widget.isActive ? widget.activeColor : widget.inactiveColor,
            ),
          );
        },
      ),
    );
  }
}

/// A success checkmark animation.
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color? color;
  final Duration duration;
  final bool autoAnimate;

  const AnimatedCheckmark({
    super.key,
    this.size = 80,
    this.color,
    this.duration = const Duration(milliseconds: 500),
    this.autoAnimate = true,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      ),
    );

    if (widget.autoAnimate) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        widget.color ?? (isDark ? AppColors.successLight : AppColors.success);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: CustomPaint(
              painter: _CheckPainter(
                progress: _checkAnimation.value,
                color: Colors.white,
                strokeWidth: 4,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final start = Offset(center.dx - size.width * 0.2, center.dy);
    final middle = Offset(
      center.dx - size.width * 0.05,
      center.dy + size.height * 0.15,
    );
    final end = Offset(
      center.dx + size.width * 0.25,
      center.dy - size.height * 0.15,
    );

    final path = Path();
    path.moveTo(start.dx, start.dy);

    if (progress <= 0.5) {
      final t = progress * 2;
      final current = Offset.lerp(start, middle, t)!;
      path.lineTo(current.dx, current.dy);
    } else {
      path.lineTo(middle.dx, middle.dy);
      final t = (progress - 0.5) * 2;
      final current = Offset.lerp(middle, end, t)!;
      path.lineTo(current.dx, current.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
