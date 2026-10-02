import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable high-contrast glassmorphism container with frosted blur,
/// strong ambient elevation shadows, and crisp contrast borders for clear visibility on white screens.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double blur;
  final double opacity;
  final Color? backgroundColor;
  final bool isCircle;
  final BoxBorder? border;
  final bool useGradientBorder;
  final AlignmentGeometry? alignment;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 22,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur = 16,
    this.opacity = 0.95,
    this.backgroundColor,
    this.isCircle = false,
    this.border,
    this.useGradientBorder = false,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = isCircle
        ? (width != null ? width! / 2 : 50.0)
        : borderRadius;

    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: isCircle ? null : BorderRadius.circular(effectiveRadius),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: [
          // Strong primary drop shadow for high contrast definition
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          // Soft ambient fill shadow for depth
          BoxShadow(
            color: const Color(0xFF5B3DF5).withValues(alpha: 0.05),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: isCircle
            ? BorderRadius.circular(effectiveRadius)
            : BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (backgroundColor ?? Colors.white).withValues(alpha: opacity),
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(effectiveRadius),
              border: border ??
                  Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
