import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SnowyBackground extends PositionComponent {
  SnowyBackground({required Vector2 size}) : super(size: size);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFBFEAFF), Color(0xFFF8FDFF)],
      ).createShader(size.toRect());
    canvas.drawRect(size.toRect(), skyPaint);

    final hillPaint = Paint()..color = const Color(0xFFE5F4FA);
    final snowPaint = Paint()..color = const Color(0xFFFFFFFF);

    final hillPath = Path()
      ..moveTo(0, size.y * 0.72)
      ..quadraticBezierTo(
        size.x * 0.28,
        size.y * 0.58,
        size.x * 0.55,
        size.y * 0.72,
      )
      ..quadraticBezierTo(
        size.x * 0.78,
        size.y * 0.84,
        size.x,
        size.y * 0.68,
      )
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    for (final flake in _flakes) {
      canvas.drawCircle(
        Offset(size.x * flake.x, size.y * flake.y),
        flake.radius,
        snowPaint,
      );
    }
  }

  static const _flakes = [
    _SnowFlake(0.12, 0.16, 2),
    _SnowFlake(0.24, 0.36, 3),
    _SnowFlake(0.38, 0.22, 2),
    _SnowFlake(0.52, 0.42, 2),
    _SnowFlake(0.68, 0.18, 3),
    _SnowFlake(0.82, 0.32, 2),
    _SnowFlake(0.93, 0.48, 3),
  ];
}

class _SnowFlake {
  const _SnowFlake(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;
}
