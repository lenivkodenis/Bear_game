import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class IceRidgeObstacle extends PositionComponent {
  IceRidgeObstacle({required super.position, required super.size})
    : super(anchor: Anchor.topLeft);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final shadowPaint = Paint()..color = const Color(0x332E6F8F);
    final fillPaint = Paint()..color = const Color(0xFFEAF8FF);
    final sidePaint = Paint()..color = const Color(0xFFCBEFFF);
    final highlightPaint = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final outlinePaint = Paint()
      ..color = const Color(0xFF79BBD8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final width = size.x;
    final height = size.y;
    final baseY = height;
    final body = Path()
      ..moveTo(0, baseY)
      ..quadraticBezierTo(
        width * 0.06,
        height * 0.46,
        width * 0.24,
        height * 0.34,
      )
      ..quadraticBezierTo(
        width * 0.38,
        height * 0.02,
        width * 0.55,
        height * 0.22,
      )
      ..quadraticBezierTo(
        width * 0.72,
        height * 0.0,
        width * 0.88,
        height * 0.34,
      )
      ..quadraticBezierTo(width * 0.98, height * 0.5, width, baseY)
      ..close();

    canvas.drawOval(
      Rect.fromLTWH(width * 0.05, height * 0.82, width * 0.9, height * 0.18),
      shadowPaint,
    );
    canvas.drawPath(body, fillPaint);

    final side = Path()
      ..moveTo(width * 0.12, baseY)
      ..quadraticBezierTo(
        width * 0.3,
        height * 0.52,
        width * 0.52,
        height * 0.5,
      )
      ..quadraticBezierTo(width * 0.7, height * 0.56, width * 0.91, baseY)
      ..close();
    canvas.drawPath(side, sidePaint);
    canvas.drawPath(body, outlinePaint);

    canvas.drawArc(
      Rect.fromLTWH(width * 0.22, height * 0.18, width * 0.34, height * 0.3),
      3.6,
      1.6,
      false,
      highlightPaint,
    );
  }
}
