import 'package:bear_game/game/components/ambient/level_ambient_effects.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level 9 does not add a separate aurora overlay', () {
    expect(
      AmbientEffectsFactory.forLevel(levelId: 9, size: Vector2(800, 600)),
      isNull,
    );
  });
}
