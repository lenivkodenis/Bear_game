import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bear_game/game/obstacle_collision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level 10 overturned boat is a reachable standard obstacle', () {
    final geometry =
        jsonDecode(File('assets/data/level_geometry.json').readAsStringSync())
            as Map<String, Object?>;
    final levels = geometry['levels']! as List<Object?>;
    final levelTen = levels.cast<Map<String, Object?>>().singleWhere(
      (level) => level['levelId'] == 10,
    );
    final obstacle =
        ((levelTen['obstacleColliders']! as List<Object?>)
                .cast<Map<String, Object?>>())
            .single;
    final obstacleRect = Rect.fromLTWH(
      (obstacle['x']! as num).toDouble(),
      (obstacle['y']! as num).toDouble(),
      (obstacle['width']! as num).toDouble(),
      (obstacle['height']! as num).toDouble(),
    );

    expect(obstacle['id'], 'overturned_boat');
    expect(obstacleRect.left, 293);
    expect(obstacleRect.top, 462);
    expect(obstacleRect.right, 473);
    expect(obstacleRect.bottom, 519);

    const playerWidth = 78.0;
    const playerHeight = 92.0;
    const moveSpeed = 160.0;
    const jumpImpulse = -410.0;
    const gravity = 820.0;
    const dt = 1 / 120;
    const groundY = 519.0;

    var previousPlayerRect = _playerRect(
      feetX: obstacleRect.left - playerWidth / 2,
      bottom: groundY,
      width: playerWidth,
      height: playerHeight,
    );
    var feetX = previousPlayerRect.center.dx;
    var bottomY = previousPlayerRect.bottom;
    var velocityY = jumpImpulse;

    Rect? landingObstacle;
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

      landingObstacle = findObstacleTopLanding(
        previousPlayerRect: previousPlayerRect,
        futurePlayerRect: futurePlayerRect,
        obstacleRects: [obstacleRect],
      );
      if (landingObstacle != null) {
        break;
      }

      previousPlayerRect = futurePlayerRect;
    }

    expect(landingObstacle, obstacleRect);
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
