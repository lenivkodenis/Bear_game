import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:bear_game/game/obstacle_collision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level 5 ice cave route uses reachable stepped ground', () {
    final geometry =
        jsonDecode(File('assets/data/level_geometry.json').readAsStringSync())
            as Map<String, Object?>;
    final levels = geometry['levels']! as List<Object?>;
    final levelFive = levels.cast<Map<String, Object?>>().singleWhere(
      (level) => level['levelId'] == 5,
    );
    final grounds = (levelFive['groundColliders']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .toList(growable: false);
    final obstacles = (levelFive['obstacleColliders']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .toList(growable: false);

    expect((levelFive['playerSpawn']! as Map<String, Object?>)['y'], 409);
    expect((levelFive['mentorPosition']! as Map<String, Object?>)['y'], 405);
    expect(grounds.map((ground) => ground['id']), <String>[
      'ground_left_shelf',
      'ground_lower_ice_floor',
      'ground_middle_step',
      'ground_right_shelf',
    ]);
    expect(grounds.map((ground) => ground['y']), <num>[409, 493, 424, 405]);

    const jumpImpulse = 410.0;
    const gravity = 820.0;
    const safetyMargin = 25.0;
    const maxJumpHeight = jumpImpulse * jumpImpulse / (2 * gravity);

    final lowerToMiddleStep =
        (grounds[1]['y']! as num).toDouble() -
        (grounds[2]['y']! as num).toDouble();
    final middleToRightStep =
        (grounds[2]['y']! as num).toDouble() -
        (grounds[3]['y']! as num).toDouble();

    expect(lowerToMiddleStep, lessThanOrEqualTo(maxJumpHeight - safetyMargin));
    expect(middleToRightStep, lessThanOrEqualTo(maxJumpHeight - safetyMargin));
    expect(obstacles, hasLength(1));

    final obstacle = obstacles.single;
    final slope = SlopedObstacleSurface(
      bounds: Rect.fromLTWH(
        (obstacle['x']! as num).toDouble(),
        (obstacle['y']! as num).toDouble(),
        (obstacle['width']! as num).toDouble(),
        (obstacle['height']! as num).toDouble(),
      ),
      surfaceYAtLeft: (obstacle['surfaceYAtLeft']! as num).toDouble(),
      surfaceYAtRight: (obstacle['surfaceYAtRight']! as num).toDouble(),
      edgeCapture: (obstacle['edgeCapture']! as num).toDouble(),
    );

    expect(obstacle['id'], 'ice_slab_slope');
    expect(slope.edgeCapture, 0);
    expect(slope.surfaceYAt(slope.bounds.left), 378);
    expect(slope.surfaceYAt(slope.bounds.right), 424);
  });

  test('level 5 jump clears the ice slab slope onto the right shelf', () {
    const playerWidth = 78.0;
    const playerHeight = 92.0;
    const moveSpeed = 160.0;
    const jumpImpulse = -410.0;
    const gravity = 820.0;
    const dt = 1 / 120;
    const middleGroundY = 424.0;
    const rightGroundY = 405.0;
    const rightGroundLeft = 603.0;

    const slope = SlopedObstacleSurface(
      bounds: Rect.fromLTWH(493, 378, 110, 46),
      surfaceYAtLeft: 378,
      surfaceYAtRight: 424,
      edgeCapture: 0,
    );

    var previousPlayerRect = _playerRect(
      feetX: slope.bounds.left - playerWidth / 2,
      bottom: middleGroundY,
      width: playerWidth,
      height: playerHeight,
    );
    var feetX = previousPlayerRect.center.dx;
    var bottomY = previousPlayerRect.bottom;
    var velocityY = jumpImpulse;
    double? slopeLandingY;
    double? rightShelfLandingX;

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

      slopeLandingY ??= findSlopedObstacleSurfaceContact(
        previousPlayerRect: previousPlayerRect,
        futurePlayerRect: futurePlayerRect,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
      );
      if (feetX >= rightGroundLeft &&
          previousPlayerRect.bottom <= rightGroundY + 3 &&
          futurePlayerRect.bottom >= rightGroundY - 3) {
        rightShelfLandingX = feetX;
        break;
      }

      previousPlayerRect = futurePlayerRect;
    }

    expect(slopeLandingY, isNull);
    expect(rightShelfLandingX, isNotNull);
    expect(rightShelfLandingX!, inInclusiveRange(603, 630));
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
