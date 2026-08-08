# Level Asset Manifest

Date: 2026-05-24

All 10 canonical level folders use their own production `background.png`.
Each production background was replaced with the clean environment-only file
from `clean_source/background_clean.png`.

The previous production backgrounds with the baked-in player bear cub are kept
only as archival backups in `source_with_bear/background_with_bear.png`. They
are no longer active production backgrounds and are not used by the runtime.

| Level | Name | Folder | Production background | Clean source | With-bear backup | Input clean image | Status | Notes |
|---|---|---|---|---|---|---|---|---|
| 1 | Льдина | level_01_ice_floe | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | холодный_арктический_пейзаж_с_айсбергами.png | clean_active | Production background replaced with clean environment-only art. |
| 2 | Ледяная река | level_02_icy_river | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | зимний_пейзаж_с_ледяной_рекой.png | clean_active | Production background replaced with clean environment-only art. |
| 3 | Заснеженный берег | level_03_snowy_shore | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | снежный_пейзаж_с_ледяным_озером.png | clean_active | Production background replaced with clean environment-only art. |
| 4 | Северный лес | level_04_northern_forest | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | зимний_лес_с_падающим_снегом.png | clean_active | Production background replaced with clean environment-only art. |
| 5 | Ледяная пещера | level_05_ice_cave | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | ледяная_пещера_с_кристаллами.png | clean_active | Production background replaced with clean environment-only art. |
| 6 | Снежная долина | level_06_snowy_valley | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | зимний_альпийский_пейзаж_в_ярких_тонах.png | clean_active | Production background replaced with clean environment-only art. |
| 7 | Горный перевал | level_07_mountain_pass | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | заснеженные_альпийские_вершины_и_мост.png | clean_active | Production background replaced with clean environment-only art. |
| 8 | Полярная ночь | level_08_polar_night | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | арктическая_ночь_с_иглу_и_северным_сиянием.png | clean_active | Production background replaced with clean environment-only art. |
| 9 | Северное сияние | level_09_northern_lights | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | зимняя_фантазия_с_магическими_рунами.png | clean_active | Production background replaced with clean environment-only art. |
| 10 | Северный океан | level_10_northern_ocean | background.png | clean_source/background_clean.png | source_with_bear/background_with_bear.png | зимний_пейзаж_с_северным_сиянием.png | clean_active | Production background replaced with clean environment-only art. |

## Runtime

The game still uses per-level backgrounds through
`LevelBackgroundAssets.byLevelId`, with one `background.png` path per level.
No runtime code changes were needed for this replacement.
