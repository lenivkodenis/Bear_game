# Level Background Cleanup Audit

Date: 2026-05-24

All 10 production `background.png` files have been replaced with verified clean
environment-only backgrounds. The active production backgrounds contain no
player bear cub, mentor sprite, animals, UI, captions, or text.

The older production backgrounds with the baked-in player bear cub are retained
only in `source_with_bear/background_with_bear.png` as audit/history backups.
They are no longer active production assets and are not referenced by the game
runtime.

| Level | Name | Production background | Clean source added | Has baked-in bear | Has mentor | Has animals | Has UI/text | Status |
|---|---|---|---|---|---|---|---|---|
| 1 | Льдина | `assets/images/levels/level_01_ice_floe/background.png` | `assets/images/levels/level_01_ice_floe/clean_source/background_clean.png` | no | no | no | no | clean_active |
| 2 | Ледяная река | `assets/images/levels/level_02_icy_river/background.png` | `assets/images/levels/level_02_icy_river/clean_source/background_clean.png` | no | no | no | no | clean_active |
| 3 | Заснеженный берег | `assets/images/levels/level_03_snowy_shore/background.png` | `assets/images/levels/level_03_snowy_shore/clean_source/background_clean.png` | no | no | no | no | clean_active |
| 4 | Северный лес | `assets/images/levels/level_04_northern_forest/background.png` | `assets/images/levels/level_04_northern_forest/clean_source/background_clean.png` | no | no | no | no | clean_active |
| 5 | Ледяная пещера | `assets/images/levels/level_05_ice_cave/background.png` | `assets/images/levels/level_05_ice_cave/clean_source/background_clean.png` | no | no | no | no | clean_active |
| 6 | Снежная долина | `assets/images/levels/level_06_snowy_valley/background.png` | `assets/images/levels/level_06_snowy_valley/clean_source/background_clean.png` | no | no | no | no | clean_active |
| 7 | Горный перевал | `assets/images/levels/level_07_mountain_pass/background.png` | `assets/images/levels/level_07_mountain_pass/clean_source/background_clean.png` | no | no | no | no | clean_active |
| 8 | Полярная ночь | `assets/images/levels/level_08_polar_night/background.png` | `assets/images/levels/level_08_polar_night/clean_source/background_clean.png` | no | no | no | no | clean_active |
| 9 | Северное сияние | `assets/images/levels/level_09_northern_lights/background.png` | `assets/images/levels/level_09_northern_lights/clean_source/background_clean.png` | no | no | no | no | clean_active |
| 10 | Северный океан | `assets/images/levels/level_10_northern_ocean/background.png` | `assets/images/levels/level_10_northern_ocean/clean_source/background_clean.png` | no | no | no | no | clean_active |

## Replacement Sources

| Level | Requested clean source image | Stored clean source |
|---|---|---|
| 1 | холодный_арктический_пейзаж_с_айсбергами.png | `assets/images/levels/level_01_ice_floe/clean_source/background_clean.png` |
| 2 | зимний_пейзаж_с_ледяной_рекой.png | `assets/images/levels/level_02_icy_river/clean_source/background_clean.png` |
| 3 | снежный_пейзаж_с_ледяным_озером.png | `assets/images/levels/level_03_snowy_shore/clean_source/background_clean.png` |
| 4 | зимний_лес_с_падающим_снегом.png | `assets/images/levels/level_04_northern_forest/clean_source/background_clean.png` |
| 5 | ледяная_пещера_с_кристаллами.png | `assets/images/levels/level_05_ice_cave/clean_source/background_clean.png` |
| 6 | зимний_альпийский_пейзаж_в_ярких_тонах.png | `assets/images/levels/level_06_snowy_valley/clean_source/background_clean.png` |
| 7 | заснеженные_альпийские_вершины_и_мост.png | `assets/images/levels/level_07_mountain_pass/clean_source/background_clean.png` |
| 8 | арктическая_ночь_с_иглу_и_северным_сиянием.png | `assets/images/levels/level_08_polar_night/clean_source/background_clean.png` |
| 9 | зимняя_фантазия_с_магическими_рунами.png | `assets/images/levels/level_09_northern_lights/clean_source/background_clean.png` |
| 10 | зимний_пейзаж_с_северным_сиянием.png | `assets/images/levels/level_10_northern_ocean/clean_source/background_clean.png` |

## Runtime Check

The existing runtime mapping remains per-level:
`lib/game/level_background_assets.dart` maps levels 1 through 10 to their own
`assets/images/levels/<level_folder>/background.png` files. No code changes
were made for this cleanup.
