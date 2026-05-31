import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bear_game/game/obstacle_collision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level 7 fallen bridge slope is reachable by jump', () {
    final geometry =
        jsonDecode(File('assets/data/level_geometry.json').readAsStringSync())
            as Map<String, Object?>;
    final levels = geometry['levels']! as List<Object?>;
    final levelSeven = levels.cast<Map<String, Object?>>().singleWhere(
      (level) => level['levelId'] == 7,
    );
    final obstacle =
        ((levelSeven['obstacleColliders']! as List<Object?>)
                .cast<Map<String, Object?>>())
            .single;
    final obstacleRect = Rect.fromLTWH(
      (obstacle['x']! as num).toDouble(),
      (obstacle['y']! as num).toDouble(),
      (obstacle['width']! as num).toDouble(),
      (obstacle['height']! as num).toDouble(),
    );
    final slopeSurface = SlopedObstacleSurface(
      bounds: obstacleRect,
      surfaceYAtLeft: (obstacle['surfaceYAtLeft']! as num).toDouble(),
      surfaceYAtRight: (obstacle['surfaceYAtRight']! as num).toDouble(),
      edgeCapture: (obstacle['edgeCapture']! as num).toDouble(),
    );

    expect(obstacle['id'], 'fallen_bridge_slope');
    expect(obstacleRect.left, 274);
    expect(obstacleRect.right, 420);
    expect(slopeSurface.edgeCapture, 0);
    expect(slopeSurface.surfaceYAt(obstacleRect.left), 386);
    expect(slopeSurface.surfaceYAt(obstacleRect.right), 426);

    const playerWidth = 78.0;
    const playerHeight = 92.0;
    const moveSpeed = 160.0;
    const jumpImpulse = -410.0;
    const gravity = 820.0;
    const dt = 1 / 120;
    const groundY = 464.0;

    expect(
      findSlopedObstacleTopSupport(
        playerRect: _playerRect(
          feetX: obstacleRect.left - 1,
          bottom: slopeSurface.surfaceYAt(obstacleRect.left),
          width: playerWidth,
          height: playerHeight,
        ),
        slopedSurfaces: [slopeSurface],
        horizontalVelocityX: moveSpeed,
      ),
      isNull,
    );

    var previousPlayerRect = _playerRect(
      feetX: obstacleRect.left - playerWidth / 2,
      bottom: groundY,
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
    expect(landingY!, inInclusiveRange(386, 426));
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
