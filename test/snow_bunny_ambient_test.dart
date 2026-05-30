import 'package:bear_game/game/components/ambient/level_ambient_effects.dart';
import 'package:bear_game/game/components/ambient/snow_bunny_ambient.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('snow bunny ambient is only connected to the northern forest level', () {
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
}
