import 'dart:ui';
import 'package:flutter/material.dart';

class LiquidGlassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const LiquidGlassToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 54,
        height: 30,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value 
                    ? const Color(0xFF5B3DF5).withValues(alpha: 0.5) 
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(15),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.0),
                  left: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.0),
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
