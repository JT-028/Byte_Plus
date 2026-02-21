// lib/widgets/cooking_loader.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A reusable Lottie cooking loader animation widget
/// Can be used as a loading indicator throughout the app
class CookingLoader extends StatelessWidget {
  final double size;
  final Color? backgroundColor;

  const CookingLoader({super.key, this.size = 60, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Lottie.asset(
          'assets/animation/Cooking_loader.json',
          width: size,
          height: size,
          fit: BoxFit.contain,
          repeat: true,
        ),
      ),
    );
  }
}

/// A full-screen loading overlay with the cooking animation
class CookingLoaderOverlay extends StatelessWidget {
  final double size;
  final String? message;

  const CookingLoaderOverlay({super.key, this.size = 100, this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.black54 : Colors.white70,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animation/Cooking_loader.json',
              width: size,
              height: size,
              fit: BoxFit.contain,
              repeat: true,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
