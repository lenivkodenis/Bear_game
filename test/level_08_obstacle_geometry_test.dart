import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bear_game/game/obstacle_collision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level 8 snow obstacles are reachable by jump', () {
    final geometry =
        jsonDecode(File('assets/data/level_geometry.json').readAsStringSync())
            as Map<String, Object?>;
    final levels = geometry['levels']! as List<Object?>;
    final levelEight = levels.cast<Map<String, Object?>>().singleWhere(
      (level) => level['levelId'] == 8,
    );
    final obstacles = (levelEight['obstacleColliders']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .toList(growable: false);
    final obstacleRects = obstacles
        .map(
          (obstacle) => Rect.fromLTWH(
            (obstacle['x']! as num).toDouble(),
            (obstacle['y']! as num).toDouble(),
            (obstacle['width']! as num).toDouble(),
            (obstacle['height']! as num).toDouble(),
          ),
        )
        .toList(growable: false);

    expect(obstacleRects, hasLength(2));
    expect(obstacleRects.first.top, 409);

    final slopeObstacle = obstacles.last;
    final slopeSurface = SlopedObstacleSurface(
      bounds: obstacleRects.last,
      surfaceYAtLeft: (slopeObstacle['surfaceYAtLeft']! as num).toDouble(),
      surfaceYAtRight: (slopeObstacle['surfaceYAtRight']! as num).toDouble(),
    );

    const playerWidth = 78.0;
    const playerHeight = 92.0;
    const moveSpeed = 160.0;
    const jumpImpulse = -410.0;
    const gravity = 820.0;
    const dt = 1 / 120;

    final firstObstacle = obstacleRects.first;
    var previousPlayerRect = _playerRect(
      feetX: firstObstacle.right,
      bottom: firstObstacle.top,
      width: playerWidth,
      height: playerHeight,
    );
    var feetX = previousPlayerRect.center.dx;
    var bottomY = previousPlayerRect.bottom;
    var velocityY = jumpImpulse;

    double? landingY;
    for (var frame = 0; frame < 240; frame += 1) {
      feetX += moveSpeed * dt;
      velocityY += gravity * dt;
      bottomY += velocityY * dt;
      final futurePlayerRect = _playerRect(
        feetX: feetX,
        bottom: bottomY,
        width: playerWidth,
        height: playerHeight,
      );

      landingY = findSlopedObstacleSurfaceContact(
        previousPlayerRect: previousPlayerRect,
        futurePlayerRect: futurePlayerRect,
        slopedSurfaces: [slopeSurface],
      );
      if (landingY != null) {
        break;
      }

      previousPlayerRect = futurePlayerRect;
    }

    expect(landingY, isNotNull);
    expect(landingY!, inInclusiveRange(398, 425));
  });
}

Rect _playerRect({
  required double feetX,
  required double bottom,
  required double width,
  required double height,
}) {
  return Rect.fromLTWH(feetX - width / 2, bottom - height, width, height);
}
