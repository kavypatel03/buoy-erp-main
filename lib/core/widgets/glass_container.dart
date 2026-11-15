import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';

/// High-performance iOS Liquid Glass container.
/// • Blur disabled by default on list items for 90/120 fps scrolling.
/// • Fully theme-aware (dark/light).
/// • Single lightweight shadow, const-friendly.
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
  final bool enableBlur;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.blur = 10,          // Optimized lightweight blur when enabled
    this.opacity = 0.82,     // Translucent liquid glass
    this.backgroundColor,
    this.isCircle = false,
    this.border,
    this.useGradientBorder = true,
    this.alignment,
    this.onTap,
    this.enableBlur = false, // Disabled by default for silky smooth 60-120 FPS on 2GB/4GB devices
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scale;
  Animation<double>? _opacity;

  @override
  void initState() {
    super.initState();
    if (widget.onTap != null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 90),
        reverseDuration: const Duration(milliseconds: 120),
      );
      _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
      _opacity = Tween<double>(begin: 1.0, end: 0.82).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller?.forward();
  void _onTapUp(TapUpDetails _) {
    _controller?.reverse();
    widget.onTap?.call();
  }
  void _onTapCancel() => _controller?.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Surface color: fully opaque cards for readability
    final Color bg = widget.backgroundColor ??
        (isDark ? AppColors.darkCard : Colors.white);

    final effectiveRadius = widget.isCircle
        ? (widget.width != null ? widget.width! / 2 : 50.0)
        : widget.borderRadius;

    final shapeBorderRadius =
        widget.isCircle ? null : BorderRadius.circular(effectiveRadius);

    final effectiveBorder = widget.border ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.75),
          width: 1.1,
        );

    // ── Inner container ──────────────────────────────────────────────────────
    Widget inner = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: widget.opacity.clamp(0.0, 1.0)),
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: shapeBorderRadius,
        border: effectiveBorder,
      ),
      child: widget.child,
    );

    // Apply BackdropFilter only when explicitly requested
    if (widget.enableBlur && widget.blur > 0) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: inner,
        ),
      );
    } else {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: inner,
      );
    }

    // ── Outer shadow wrapper ─────────────────────────────────────────────────
    Widget container = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      alignment: widget.alignment,
      decoration: BoxDecoration(
        borderRadius: shapeBorderRadius,
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: inner,
    );

    // ── Tap animation ────────────────────────────────────────────────────────
    if (widget.onTap != null &&
        _controller != null &&
        _scale != null &&
        _opacity != null) {
      return GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _controller!,
          builder: (_, child) => Transform.scale(
            scale: _scale!.value,
            child: Opacity(opacity: _opacity!.value, child: child),
          ),
          child: container,
        ),
      );
    }

    return container;
  }
}
