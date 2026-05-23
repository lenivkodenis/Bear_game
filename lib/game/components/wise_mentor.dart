import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WiseMentor extends PositionComponent {
  WiseMentor({required super.position})
      : super(size: defaultSize, anchor: Anchor.topLeft);

  static final defaultSize = Vector2(56, 64);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bodyPaint = Paint()..color = const Color(0xFF7A8E9A);
    final bellyPaint = Paint()..color = const Color(0xFFECE7D5);
    final detailPaint = Paint()..color = const Color(0xFF1E2E38);
    final tuskPaint = Paint()..color = const Color(0xFFFFFAEA);

    canvas.drawOval(Rect.fromLTWH(4, 14, 48, 48), bodyPaint);
    canvas.drawOval(Rect.fromLTWH(12, 30, 32, 28), bellyPaint);
    canvas.drawCircle(const Offset(18, 28), 3, detailPaint);
    canvas.drawCircle(const Offset(38, 28), 3, detailPaint);
    canvas.drawOval(Rect.fromLTWH(21, 33, 14, 8), detailPaint);

    final leftTusk = Path()
      ..moveTo(22, 40)
      ..quadraticBezierTo(19, 52, 15, 58)
      ..quadraticBezierTo(24, 53, 26, 41)
      ..close();
    final rightTusk = Path()
      ..moveTo(34, 40)
      ..quadraticBezierTo(37, 52, 41, 58)
      ..quadraticBezierTo(32, 53, 30, 41)
      ..close();

    canvas.drawPath(leftTusk, tuskPaint);
    canvas.drawPath(rightTusk, tuskPaint);
  }
}
