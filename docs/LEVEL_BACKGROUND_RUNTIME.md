# Level Background Runtime

Production level backgrounds live in `assets/images/levels/`. Each canonical
level folder contains a runtime image named `background.png` and a preserved
source copy under `source/`.

## Runtime mapping

The `levelId -> background.png` mapping is defined in
`lib/game/level_background_assets.dart`.

| Level | Name | Runtime background |
|---|---|---|
| 1 | Льдина | `assets/images/levels/level_01_ice_floe/background.png` |
| 2 | Ледяная река | `assets/images/levels/level_02_icy_river/background.png` |
| 3 | Заснеженный берег | `assets/images/levels/level_03_snowy_shore/background.png` |
| 4 | Северный лес | `assets/images/levels/level_04_northern_forest/background.png` |
| 5 | Ледяная пещера | `assets/images/levels/level_05_ice_cave/background.png` |
| 6 | Снежная долина | `assets/images/levels/level_06_snowy_valley/background.png` |
| 7 | Горный перевал | `assets/images/levels/level_07_mountain_pass/background.png` |
| 8 | Полярная ночь | `assets/images/levels/level_08_polar_night/background.png` |
| 9 | Северное сияние | `assets/images/levels/level_09_northern_lights/background.png` |
| 10 | Северный океан | `assets/images/levels/level_10_northern_ocean/background.png` |

`BearMathGame` passes the current level id to that mapping when it creates the
`SnowyBackground` component. `SnowyBackground` then loads the selected image
through Flame and draws it with `BoxFit.cover`, so the background fills the game
area without changing the ground line or gameplay components.

## Fallback

Unknown level ids use the previous shared background:
`assets/images/locations/snowy_clearing/preview/snowy_clearing_full_preview.png`.
If a configured level background cannot be loaded at runtime, the background
component logs a warning and tries that same fallback image.

## Adding A New Background

1. Add the production image as `background.png` under a new
   `assets/images/levels/level_XX_name/` folder.
2. Preserve the source image under that folder's `source/` directory.
3. Add the level id and asset path to `LevelBackgroundAssets.byLevelId`.
4. Add or update the asset test so the new file must exist.

Physics, colliders, obstacles, and level geometry are intentionally separate
from this runtime background step and will be handled in a later stage.
