import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable iOS Liquid Glass container with intense frosted blur,
/// translucent fill, directional rim lighting (borders), and iOS-style touch effects.
class GlassContainer extends StatefulWidget {
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
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 22,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur = 32, // Intense blur for liquid glass
    this.opacity = 0.45, // Translucent fill
    this.backgroundColor,
    this.isCircle = false,
    this.border,
    this.useGradientBorder = false,
    this.alignment,
    this.onTap,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.isCircle
        ? (widget.width != null ? widget.width! / 2 : 50.0)
        : widget.borderRadius;

    Widget container = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      alignment: widget.alignment,
      decoration: BoxDecoration(
        borderRadius: widget.isCircle ? null : BorderRadius.circular(effectiveRadius),
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF5B3DF5).withValues(alpha: 0.04),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.isCircle
            ? BorderRadius.circular(effectiveRadius)
            : BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: (widget.backgroundColor ?? Colors.white).withValues(alpha: widget.opacity),
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle ? null : BorderRadius.circular(effectiveRadius),
              border: widget.border ??
                  Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
                    left: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.2),
                    right: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
                  ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      container = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: child,
              ),
            );
          },
          child: container,
        ),
      );
    }

    return container;
  }
}
