# Level Background Runtime

Production level backgrounds live in `assets/images/levels/`. Each canonical
level folder contains a runtime image named `background.png` and a preserved
source copy under `source/`.

## Runtime mapping

The runtime background selection is defined in
`lib/game/level_background_assets.dart`.

Important temporary rule: the audited level `background.png` files currently
contain a baked-in player bear cub, so they are not used by runtime. Until clean
environment-only replacements are added, every level uses the shared clean
fallback background:
`assets/images/locations/snowy_clearing/preview/snowy_clearing_full_preview.png`.

| Level | Name | Audited background | Runtime background |
|---|---|---|---|
| 1 | Льдина | `assets/images/levels/level_01_ice_floe/background.png` | fallback |
| 2 | Ледяная река | `assets/images/levels/level_02_icy_river/background.png` | fallback |
| 3 | Заснеженный берег | `assets/images/levels/level_03_snowy_shore/background.png` | fallback |
| 4 | Северный лес | `assets/images/levels/level_04_northern_forest/background.png` | fallback |
| 5 | Ледяная пещера | `assets/images/levels/level_05_ice_cave/background.png` | fallback |
| 6 | Снежная долина | `assets/images/levels/level_06_snowy_valley/background.png` | fallback |
| 7 | Горный перевал | `assets/images/levels/level_07_mountain_pass/background.png` | fallback |
| 8 | Полярная ночь | `assets/images/levels/level_08_polar_night/background.png` | fallback |
| 9 | Северное сияние | `assets/images/levels/level_09_northern_lights/background.png` | fallback |
| 10 | Северный океан | `assets/images/levels/level_10_northern_ocean/background.png` | fallback |

`BearMathGame` passes the current level id to this resolver when it creates the
`SnowyBackground` component. `SnowyBackground` then loads the selected image
through Flame and draws it with `BoxFit.cover`, so the background fills the game
area without changing the ground line or gameplay components.

## Fallback

Unknown level ids and levels without clean replacements use the previous shared
background:
`assets/images/locations/snowy_clearing/preview/snowy_clearing_full_preview.png`.
If a configured clean level background cannot be loaded at runtime, the
background component logs a warning and tries that same fallback image.

## Adding A New Background

1. Add the production image as `background.png` under a new
   `assets/images/levels/level_XX_name/` folder.
2. Preserve the source image under that folder's `source/` directory.
3. Verify the image has no baked-in player bear, mentor sprite, UI, or text.
4. Add the level id and asset path to
   `LevelBackgroundAssets.cleanBackgroundsByLevelId`.
5. Keep audited rejected files in
   `LevelBackgroundAssets.auditedBackgroundsWithBakedInBearByLevelId` only for
   tracking.
6. Add or update the asset test so the new file must exist.

Physics, colliders, obstacles, and level geometry are intentionally separate
from this runtime background step and will be handled in a later stage.
