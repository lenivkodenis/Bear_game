import 'dart:ui' as ui;

import 'package:bear_game/game/components/ambient/level_ambient_effects.dart';
import 'package:bear_game/game/components/ambient/mountain_eagle_ambient.dart';
import 'package:bear_game/game/components/ambient/snow_bunny_ambient.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('snow bunny ambient stays on northern forest without eagle', () {
    final forestAmbient = AmbientEffectsFactory.forLevel(
      levelId: 4,
      size: Vector2(800, 600),
      groundY: 498,
    );

    expect(forestAmbient, isA<SnowBunnyAmbient>());
    expect(
      AmbientEffectsFactory.forLevel(levelId: 1, size: Vector2(800, 600)),
      isNull,
    );
    expect(
      AmbientEffectsFactory.forLevel(levelId: 3, size: Vector2(800, 600)),
      isNull,
    );
    expect(
      AmbientEffectsFactory.forLevel(levelId: 6, size: Vector2(800, 600)),
      isNull,
    );
  });

  test('mountain eagle ambient is connected only to mountain pass level', () {
    final mountainAmbient = AmbientEffectsFactory.forLevel(
      levelId: 7,
      size: Vector2(1672, 941),
    );

    expect(mountainAmbient, isA<MountainPassAmbientEffect>());
    final mountainPass = mountainAmbient! as MountainPassAmbientEffect;
    expect(
      mountainPass.children.query<MountainPassSnowPlumeEffect>(),
      hasLength(1),
    );
    expect(mountainPass.children.query<MountainEagleAmbient>(), hasLength(1));
    expect(mountainPass.debugEaglePerchPoint.x, closeTo(130.42, 0.01));
    expect(mountainPass.debugEaglePerchPoint.y, closeTo(418.75, 0.01));
    expect(mountainPass.debugEagleEntryPoint.x, closeTo(-95.2, 0.01));
    expect(mountainPass.debugEagleEntryPoint.y, closeTo(305.83, 0.01));
    expect(mountainPass.debugEagleExitPoint.x, closeTo(-108.8, 0.01));
    expect(mountainPass.debugEagleExitPoint.y, closeTo(230.55, 0.01));
    expect(mountainPass.debugEagleSize.x, closeTo(68, 0.01));
    expect(mountainPass.debugEagleSize.y, closeTo(68, 0.01));
    expect(mountainPass.debugEagleCycleInterval, 10);
  });

  test('northern ocean blizzard is moved to mountain pass foreground', () {
    final mountainForegroundAmbient = AmbientEffectsFactory.foregroundForLevel(
      levelId: 7,
      size: Vector2(800, 600),
    );

    expect(mountainForegroundAmbient, isA<NorthernOceanBlizzardEffect>());

    final blizzard = mountainForegroundAmbient! as NorthernOceanBlizzardEffect;
    expect(blizzard.priority, greaterThan(20));
    expect(
      blizzard.debugParticleCount,
      NorthernOceanBlizzardEffect.blizzardParticleCount,
    );

    final oceanAmbient = AmbientEffectsFactory.foregroundForLevel(
      levelId: 10,
      size: Vector2(800, 600),
    );

    expect(oceanAmbient, isNull);
    expect(
      AmbientEffectsFactory.forLevel(levelId: 10, size: Vector2(800, 600)),
      isNull,
    );
  });

  test('northern ocean blizzard renders without asset dependencies', () {
    final blizzard = NorthernOceanBlizzardEffect(size: Vector2(800, 600));
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    expect(() {
      blizzard.update(0.5);
      blizzard.render(canvas);
    }, returnsNormally);

    recorder.endRecording().dispose();
  });

  test('runtime snow bunny alpha frames are bundled', () async {
    const frameRoot =
        'assets/images/characters/snow_bunny/animations/hop_turn/alpha';
    const frameNames = <String>[
      'snow_bunny_01_crouch_right.png',
      'snow_bunny_02_push_right.png',
      'snow_bunny_03_jump_right.png',
      'snow_bunny_04_fly_right.png',
      'snow_bunny_05_land_right.png',
      'snow_bunny_06_turn_start.png',
      'snow_bunny_07_turn_pivot.png',
      'snow_bunny_08_crouch_left.png',
      'snow_bunny_09_push_left.png',
      'snow_bunny_10_jump_left.png',
      'snow_bunny_11_fly_left.png',
      'snow_bunny_12_land_left.png',
    ];

    for (final frameName in frameNames) {
      final data = await rootBundle.load('$frameRoot/$frameName');

      expect(data.lengthInBytes, greaterThan(0));
    }
  });

  test('runtime mountain eagle frames are bundled', () async {
    const frameRoot =
        'assets/images/characters/mountain_eagle/animations/fly_land_takeoff';
    const frameNames = <String>[
      'mountain_eagle_01_glide.png',
      'mountain_eagle_02_approach.png',
      'mountain_eagle_03_descent.png',
      'mountain_eagle_04_brake.png',
      'mountain_eagle_05_touchdown.png',
      'mountain_eagle_06_settle.png',
      'mountain_eagle_07_stand.png',
      'mountain_eagle_08_takeoff_prepare.png',
      'mountain_eagle_09_takeoff_push.png',
      'mountain_eagle_10_takeoff_upstroke.png',
      'mountain_eagle_11_depart.png',
    ];

    for (final frameName in frameNames) {
      final data = await rootBundle.load('$frameRoot/$frameName');

      expect(data.lengthInBytes, greaterThan(0));
    }
  });
}
