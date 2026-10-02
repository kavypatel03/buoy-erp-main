import 'package:flutter/material.dart';

class BuoyLogoWidget extends StatelessWidget {
  final double fontSize;
  final bool showAsCard;
  final double? height;
  final double? size;

  const BuoyLogoWidget({
    super.key,
    this.fontSize = 24.0,
    this.showAsCard = true,
    this.height,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cardSize = size ?? 50.0;
    final imgHeight = height ?? (cardSize * 0.65);

    return Container(
      width: cardSize,
      height: cardSize,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 8,
            spreadRadius: -1,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: Center(
        child: Image.asset(
          'assets/icon/app_icon.png',
          height: imgHeight,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackTextLogo();
          },
        ),
      ),
    );
  }

  Widget _buildFallbackTextLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('b', style: TextStyle(fontFamily: 'Arial', fontSize: fontSize * 0.6, fontWeight: FontWeight.w900, color: const Color(0xFF2563EB), height: 0.85)),
            Transform.rotate(angle: 0.12, child: Text('u', style: TextStyle(fontFamily: 'Arial', fontSize: fontSize * 0.55, fontWeight: FontWeight.w900, color: const Color(0xFFEF4444), height: 0.85))),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('o', style: TextStyle(fontFamily: 'Arial', fontSize: fontSize * 0.6, fontWeight: FontWeight.w900, color: const Color(0xFFF59E0B), height: 0.85)),
            Transform.rotate(angle: -0.1, child: Text('y', style: TextStyle(fontFamily: 'Arial', fontSize: fontSize * 0.65, fontWeight: FontWeight.w900, color: const Color(0xFFEC4899), height: 0.85))),
            Text('!', style: TextStyle(fontFamily: 'Arial', fontSize: fontSize * 0.7, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), height: 0.85)),
          ],
        ),
      ],
    );
  }
}
