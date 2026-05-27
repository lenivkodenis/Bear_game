import 'dart:io';

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

  void settleIntoSitting(PlayerBear bear) {
    bear.update(3.0);
    expect(bear.animationState, BearAnimationState.sitDown);

    bear.update(0.68);
    expect(bear.animationState, BearAnimationState.sitting);
  }

  group('bear idle sitting state machine', () {
    test('idle timer reaches 3 seconds and starts sitting down', () {
      final bear = createBear();

      bear.update(2.99);
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(0.02);
      expect(bear.animationState, BearAnimationState.sitDown);
    });

    test('movement before 3 seconds resets idle timer', () {
      final bear = createBear();

      bear.update(2.9);
      bear.moveRight();
      bear.update(0.1);
      expect(bear.animationState, BearAnimationState.walk);

      bear.stopMoving();
      bear.update(2.9);
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(0.11);
      expect(bear.animationState, BearAnimationState.sitDown);
    });

    test('jump resets idle timer', () {
      final bear = createBear();

      bear.update(2.9);
      bear.jump();
      expect(bear.animationState, BearAnimationState.jump);

      bear.landOnSurface(groundY);
      bear.update(2.9);
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(0.11);
      expect(bear.animationState, BearAnimationState.sitDown);
    });

    test('idle timer does not run while bear is in the air', () {
      final bear = createBear(airborneOffset: 20);

      bear.update(1.0);
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(2.9);
      expect(bear.animationState, BearAnimationState.idle);

      bear.update(0.11);
      expect(bear.animationState, BearAnimationState.sitDown);
    });

    test('sitting and movement input starts standing up before walking', () {
      final bear = createBear();
      settleIntoSitting(bear);

      bear.moveRight();
      expect(bear.animationState, BearAnimationState.standUp);

      bear.update(0.68);
      expect(bear.animationState, BearAnimationState.walk);
    });

    test('sitting and jump input starts standing up before jumping', () {
      final bear = createBear();
      settleIntoSitting(bear);

      bear.jump();
      expect(bear.animationState, BearAnimationState.standUp);

      bear.update(0.68);
      expect(bear.animationState, BearAnimationState.jump);
    });

    test('sitting pose keeps visual feet on the ground line', () {
      final bear = createBear();
      settleIntoSitting(bear);

      expect(bear.visualFeetY, closeTo(groundY, 0.001));
    });

    test('sitting animation frames are ordered from standing to sitting', () {
      for (final frameName in kBearSitFrameOrder) {
        expect(
          File(
            'assets/images/characters/bear_cub/animations/sit_down/$frameName',
          ).existsSync(),
          isTrue,
        );
      }

      expect(kBearSitFrameOrder.first, 'bear_sit_down_01.png');
      expect(kBearSitFrameOrder.last, 'bear_sit_down_09.png');
    });
  });
}
