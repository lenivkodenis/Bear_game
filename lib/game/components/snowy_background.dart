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
      ..quadraticBezierTo(size.x * 0.78, size.y * 0.84, size.x, size.y * 0.68)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(hillPath, hillPaint);

    final farHillPaint = Paint()..color = const Color(0xFFD8EEF7);
    final farHillPath = Path()
      ..moveTo(0, size.y * 0.62)
      ..quadraticBezierTo(
        size.x * 0.18,
        size.y * 0.52,
        size.x * 0.38,
        size.y * 0.62,
      )
      ..quadraticBezierTo(size.x * 0.62, size.y * 0.74, size.x, size.y * 0.58)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(farHillPath, farHillPaint);
    canvas.drawPath(hillPath, hillPaint);

    final cloudPaint = Paint()..color = const Color(0xCCFFFFFF);
    _drawCloud(canvas, Offset(size.x * 0.18, size.y * 0.18), cloudPaint);
    _drawCloud(canvas, Offset(size.x * 0.78, size.y * 0.24), cloudPaint);

    final icePaint = Paint()..color = const Color(0xCCFFFFFF);
    final iceBorderPaint = Paint()
      ..color = const Color(0xFFBFEAFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final floe in _iceFloes) {
      final rect = Rect.fromCenter(
        center: Offset(size.x * floe.x, size.y * floe.y),
        width: floe.width,
        height: floe.height,
      );
      final radius = Radius.circular(floe.height / 2);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), icePaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), iceBorderPaint);
    }

    for (final flake in _flakes) {
      canvas.drawCircle(
        Offset(size.x * flake.x, size.y * flake.y),
        flake.radius,
        snowPaint,
      );
    }
  }

  void _drawCloud(Canvas canvas, Offset center, Paint paint) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 86, height: 28),
      paint,
    );
    canvas.drawCircle(center.translate(-28, -4), 18, paint);
    canvas.drawCircle(center.translate(2, -10), 24, paint);
    canvas.drawCircle(center.translate(30, -2), 16, paint);
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

  static const _iceFloes = [
    _IceFloe(0.18, 0.78, 92, 22),
    _IceFloe(0.52, 0.83, 122, 26),
    _IceFloe(0.84, 0.76, 78, 20),
  ];
}

class _SnowFlake {
  const _SnowFlake(this.x, this.y, this.radius);

  final double x;
  final double y;
  final double radius;
}

class _IceFloe {
  const _IceFloe(this.x, this.y, this.width, this.height);

  final double x;
  final double y;
  final double width;
  final double height;
}
