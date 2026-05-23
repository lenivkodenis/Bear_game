import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlatformComponent extends PositionComponent {
  PlatformComponent({required super.position, required super.size});

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final snowPaint = Paint()..color = const Color(0xFFFFFFFF);
    final icePaint = Paint()..color = const Color(0xFF9BD3E8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, 16),
        const Radius.circular(8),
      ),
      snowPaint,
    );
    canvas.drawRect(Rect.fromLTWH(0, 14, size.x, size.y - 14), icePaint);
  }
}
