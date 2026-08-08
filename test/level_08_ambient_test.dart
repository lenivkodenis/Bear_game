import 'package:bear_game/game/components/ambient/level_ambient_effects.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level 8 shooting star stays high in the sky', () {
    final effect = AmbientEffectsFactory.forLevel(
      levelId: 8,
      size: Vector2(800, 600),
    );

    expect(effect, isA<PolarNightStarsEffect>());
    expect(PolarNightStarsEffect.startPositionNormalized.dy, lessThan(0.18));
    expect(PolarNightStarsEffect.endPositionNormalized.dy, lessThan(0.18));
    expect(
      PolarNightStarsEffect.endPositionNormalized.dx -
          PolarNightStarsEffect.startPositionNormalized.dx,
      greaterThan(0.60),
    );
  });
}
