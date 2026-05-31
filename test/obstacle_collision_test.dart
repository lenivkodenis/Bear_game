import 'dart:io';
import 'dart:ui';

import 'package:bear_game/game/obstacle_collision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const obstacle = Rect.fromLTWH(537.70, 459, 90, 30);
  const slope = SlopedObstacleSurface(
    bounds: Rect.fromLTWH(425, 398, 136, 87),
    surfaceYAtLeft: 398,
    surfaceYAtRight: 428,
  );

  group('obstacle solid block collision', () {
    test('blocks a grounded player moving into the obstacle from the left', () {
      const previous = Rect.fromLTWH(459, 397, 78, 92);
      const future = Rect.fromLTWH(462, 397, 78, 92);

      final resolved = resolveObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
        minX: 0,
        maxX: 722,
      );

      expect(resolved.left, obstacle.left - future.width);
      expect(resolved.top, future.top);
      expect(resolved.bottom, future.bottom);
    });

    test(
      'blocks a grounded player moving into the obstacle from the right',
      () {
        const previous = Rect.fromLTWH(629, 397, 78, 92);
        const future = Rect.fromLTWH(626, 397, 78, 92);

        final resolved = resolveObstacleSideCollision(
          previousPlayerRect: previous,
          futurePlayerRect: future,
          obstacleRects: const <Rect>[obstacle],
          minX: 0,
          maxX: 722,
        );

        expect(resolved.left, obstacle.right);
        expect(resolved.top, future.top);
        expect(resolved.bottom, future.bottom);
      },
    );

    test('lands a falling player on the obstacle top', () {
      const previous = Rect.fromLTWH(548, 360, 78, 92);
      const future = Rect.fromLTWH(548, 370, 78, 92);

      final landing = findObstacleTopLanding(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
      );

      expect(landing, obstacle);
    });

    test('does not land when feet are outside obstacle width', () {
      const previous = Rect.fromLTWH(450, 360, 78, 92);
      const future = Rect.fromLTWH(450, 370, 78, 92);

      final landing = findObstacleTopLanding(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
      );

      expect(landing, isNull);
    });

    test('keeps top support while feet stay inside obstacle width', () {
      const playerOnTop = Rect.fromLTWH(548, 367, 78, 92);

      final support = findObstacleTopSupport(
        playerRect: playerOnTop,
        obstacleRects: const <Rect>[obstacle],
      );

      expect(support, obstacle);
      expect(feetXInsideObstacle(playerOnTop, obstacle), isTrue);
    });

    test('drops top support after walking past the obstacle edge', () {
      const playerPastRightEdge = Rect.fromLTWH(590, 367, 78, 92);

      final support = findObstacleTopSupport(
        playerRect: playerPastRightEdge,
        obstacleRects: const <Rect>[obstacle],
      );

      expect(support, isNull);
      expect(feetXInsideObstacle(playerPastRightEdge, obstacle), isFalse);
    });

    test('does not side-snap when walking off the obstacle top edge', () {
      const previous = Rect.fromLTWH(590, 367, 78, 92);
      const future = Rect.fromLTWH(593, 369, 78, 92);

      final resolved = resolveObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
        minX: 0,
        maxX: 722,
      );

      expect(future.overlaps(obstacle), isTrue);
      expect(feetXOutsideRightEdge(future, obstacle), isTrue);
      expect(resolved, future);
    });

    test('keeps falling past the right edge after leaving top tolerance', () {
      const previous = Rect.fromLTWH(604, 371, 78, 92);
      const future = Rect.fromLTWH(607, 374, 78, 92);

      final resolved = resolveObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
        minX: 0,
        maxX: 722,
      );

      expect(previous.bottom, greaterThan(obstacle.top + obstacleTopTolerance));
      expect(future.overlaps(obstacle), isTrue);
      expect(feetXOutsideRightEdge(future, obstacle), isTrue);
      expect(resolved, future);
    });

    test('keeps falling past the left edge after leaving top tolerance', () {
      const previous = Rect.fromLTWH(475, 371, 78, 92);
      const future = Rect.fromLTWH(472, 374, 78, 92);

      final resolved = resolveObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
        minX: 0,
        maxX: 722,
      );

      expect(previous.bottom, greaterThan(obstacle.top + obstacleTopTolerance));
      expect(future.overlaps(obstacle), isTrue);
      expect(feetXOutsideLeftEdge(future, obstacle), isTrue);
      expect(resolved, future);
    });

    test('blocks movement back into the obstacle after leaving the top', () {
      const previous = Rect.fromLTWH(607, 374, 78, 92);
      const future = Rect.fromLTWH(604, 377, 78, 92);

      final resolved = resolveObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
        minX: 0,
        maxX: 722,
      );

      expect(feetXOutsideRightEdge(future, obstacle), isTrue);
      expect(resolved.left, obstacle.right);
      expect(resolved.top, future.top);
    });

    test('does not apply when a level has no obstacle colliders', () {
      const previous = Rect.fromLTWH(459, 397, 78, 92);
      const future = Rect.fromLTWH(462, 397, 78, 92);

      final resolved = resolveObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[],
        minX: 0,
        maxX: 722,
      );

      expect(resolved, future);
    });

    test('side collision does not change vertical position', () {
      const previous = Rect.fromLTWH(459, 397, 78, 92);
      const future = Rect.fromLTWH(462, 397, 78, 92);

      final resolved = resolveObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
        minX: 0,
        maxX: 722,
      );

      expect(resolved.top, future.top);
      expect(resolved.height, future.height);
    });
  });

  group('sloped obstacle collision', () {
    test('snaps support upward while walking up the slope', () {
      final previousSurfaceY = slope.surfaceYAt(535);
      final futureSurfaceY = slope.surfaceYAt(520);
      final previous = _playerRect(feetX: 535, bottom: previousSurfaceY);
      final future = _playerRect(feetX: 520, bottom: previousSurfaceY);

      final contactY = findSlopedObstacleSurfaceContact(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
      );

      expect(futureSurfaceY, lessThan(previousSurfaceY));
      expect(contactY, futureSurfaceY);
    });

    test('does not side-block a player already on the slope surface', () {
      final previousSurfaceY = slope.surfaceYAt(535);
      final previous = _playerRect(feetX: 535, bottom: previousSurfaceY);
      final future = _playerRect(feetX: 520, bottom: previousSurfaceY);

      final resolved = resolveSlopedObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
        minX: 0,
        maxX: 722,
      );

      expect(resolved, future);
    });

    test('does not side-snap when jumping from the slope surface', () {
      final surfaceY = slope.surfaceYAt(520);
      final previous = _playerRect(feetX: 520, bottom: surfaceY);
      final future = _playerRect(feetX: 520, bottom: surfaceY - 10);

      final resolved = resolveSlopedObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
        minX: 0,
        maxX: 722,
      );

      expect(future.overlaps(slope.bounds), isTrue);
      expect(resolved, future);
    });

    test('does not side-snap while above the slope surface', () {
      final surfaceY = slope.surfaceYAt(520);
      final previous = _playerRect(feetX: 520, bottom: surfaceY - 14);
      final future = _playerRect(feetX: 520, bottom: surfaceY - 20);

      final resolved = resolveSlopedObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
        minX: 0,
        maxX: 722,
      );

      expect(future.overlaps(slope.bounds), isTrue);
      expect(resolved, future);
    });

    test('allows airborne approach onto the slope from the right', () {
      final previous = _playerRect(
        feetX: 585,
        bottom: slope.surfaceYAt(561) - 4,
      );
      final future = _playerRect(feetX: 575, bottom: slope.surfaceYAt(561) + 2);

      final resolved = resolveSlopedObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
        minX: 0,
        maxX: 722,
      );

      expect(future.center.dx, greaterThan(slope.bounds.right));
      expect(future.overlaps(slope.bounds), isTrue);
      expect(resolved, future);
    });

    test(
      'lands on the slope edge from the right before feet center enters',
      () {
        final previous = _playerRect(
          feetX: 585,
          bottom: slope.surfaceYAt(561) - 4,
        );
        final future = _playerRect(
          feetX: 575,
          bottom: slope.surfaceYAt(561) + 2,
        );

        final contactY = findSlopedObstacleSurfaceContact(
          previousPlayerRect: previous,
          futurePlayerRect: future,
          slopedSurfaces: const <SlopedObstacleSurface>[slope],
        );

        expect(future.center.dx, greaterThan(slope.bounds.right));
        expect(contactY, slope.surfaceYAt(561));
      },
    );

    test('does not keep slope support while feet center is outside edge', () {
      final player = _playerRect(
        feetX: 575,
        bottom: slope.surfaceYAt(slope.bounds.right),
      );

      final supportY = findSlopedObstacleTopSupport(
        playerRect: player,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
      );

      expect(player.center.dx, greaterThan(slope.bounds.right));
      expect(supportY, isNull);
    });

    test('keeps slope edge support while moving inward from the right', () {
      final player = _playerRect(
        feetX: 575,
        bottom: slope.surfaceYAt(slope.bounds.right),
      );

      final supportY = findSlopedObstacleTopSupport(
        playerRect: player,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
        horizontalVelocityX: -160,
      );

      expect(player.center.dx, greaterThan(slope.bounds.right));
      expect(supportY, slope.surfaceYAt(slope.bounds.right));
    });

    test('does not side-snap when walking off the slope edge', () {
      final previousSurfaceY = slope.surfaceYAt(555);
      final previous = _playerRect(feetX: 555, bottom: previousSurfaceY);
      final future = _playerRect(feetX: 565, bottom: previousSurfaceY + 2);

      final resolved = resolveSlopedObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
        minX: 0,
        maxX: 722,
      );

      expect(future.center.dx, greaterThan(slope.bounds.right));
      expect(future.overlaps(slope.bounds), isTrue);
      expect(resolved, future);
    });

    test('keeps falling away after leaving the slope edge', () {
      final previous = _playerRect(
        feetX: 565,
        bottom: slope.surfaceYAt(565) + 9,
      );
      final future = _playerRect(
        feetX: 575,
        bottom: slope.surfaceYAt(575) + 15,
      );

      final resolved = resolveSlopedObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
        minX: 0,
        maxX: 722,
      );

      expect(previous.center.dx, greaterThan(slope.bounds.right));
      expect(future.center.dx, greaterThan(slope.bounds.right));
      expect(future.overlaps(slope.bounds), isTrue);
      expect(resolved, future);
    });

    test('blocks walking into the slope body from the ground', () {
      const previous = Rect.fromLTWH(340, 393, 78, 92);
      const future = Rect.fromLTWH(350, 393, 78, 92);

      final resolved = resolveSlopedObstacleSideCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        slopedSurfaces: const <SlopedObstacleSurface>[slope],
        minX: 0,
        maxX: 722,
      );

      expect(resolved.left, slope.bounds.left - future.width);
      expect(resolved.top, future.top);
    });
  });

  test('player physics constants stay unchanged', () {
    final source = File(
      'lib/game/components/player_bear.dart',
    ).readAsStringSync();

    expect(source, contains('static const _moveSpeed = 160.0;'));
    expect(source, contains('static const _jumpImpulse = -410.0;'));
    expect(source, contains('static const _gravity = 820.0;'));
    expect(source, contains('static const _hitboxWidth = 78.0;'));
    expect(source, contains('static const _hitboxHeight = 92.0;'));
  });
}

Rect _playerRect({required double feetX, required double bottom}) {
  return Rect.fromLTWH(feetX - 39, bottom - 92, 78, 92);
}

bool feetXOutsideRightEdge(Rect playerRect, Rect obstacleRect) {
  return playerRect.center.dx > obstacleRect.right;
}

bool feetXOutsideLeftEdge(Rect playerRect, Rect obstacleRect) {
  return playerRect.center.dx < obstacleRect.left;
}
