class LevelBackgroundLayerAssets {
  const LevelBackgroundLayerAssets({
    required this.backLayerAssetPath,
    required this.foregroundOverlayAssetPath,
  });

  final String backLayerAssetPath;
  final String foregroundOverlayAssetPath;
}

class LevelBackgroundAssets {
  static const fallbackAssetPath =
      'assets/images/locations/snowy_clearing/preview/snowy_clearing_full_preview.png';

  static const level2IcyRiverBackgroundAsset =
      'assets/images/levels/level_02_icy_river/background.png';
  static const level2IcyRiverBackLayerAsset =
      'assets/images/backgrounds/levels/level_2_background_backlayer_realistic_v2.png';
  static const level2IcyRiverForegroundOverlayAsset =
      'assets/images/levels/level_02_icy_river/foreground_gameplay_overlay.png';

  static const Map<int, String> byLevelId = <int, String>{
    1: 'assets/images/levels/level_01_ice_floe/background.png',
    2: level2IcyRiverBackgroundAsset,
    3: 'assets/images/levels/level_03_snowy_shore/background.png',
    4: 'assets/images/levels/level_04_northern_forest/background.png',
    5: 'assets/images/levels/level_05_ice_cave/background.png',
    6: 'assets/images/levels/level_06_snowy_valley/background.png',
    7: 'assets/images/levels/level_07_mountain_pass/background.png',
    8: 'assets/images/levels/level_08_polar_night/background.png',
    9: 'assets/images/levels/level_09_northern_lights/background.png',
    10: 'assets/images/levels/level_10_northern_ocean/background.png',
  };

  static const Map<String, LevelBackgroundLayerAssets>
  layeredByBackgroundAsset = <String, LevelBackgroundLayerAssets>{
    level2IcyRiverBackgroundAsset: LevelBackgroundLayerAssets(
      backLayerAssetPath: level2IcyRiverBackLayerAsset,
      foregroundOverlayAssetPath: level2IcyRiverForegroundOverlayAsset,
    ),
  };

  static String forLevelId(int levelId) {
    return byLevelId[levelId] ?? fallbackAssetPath;
  }

  static LevelBackgroundLayerAssets? layersForBackground(
    String backgroundAssetPath,
  ) {
    return layeredByBackgroundAsset[backgroundAssetPath];
  }

  static String flameImageKey(String assetPath) {
    const imagesPrefix = 'assets/images/';
    if (assetPath.startsWith(imagesPrefix)) {
      return assetPath.substring(imagesPrefix.length);
    }

    return assetPath;
  }
}
