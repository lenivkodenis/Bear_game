import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('level 9 uses two reachable ground heights', () {
    final geometry =
        jsonDecode(File('assets/data/level_geometry.json').readAsStringSync())
            as Map<String, Object?>;
    final levels = geometry['levels']! as List<Object?>;
    final levelNine = levels.cast<Map<String, Object?>>().singleWhere(
      (level) => level['levelId'] == 9,
    );
    final grounds = (levelNine['groundColliders']! as List<Object?>)
        .cast<Map<String, Object?>>();

    final uniqueSurfaceYs =
        grounds.map((ground) => ground['y'] as num).toSet().toList()..sort();

    expect(uniqueSurfaceYs, <num>[410, 475]);
    expect((levelNine['playerSpawn']! as Map<String, Object?>)['y'], 410);
    expect((levelNine['mentorPosition']! as Map<String, Object?>)['y'], 410);

    const jumpImpulse = 410.0;
    const gravity = 820.0;
    const safetyMargin = 25.0;
    const maxJumpHeight = jumpImpulse * jumpImpulse / (2 * gravity);
    final stepHeight = uniqueSurfaceYs.last - uniqueSurfaceYs.first;

    expect(stepHeight, lessThanOrEqualTo(maxJumpHeight - safetyMargin));
  });
}
