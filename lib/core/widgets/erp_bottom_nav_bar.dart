import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErpBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final PageController? pageController;

  const ErpBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.pageController,
  });

  @override
  State<ErpBottomNavBar> createState() => _ErpBottomNavBarState();
}

class _ErpBottomNavBarState extends State<ErpBottomNavBar> with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  double? _dragPositionX;
  int _lastHapticIndex = -1;

  @override
  void initState() {
    super.initState();
    _lastHapticIndex = widget.currentIndex;
  }

  void _handleDragStart(DragStartDetails details, double maxWidth) {
    setState(() {
      _isDragging = true;
      _dragPositionX = details.localPosition.dx.clamp(0.0, maxWidth);
    });
    HapticFeedback.selectionClick();
  }

  void _handleDragUpdate(DragUpdateDetails details, double maxWidth) {
    final itemWidth = maxWidth / 5;
    final currentPos = details.localPosition.dx.clamp(0.0, maxWidth);
    final targetIndex = (currentPos / itemWidth).floor().clamp(0, 4);

    if (targetIndex != _lastHapticIndex) {
      _lastHapticIndex = targetIndex;
      HapticFeedback.selectionClick();
    }

    setState(() {
      _dragPositionX = currentPos;
    });
  }

  void _handleDragEnd(DragEndDetails details, double maxWidth) {
    if (_dragPositionX != null) {
      final itemWidth = maxWidth / 5;
      final targetIndex = (_dragPositionX! / itemWidth).floor().clamp(0, 4);
      if (widget.onTap != null) {
        widget.onTap!(targetIndex);
      }
    }
    setState(() {
      _isDragging = false;
      _dragPositionX = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      height: 74,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.black.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.06),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                final itemWidth = maxWidth / 5;
                const circleSize = 58.0;

                // Position calculation: either from live touch drag or selected tab index
                final double targetLeft;
                if (_isDragging && _dragPositionX != null) {
                  targetLeft = (_dragPositionX! - (circleSize / 2)).clamp(0.0, maxWidth - circleSize);
                } else {
                  targetLeft = (widget.currentIndex * itemWidth) + (itemWidth / 2) - (circleSize / 2);
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) => _handleDragStart(details, maxWidth),
                  onHorizontalDragUpdate: (details) => _handleDragUpdate(details, maxWidth),
                  onHorizontalDragEnd: (details) => _handleDragEnd(details, maxWidth),
                  child: Stack(
                    children: [
                      // Liquid Glass Sliding Blob
                      AnimatedPositioned(
                        duration: _isDragging ? const Duration(milliseconds: 40) : const Duration(milliseconds: 320),
                        curve: _isDragging ? Curves.linear : Curves.easeOutBack,
                        top: (constraints.maxHeight - circleSize) / 2,
                        left: targetLeft,
                        width: circleSize,
                        height: circleSize,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 150),
                          scale: _isDragging ? 1.15 : 1.0,
                          curve: Curves.easeInOut,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDarkMode
                                    ? [
                                        Colors.white.withValues(alpha: 0.25),
                                        Colors.white.withValues(alpha: 0.10),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.85),
                                        Colors.white.withValues(alpha: 0.50),
                                      ],
                              ),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.85),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF5B3DF5).withValues(alpha: 0.22),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Navigation Icons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', itemWidth),
                          _buildNavItem(1, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Inventory', itemWidth),
                          _buildNavItem(2, Icons.person_outline_rounded, Icons.person_rounded, 'Employee', itemWidth),
                          _buildNavItem(3, Icons.factory_outlined, Icons.factory_rounded, 'Factory', itemWidth),
                          _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded, 'Settings', itemWidth),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    double itemWidth,
  ) {
    // If currently dragging, visually highlight the tab closest to the finger
    final int activeIndex;
    if (_isDragging && _dragPositionX != null) {
      activeIndex = (_dragPositionX! / itemWidth).floor().clamp(0, 4);
    } else {
      activeIndex = widget.currentIndex;
    }

    final isSelected = activeIndex == index;
    const primaryColor = Color(0xFF5B3DF5);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        if (widget.onTap != null) widget.onTap!(index);
      },
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.12 : 1.0,
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? primaryColor : const Color(0xFF64748B),
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? primaryColor : const Color(0xFF64748B),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
