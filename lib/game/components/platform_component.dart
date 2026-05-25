import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlatformComponent extends PositionComponent {
  PlatformComponent({required super.position, required super.size});
}

class IceObstacleComponent extends PositionComponent {
  IceObstacleComponent({required super.position, required super.size});

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = size.toRect();
    final moundPath = Path()
      ..moveTo(rect.left, rect.bottom)
      ..quadraticBezierTo(
        rect.left + rect.width * 0.16,
        rect.top + rect.height * 0.30,
        rect.left + rect.width * 0.34,
        rect.top + rect.height * 0.28,
      )
      ..quadraticBezierTo(
        rect.left + rect.width * 0.52,
        rect.top - rect.height * 0.02,
        rect.left + rect.width * 0.70,
        rect.top + rect.height * 0.26,
      )
      ..quadraticBezierTo(
        rect.left + rect.width * 0.88,
        rect.top + rect.height * 0.34,
        rect.right,
        rect.bottom,
      )
      ..close();

    final shadowPaint = Paint()..color = const Color(0xFF97D4E8);
    final fillPaint = Paint()..color = const Color(0xFFE9FAFF);
    final highlightPaint = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final outlinePaint = Paint()
      ..color = const Color(0xFF78BFD7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawPath(moundPath, shadowPaint);
    canvas.save();
    canvas.clipPath(moundPath);
    canvas.drawOval(
      Rect.fromLTWH(
        rect.left + rect.width * 0.08,
        rect.top + rect.height * 0.02,
        rect.width * 0.84,
        rect.height * 0.82,
      ),
      fillPaint,
    );
    canvas.restore();

    final highlightPath = Path()
      ..moveTo(rect.left + rect.width * 0.18, rect.top + rect.height * 0.54)
      ..quadraticBezierTo(
        rect.left + rect.width * 0.46,
        rect.top + rect.height * 0.22,
        rect.left + rect.width * 0.74,
        rect.top + rect.height * 0.46,
      );

    canvas.drawPath(highlightPath, highlightPaint);
    canvas.drawPath(moundPath, outlinePaint);
  }
}
