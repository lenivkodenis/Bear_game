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

  group('bear idle state', () {
    test('inactive grounded bear remains idle after several seconds', () {
      final bear = createBear();

      bear.update(2.99);
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(3.5);
      expect(bear.animationState, BearAnimationState.idle);
      expect(bear.visualFeetY, closeTo(groundY, 0.001));
    });

    test('movement and jump still leave idle immediately', () {
      final bear = createBear();

      bear.update(3.5);
      expect(bear.animationState, BearAnimationState.idle);

      bear.moveRight();
      bear.update(0.1);
      expect(bear.animationState, BearAnimationState.walk);

      bear.stopMoving();
      bear.jump();
      expect(bear.animationState, BearAnimationState.jump);
    });

    test('airborne bear returns to idle after landing', () {
      final bear = createBear(airborneOffset: 20);

      bear.update(1.0);
      expect(bear.animationState, BearAnimationState.idle);

      bear.landOnSurface(groundY);
      bear.update(3.5);
      expect(bear.animationState, BearAnimationState.idle);
    });
  });
}
