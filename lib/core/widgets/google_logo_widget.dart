import 'package:flutter/material.dart';

class GoogleLogoWidget extends StatelessWidget {
  final double size;

  const GoogleLogoWidget({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleGLogoPainter(),
    );
  }
}

class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    // Blue: #4285F4
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    // Red: #EA4335
    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // Yellow: #FBBC05
    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;

    // Green: #34A853
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;

    final double strokeWidth = size.width * 0.22;
    final Rect rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Red Arc (top)
    canvas.drawArc(rect, -0.6, 2.2, true, redPaint);

    // Yellow Arc (left)
    canvas.drawArc(rect, 1.6, 1.2, true, yellowPaint);

    // Green Arc (bottom)
    canvas.drawArc(rect, 2.7, 1.1, true, greenPaint);

    // Blue Arc (right)
    canvas.drawArc(rect, -0.6, -1.0, true, bluePaint);

    // Blue bar across center
    final Rect barRect = Rect.fromLTWH(
      radius - strokeWidth * 0.2,
      radius - strokeWidth / 2,
      radius * 0.95,
      strokeWidth,
    );
    canvas.drawRect(barRect, bluePaint);

    // Inner white circle mask
    final Paint whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - strokeWidth, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
