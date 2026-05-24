import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum LevelGeometryDebugKind { ground, platform, obstacle, playerSpawn, mentor }

class PlatformComponent extends PositionComponent {
  PlatformComponent({
    required super.position,
    required super.size,
    this.id,
    this.debugKind = LevelGeometryDebugKind.ground,
    this.debugOverlay = false,
  });

  final String? id;
  final LevelGeometryDebugKind debugKind;
  final bool debugOverlay;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (!debugOverlay) {
      return;
    }

    final color = switch (debugKind) {
      LevelGeometryDebugKind.ground => const Color(0xFF1E88E5),
      LevelGeometryDebugKind.platform => const Color(0xFF43A047),
      LevelGeometryDebugKind.obstacle => const Color(0xFFE53935),
      LevelGeometryDebugKind.playerSpawn => const Color(0xFFFFB300),
      LevelGeometryDebugKind.mentor => const Color(0xFF8E24AA),
    };
    final fillPaint = Paint()..color = color.withValues(alpha: 0.20);
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = size.toRect();

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, strokePaint);

    if (debugKind == LevelGeometryDebugKind.playerSpawn ||
        debugKind == LevelGeometryDebugKind.mentor) {
      final center = rect.center;
      final markerPaint = Paint()
        ..color = color
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(center.dx - 6, center.dy),
        Offset(center.dx + 6, center.dy),
        markerPaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - 6),
        Offset(center.dx, center.dy + 6),
        markerPaint,
      );
    }
  }
}
