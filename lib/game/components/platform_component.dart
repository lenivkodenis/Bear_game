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
    final ridgePath = Path()
      ..moveTo(rect.left, rect.bottom)
      ..quadraticBezierTo(
        rect.left + rect.width * 0.12,
        rect.top + rect.height * 0.30,
        rect.left + rect.width * 0.30,
        rect.top + rect.height * 0.24,
      )
      ..quadraticBezierTo(
        rect.left + rect.width * 0.52,
        rect.top - rect.height * 0.08,
        rect.left + rect.width * 0.72,
        rect.top + rect.height * 0.24,
      )
      ..quadraticBezierTo(
        rect.left + rect.width * 0.90,
        rect.top + rect.height * 0.34,
        rect.right,
        rect.bottom,
      )
      ..close();

    final fillPaint = Paint()..color = const Color(0xFFE6F8FF);
    final shadowPaint = Paint()..color = const Color(0xFF9ED7EA);
    final highlightPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final outlinePaint = Paint()
      ..color = const Color(0xFF7FC5DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(ridgePath, shadowPaint);
    canvas.save();
    canvas.clipPath(ridgePath);
    canvas.drawOval(
      Rect.fromLTWH(
        rect.left + rect.width * 0.08,
        rect.top - rect.height * 0.10,
        rect.width * 0.84,
        rect.height * 0.92,
      ),
      fillPaint,
    );
    canvas.restore();

    final highlightPath = Path()
      ..moveTo(rect.left + rect.width * 0.18, rect.top + rect.height * 0.48)
      ..quadraticBezierTo(
        rect.left + rect.width * 0.44,
        rect.top + rect.height * 0.16,
        rect.left + rect.width * 0.72,
        rect.top + rect.height * 0.42,
      );
    canvas.drawPath(highlightPath, highlightPaint);
    canvas.drawPath(ridgePath, outlinePaint);
  }
}
