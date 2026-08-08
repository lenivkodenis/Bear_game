import 'package:bear_game/game/components/distant_birds_component.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistantBirdsConfig', () {
    test('level 3 slows by five percent every fifth of the path', () {
      final config = DistantBirdsConfig.snowyOceanShore;

      expect(config.pathSlowdownPerSegment, 0.05);
      expect(config.pathSlowdownSegmentCount, 5);
      expect(config.flightProgressForElapsed(0), 0);
      expect(
        config.flightProgressForElapsed(config.flightDuration * 0.2),
        closeTo(0.2, 0.0001),
      );

      final secondFifthElapsed =
          config.flightDuration * 0.2 + config.flightDuration * 0.2 / 0.95;
      expect(
        config.flightProgressForElapsed(secondFifthElapsed),
        closeTo(0.4, 0.0001),
      );
      expect(
        config.flightProgressForElapsed(config.flightDuration),
        lessThan(1),
      );
    });

    test('levels without slowdown keep linear flight progress', () {
      final config = DistantBirdsConfig.levelOne;

      expect(config.pathSlowdownPerSegment, 0);
      expect(config.flightProgressForElapsed(config.flightDuration * 0.5), 0.5);
      expect(config.flightProgressForElapsed(config.flightDuration), 1);
    });

    test('snowy valley has no legacy distant birds', () {
      expect(DistantBirdsConfig.forLevel(6), isNull);
    });
  });
}
