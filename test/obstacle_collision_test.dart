import 'dart:io';
import 'dart:ui';

import 'package:bear_game/game/obstacle_collision.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const obstacle = Rect.fromLTWH(537.70, 442.25, 90, 46.75);

  group('obstacle side collision', () {
    test('blocks a grounded player moving into the obstacle from the left', () {
      const previous = Rect.fromLTWH(459, 397, 78, 92);
      const future = Rect.fromLTWH(462, 397, 78, 92);

      final resolved = resolveObstacleHorizontalCollision(
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

    test('allows a player above the obstacle top to pass over', () {
      const previous = Rect.fromLTWH(459, 352, 78, 92);
      const future = Rect.fromLTWH(462, 352, 78, 92);

      final resolved = resolveObstacleHorizontalCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
        minX: 0,
        maxX: 722,
      );

      expect(resolved, future);
      expect(
        blocksObstacleHorizontalMovement(
          futurePlayerRect: future,
          obstacleRect: obstacle,
        ),
        isFalse,
      );
    });

    test('does not apply when a level has no obstacle colliders', () {
      const previous = Rect.fromLTWH(459, 397, 78, 92);
      const future = Rect.fromLTWH(462, 397, 78, 92);

      final resolved = resolveObstacleHorizontalCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[],
        minX: 0,
        maxX: 722,
      );

      expect(resolved, future);
    });

    test('resolves to the nearest side without changing vertical position', () {
      const previous = Rect.fromLTWH(630, 397, 78, 92);
      const future = Rect.fromLTWH(625, 397, 78, 92);

      final resolved = resolveObstacleHorizontalCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
        minX: 0,
        maxX: 722,
      );

      expect(resolved.left, obstacle.right);
      expect(resolved.top, future.top);
      expect(resolved.height, future.height);
    });

    test('keeps the correction small for normal frame movement', () {
      const previous = Rect.fromLTWH(459, 397, 78, 92);
      const future = Rect.fromLTWH(462, 397, 78, 92);

      final resolved = resolveObstacleHorizontalCollision(
        previousPlayerRect: previous,
        futurePlayerRect: future,
        obstacleRects: const <Rect>[obstacle],
        minX: 0,
        maxX: 722,
      );

      expect((future.left - resolved.left).abs(), lessThan(4));
    });
  });

  test('player physics constants stay unchanged', () {
    final source = File(
      'lib/game/components/player_bear.dart',
    ).readAsStringSync();

    expect(source, contains('static const _moveSpeed = 160.0;'));
    expect(source, contains('static const _jumpImpulse = -360.0;'));
    expect(source, contains('static const _gravity = 820.0;'));
    expect(source, contains('static const _hitboxWidth = 78.0;'));
    expect(source, contains('static const _hitboxHeight = 92.0;'));
  });
}
