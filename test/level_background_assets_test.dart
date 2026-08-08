import 'dart:io';

import 'package:bear_game/game/level_background_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelBackgroundAssets', () {
    test('maps level ids 1 through 10 to production backgrounds', () {
      expect(
        LevelBackgroundAssets.byLevelId.keys,
        containsAll(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
      );
      expect(LevelBackgroundAssets.byLevelId, hasLength(10));

      for (var levelId = 1; levelId <= 10; levelId += 1) {
        final path = LevelBackgroundAssets.forLevelId(levelId);

        expect(path, isNotEmpty);
        expect(path, startsWith('assets/images/levels/'));
        expect(path, endsWith('/background.png'));
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('returns a safe fallback for unknown level ids', () {
      expect(
        LevelBackgroundAssets.forLevelId(999),
        LevelBackgroundAssets.fallbackAssetPath,
      );
      expect(
        File(LevelBackgroundAssets.fallbackAssetPath).existsSync(),
        isTrue,
      );
    });

    test('keeps level 2 full background as layered fallback', () {
      expect(
        LevelBackgroundAssets.forLevelId(2),
        LevelBackgroundAssets.level2IcyRiverBackgroundAsset,
      );

      final layers = LevelBackgroundAssets.layersForBackground(
        LevelBackgroundAssets.level2IcyRiverBackgroundAsset,
      );

      expect(layers, isNotNull);
      expect(
        layers!.backLayerAssetPath,
        LevelBackgroundAssets.level2IcyRiverBackLayerAsset,
      );
      expect(
        layers.foregroundOverlayAssetPath,
        LevelBackgroundAssets.level2IcyRiverForegroundOverlayAsset,
      );
      expect(File(layers.backLayerAssetPath).existsSync(), isTrue);
      expect(File(layers.foregroundOverlayAssetPath).existsSync(), isTrue);
    });

    test('converts Flutter asset paths to Flame image keys', () {
      expect(
        LevelBackgroundAssets.flameImageKey(
          'assets/images/levels/level_01_ice_floe/background.png',
        ),
        'levels/level_01_ice_floe/background.png',
      );
      expect(
        LevelBackgroundAssets.flameImageKey(
          LevelBackgroundAssets.level2IcyRiverBackLayerAsset,
        ),
        'backgrounds/levels/level_2_background_backlayer_realistic_v2.png',
      );
    });
  });
}
