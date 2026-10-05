import 'dart:ui';
import 'package:flutter/material.dart';

class ErpBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const ErpBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      height: 74,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.45),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / 5;
                const circleSize = 58.0;
                final leftOffset = (currentIndex * itemWidth) + (itemWidth / 2) - (circleSize / 2);

                return Stack(
                  children: [
                    // Smooth sliding liquid glass blob
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.fastOutSlowIn,
                      top: (constraints.maxHeight - circleSize) / 2,
                      left: leftOffset,
                      width: circleSize,
                      height: circleSize,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.6),
                          border: Border.all(
                            color: isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Nav Items
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
    final isSelected = currentIndex == index;
    final primaryColor = const Color(0xFF5B3DF5);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (onTap != null) onTap!(index);
      },
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? primaryColor : const Color(0xFF64748B),
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
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
