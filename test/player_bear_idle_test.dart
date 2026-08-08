import 'dart:ui';

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

  group('bear walk animation state', () {
    test(
      'production walk animation keeps procedural leg prototype disabled',
      () {
        expect(kBearWalkFrameOrder, [
          'walk_01.png',
          'walk_02.png',
          'walk_03.png',
          'walk_04.png',
          'walk_05.png',
          'walk_06.png',
        ]);
        expect(kBearWalkFrameOrder.first, 'walk_01.png');
        expect(kBearWalkFrameOrder.last, 'walk_06.png');
        expect(kBearWalkAssetPaths, hasLength(6));
        expect(kBearWalkAssetPaths.toSet(), hasLength(6));
        expect(
          kBearWalkAssetPaths.first,
          contains('animations/walk_normalized/'),
        );
        expect(kBearWalkAssetPaths.first, isNot(contains('walk_v2_20')));
        expect(kBearWalkFrameStepTime, 0.12);
        expect(kBearWalkFrameStepTimes, [
          0.13,
          0.095,
          0.115,
          0.12,
          0.13,
          0.125,
        ]);
        expect(kBearWalkFrameVerticalOffsets, [
          0.0,
          -2.4,
          -1.1,
          -0.6,
          -0.3,
          -0.1,
        ]);
        expect(kBearUseFrameByFrameWalk, isTrue);
        expect(kBearUseHardWalkFrames, isFalse);
        expect(kBearUseProceduralWalkCarry, isFalse);
        expect(useProceduralBearWalkPrototype, isFalse);
        expect(forceProceduralWalkDebug, isFalse);
        expect(showProceduralWalkDebugOverlay, isFalse);
        expect(showProceduralWalkDebugColors, isFalse);
        expect(kBearProceduralStrideLengthPx, 80);
        expect(kBearProceduralLegSwingPhase, 0.32);
      },
    );

    test('procedural walk phase helpers support forced and distance modes', () {
      expect(
        debugAdvanceBearProceduralWalkPhase(
          phase: 0,
          dt: 0.5,
          deltaX: 0,
          forceTimePhase: true,
          active: true,
        ),
        closeTo(0.4, 0.001),
      );
      expect(
        debugAdvanceBearProceduralWalkPhase(
          phase: 0.9,
          dt: 0.5,
          deltaX: 0,
          forceTimePhase: false,
          active: true,
        ),
        closeTo(0.9, 0.001),
      );
      expect(
        debugAdvanceBearProceduralWalkPhase(
          phase: 0,
          dt: 0,
          deltaX: 40,
          forceTimePhase: false,
          active: true,
        ),
        closeTo(0.5, 0.001),
      );
      expect(
        debugAdvanceBearProceduralWalkPhase(
          phase: 0.25,
          dt: 1,
          deltaX: 80,
          forceTimePhase: false,
          active: false,
        ),
        closeTo(0.25, 0.001),
      );
    });

    test('debug prototype colors are not enabled by default', () {
      const productionColors = [
        kBearProceduralProductionFarLegColor,
        kBearProceduralProductionNearLegColor,
        kBearProceduralProductionOutlineColor,
        kBearProceduralProductionPawPadColor,
      ];

      for (final color in productionColors) {
        expect(color, isNot(const Color(0xFF3B82F6)));
        final argb = color.toARGB32();
        final blue = argb & 0xFF;
        expect(blue, lessThanOrEqualTo(250));
      }
      final nearArgb = kBearProceduralProductionNearLegColor.toARGB32();
      expect((nearArgb >> 16) & 0xFF, greaterThan(200));
      expect((nearArgb >> 8) & 0xFF, greaterThan(220));
      expect(nearArgb & 0xFF, greaterThan(225));
    });

    test('procedural gait follows diagonal four-paw walk phases', () {
      for (final leg in BearProceduralLeg.values) {
        expect(
          debugBearProceduralLegLift(leg: leg, phase: 0),
          closeTo(0, 0.001),
        );
      }

      expect(
        debugBearProceduralLegLift(
          leg: BearProceduralLeg.nearFront,
          phase: 0.2,
        ),
        greaterThan(4),
      );
      expect(
        debugBearProceduralLegLift(leg: BearProceduralLeg.farHind, phase: 0.2),
        greaterThan(4),
      );
      expect(
        debugBearProceduralLegLift(leg: BearProceduralLeg.farFront, phase: 0.2),
        closeTo(0, 0.001),
      );
      expect(
        debugBearProceduralLegLift(leg: BearProceduralLeg.nearHind, phase: 0.2),
        closeTo(0, 0.001),
      );

      expect(
        debugBearProceduralLegLift(leg: BearProceduralLeg.farFront, phase: 0.7),
        greaterThan(4),
      );
      expect(
        debugBearProceduralLegLift(leg: BearProceduralLeg.nearHind, phase: 0.7),
        greaterThan(4),
      );
      expect(
        debugBearProceduralLegLift(
          leg: BearProceduralLeg.nearFront,
          phase: 0.7,
        ),
        closeTo(0, 0.001),
      );
      expect(
        debugBearProceduralLegLift(leg: BearProceduralLeg.farHind, phase: 0.7),
        closeTo(0, 0.001),
      );
    });

    test(
      'walk activates only while grounded horizontal movement is active',
      () {
        final bear = createBear();

        bear.update(0.1);
        expect(bear.animationState, BearAnimationState.idle);

        bear.moveRight();
        bear.update(0.1);
        expect(bear.animationState, BearAnimationState.walk);

        bear.stopMoving();
        bear.update(0.1);
        expect(bear.animationState, BearAnimationState.idle);
      },
    );

    test('jump and fall are not overwritten by horizontal movement', () {
      final jumpingBear = createBear();

      jumpingBear.moveRight();
      jumpingBear.jump();
      expect(jumpingBear.animationState, BearAnimationState.jump);

      jumpingBear.update(0.05);
      expect(jumpingBear.animationState, BearAnimationState.jump);

      final fallingBear = createBear(airborneOffset: 40);
      fallingBear.moveRight();
      fallingBear.update(0.1);
      expect(fallingBear.animationState, BearAnimationState.fall);
    });

    test('production procedural walk stays still in idle', () {
      final bear = createBear();

      bear.update(0.5);
      expect(bear.animationState, BearAnimationState.idle);
      expect(bear.debugProceduralWalkPhase, closeTo(0, 0.001));
      expect(bear.debugProceduralWalkPoseBlend, closeTo(0, 0.001));
      expect(bear.debugProceduralFrontLegSwing, closeTo(0, 0.001));
      expect(bear.debugProceduralHindLegSwing, closeTo(0, 0.001));
    });

    test('production walk does not render procedural sausage legs', () {
      final bear = createBear();

      bear.moveRight();
      bear.update(0.1);
      expect(bear.animationState, BearAnimationState.walk);
      expect(bear.debugProceduralDeltaX, closeTo(16, 0.001));
      expect(bear.debugProceduralWalkPhase, closeTo(0, 0.001));
      expect(bear.debugProceduralWalkPoseBlend, closeTo(0, 0.001));
      expect(bear.debugProceduralNearFrontLegLift, closeTo(0, 0.001));
      expect(bear.debugProceduralFarHindLegLift, closeTo(0, 0.001));
      expect(bear.debugProceduralFarFrontLegLift, closeTo(0, 0.001));
      expect(bear.debugProceduralNearHindLegLift, closeTo(0, 0.001));
      expect(bear.debugProceduralRenderLegsCalled, isFalse);

      bear.update(0);
      expect(bear.debugProceduralDeltaX, closeTo(0, 0.001));
      expect(bear.debugProceduralWalkPhase, closeTo(0, 0.001));

      bear.stopMoving();
      bear.update(0.1);
      expect(bear.animationState, BearAnimationState.idle);
      expect(bear.debugProceduralWalkPhase, closeTo(0, 0.001));
      expect(bear.debugProceduralWalkPoseBlend, closeTo(0, 0.001));
    });

    test('distance helper remains available for disabled experiments', () {
      expect(
        debugAdvanceBearProceduralWalkPhase(
          phase: 0,
          dt: 0,
          deltaX: 16,
          forceTimePhase: false,
          active: true,
        ),
        closeTo(0.2, 0.001),
      );
    });

    test('forced helper phase is debug-only and can move in idle', () {
      expect(forceProceduralWalkDebug, isFalse);
      expect(
        debugAdvanceBearProceduralWalkPhase(
          phase: 0,
          dt: 0.5,
          deltaX: 0,
          forceTimePhase: forceProceduralWalkDebug,
          active: false,
        ),
        closeTo(0, 0.001),
      );
      expect(
        debugAdvanceBearProceduralWalkPhase(
          phase: 0,
          dt: 0.5,
          deltaX: 0,
          forceTimePhase: true,
          active: true,
        ),
        closeTo(0.4, 0.001),
      );
    });

    test('procedural walk does not advance while airborne', () {
      final bear = createBear();

      bear.moveRight();
      bear.update(0.1);
      expect(bear.debugProceduralWalkPhase, closeTo(0, 0.001));

      bear.jump();
      final phaseBeforeAirborneUpdate = bear.debugProceduralWalkPhase;
      bear.update(0.1);
      expect(bear.animationState, BearAnimationState.jump);
      expect(
        bear.debugProceduralWalkPhase,
        closeTo(phaseBeforeAirborneUpdate, 0.001),
      );
    });

    test('collision box stays stable across movement states', () {
      final bear = createBear();
      final initialWidth = bear.collisionBounds.width;
      final initialHeight = bear.collisionBounds.height;

      bear.moveRight();
      for (var i = 0; i < 8; i += 1) {
        bear.update(0.1);
        expect(bear.collisionBounds.width, initialWidth);
        expect(bear.collisionBounds.height, initialHeight);
      }

      bear.stopMoving();
      bear.update(0.1);
      expect(bear.collisionBounds.width, initialWidth);
      expect(bear.collisionBounds.height, initialHeight);

      bear.jump();
      bear.update(0.05);
      expect(bear.collisionBounds.width, initialWidth);
      expect(bear.collisionBounds.height, initialHeight);
    });

    test('production walk loads whole-bear frame-by-frame ticker', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final bear = createBear();
      await bear.onLoad();

      expect(bear.debugLoadedWalkFrameCount, kBearWalkFrameOrder.length);

      bear.moveRight();
      for (var i = 0; i < 220; i += 1) {
        bear.update(0.02);
        expect(bear.debugWalkFrameIndex, isNotNull);
      }
    });
  });
}
