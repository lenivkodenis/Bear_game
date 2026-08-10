import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/components/mentor_visual_component.dart';
import '../game/components/player_bear.dart';
import '../game/level_geometry.dart';

class VisualTestCollisionOverlay extends PositionComponent {
  VisualTestCollisionOverlay({
    required LevelGeometry Function() geometry,
    required PlayerBear Function() player,
    required MentorVisualComponent Function() mentor,
  }) : _geometry = geometry,
       _player = player,
       _mentor = mentor,
       super(priority: 20000);

  final LevelGeometry Function() _geometry;
  final PlayerBear Function() _player;
  final MentorVisualComponent Function() _mentor;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final geometry = _geometry();
    final player = _player();
    final mentor = _mentor();

    for (final collider in geometry.groundColliders) {
      _drawRect(
        canvas,
        collider,
        fill: const Color(0x2634C759),
        stroke: const Color(0xFF34C759),
      );
    }
    for (final collider in geometry.obstacleColliders) {
      _drawRect(
        canvas,
        collider,
        fill: const Color(0x33FF453A),
        stroke: const Color(0xFFFF453A),
      );
    }

    final playerRect = player.collisionBounds;
    canvas.drawRect(
      playerRect,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(playerRect.left, playerRect.bottom),
      Offset(playerRect.right, playerRect.bottom),
      Paint()
        ..color = const Color(0xFFFF2D55)
        ..strokeWidth = 3,
    );

    canvas.drawCircle(
      mentor.interactionPoint.toOffset(),
      mentor.spec.interactionRadius,
      Paint()
        ..color = const Color(0xFFFF9F0A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawRect(
    Canvas canvas,
    LevelGeometryCollider collider, {
    required Color fill,
    required Color stroke,
  }) {
    final rect = Rect.fromLTWH(
      collider.x,
      collider.y,
      collider.width,
      collider.height,
    );
    canvas.drawRect(rect, Paint()..color = fill);
    canvas.drawRect(
      rect,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
