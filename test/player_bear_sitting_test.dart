import 'package:bear_game/game/components/player_bear.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const groundY = 500.0;
  const levelWidth = 800.0;

  PlayerBear createBear({double airborneOffset = 0}) {
    return PlayerBear(
      position: Vector2(
        100,
        groundY - PlayerBear.defaultSize.y - airborneOffset,
      ),
      groundY: groundY,
      levelWidth: levelWidth,
    );
  }

  group('bear sitting behavior is disabled', () {
    test('idle timer no longer starts sitting down', () {
      final bear = createBear();

      bear.update(2.99);
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(0.02);
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(10.0);
      expect(bear.animationState, BearAnimationState.idle);
    });

    test('movement still works after long idle time', () {
      final bear = createBear();

      bear.update(10.0);
      expect(bear.animationState, BearAnimationState.idle);

      bear.moveRight();
      bear.update(0.1);
      expect(bear.animationState, BearAnimationState.walk);

      bear.stopMoving();
    });

    test('jump still works after long idle time', () {
      final bear = createBear();

      bear.update(10.0);
      expect(bear.animationState, BearAnimationState.idle);

      bear.jump();
      expect(bear.animationState, BearAnimationState.jump);

      bear.landOnSurface(groundY);
      bear.update(10.0);
      expect(bear.animationState, BearAnimationState.idle);
    });

    test('airborne idle checks do not start sitting down', () {
      final bear = createBear(airborneOffset: 20);

      bear.update(1.0);
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(10.0);
      expect(bear.animationState, BearAnimationState.idle);
    });

    test('explicit sitting request keeps the bear in normal idle behavior', () {
      final bear = createBear();

      bear.startSitting();
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(10.0);
      expect(bear.animationState, BearAnimationState.idle);
    });

    test(
      'movement after explicit sitting request starts walking immediately',
      () {
        final bear = createBear();

        bear.startSitting();
        bear.moveRight();

        expect(bear.animationState, BearAnimationState.walk);
      },
    );

    test('jump after explicit sitting request starts jumping immediately', () {
      final bear = createBear();

      bear.startSitting();
      bear.jump();

      expect(bear.animationState, BearAnimationState.jump);
    });
  });
}
