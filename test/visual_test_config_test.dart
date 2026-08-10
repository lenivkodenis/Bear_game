import 'package:bear_game/visual_test/visual_test_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VisualTestConfig', () {
    test('is compiled out by default', () {
      expect(kEnableVisualTestMode, isFalse);

      final config = VisualTestConfig.fromUri(
        Uri.parse(
          'https://example.test/#/game?visualTest=1&levelId=9&checkpoint=mentor',
        ),
      );

      expect(config.enabled, isFalse);
      expect(config.levelId, 1);
      expect(config.checkpoint, VisualTestCheckpoint.start);
    });

    test('ignores special parameters when the build flag is false', () {
      final config = VisualTestConfig.fromUri(
        Uri.parse(
          'https://example.test/?visualTest=1&levelId=5&checkpoint=collision',
        ),
        buildEnabled: false,
      );

      expect(config.enabled, isFalse);
      expect(config.showCollisionOverlay, isFalse);
      expect(config.openTaskDialog, isFalse);
    });

    test('requires visualTest=1 even when compiled in', () {
      final config = VisualTestConfig.fromUri(
        Uri.parse('https://example.test/#/game?levelId=3&checkpoint=mentor'),
        buildEnabled: true,
      );

      expect(config.enabled, isFalse);
    });

    test('reads deterministic level and checkpoint from hash route', () {
      final config = VisualTestConfig.fromUri(
        Uri.parse(
          'https://example.test/#/game?visualTest=1&levelId=9&checkpoint=mentor',
        ),
        buildEnabled: true,
      );

      expect(config.enabled, isTrue);
      expect(config.levelId, 9);
      expect(config.checkpoint, VisualTestCheckpoint.mentor);
      expect(config.routePath, '/game');
    });

    test('infers game and map routes from test parameters', () {
      final game = VisualTestConfig.fromUri(
        Uri.parse(
          'https://example.test/?visualTest=1&levelId=1&checkpoint=start',
        ),
        buildEnabled: true,
      );
      final map = VisualTestConfig.fromUri(
        Uri.parse('https://example.test/?visualTest=1&checkpoint=map'),
        buildEnabled: true,
      );

      expect(game.routePath, '/game');
      expect(map.routePath, '/map');
    });

    test('clamps invalid level range and falls back to start checkpoint', () {
      final config = VisualTestConfig.fromUri(
        Uri.parse(
          'https://example.test/?visualTest=1&levelId=99&checkpoint=unknown',
        ),
        buildEnabled: true,
      );

      expect(config.enabled, isTrue);
      expect(config.levelId, 10);
      expect(config.checkpoint, VisualTestCheckpoint.start);
    });
  });
}
