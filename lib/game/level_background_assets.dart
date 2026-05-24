class LevelBackgroundAssets {
  static const fallbackAssetPath =
      'assets/images/locations/snowy_clearing/preview/snowy_clearing_full_preview.png';

  static const Map<int, String> byLevelId = <int, String>{
    1: 'assets/images/levels/level_01_ice_floe/background.png',
    2: 'assets/images/levels/level_02_icy_river/background.png',
    3: 'assets/images/levels/level_03_snowy_shore/background.png',
    4: 'assets/images/levels/level_04_northern_forest/background.png',
    5: 'assets/images/levels/level_05_ice_cave/background.png',
    6: 'assets/images/levels/level_06_snowy_valley/background.png',
    7: 'assets/images/levels/level_07_mountain_pass/background.png',
    8: 'assets/images/levels/level_08_polar_night/background.png',
    9: 'assets/images/levels/level_09_northern_lights/background.png',
    10: 'assets/images/levels/level_10_northern_ocean/background.png',
  };

  static String forLevelId(int levelId) {
    return byLevelId[levelId] ?? fallbackAssetPath;
  }

  static String flameImageKey(String assetPath) {
    const imagesPrefix = 'assets/images/';
    if (assetPath.startsWith(imagesPrefix)) {
      return assetPath.substring(imagesPrefix.length);
    }

    return assetPath;
  }
}
