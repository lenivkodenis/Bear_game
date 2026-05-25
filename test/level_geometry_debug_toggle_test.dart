import 'package:bear_game/game/level_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('geometry debug overlay URL toggle', () {
    test('is off when URL has no debugGeometry parameter', () {
      expect(
        isLevelGeometryDebugOverlayEnabledForUri(
          Uri.parse('http://127.0.0.1:8099/'),
        ),
        isFalse,
      );
    });

    test('is on for top-level query parameter', () {
      expect(
        isLevelGeometryDebugOverlayEnabledForUri(
          Uri.parse('http://127.0.0.1:8099/?debugGeometry=1'),
        ),
        isTrue,
      );
    });

    test('is on when query parameter appears inside hash route', () {
      expect(
        isLevelGeometryDebugOverlayEnabledForUri(
          Uri.parse('http://127.0.0.1:8099/#/game?debugGeometry=1'),
        ),
        isTrue,
      );
    });

    test('ignores other debugGeometry values', () {
      expect(
        isLevelGeometryDebugOverlayEnabledForUri(
          Uri.parse('http://127.0.0.1:8099/?debugGeometry=0'),
        ),
        isFalse,
      );
    });
  });
}
