# Level Background Cleanup Audit

Date: 2026-05-24

All 10 current production `background.png` files contain a baked-in player bear
cub. They are not clean environment-only production backgrounds yet. No automatic
retouching, clone/heal, or inpainting was performed.

| Level | Name | Background | Has baked-in bear | Has mentor | Has UI/text | Status | Action |
|---|---|---|---|---|---|---|---|
| 1 | Льдина | `assets/images/levels/level_01_ice_floe/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. |
| 2 | Ледяная река | `assets/images/levels/level_02_icy_river/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. |
| 3 | Заснеженный берег | `assets/images/levels/level_03_snowy_shore/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. Contains a seal-like non-player animal, but not the canonical mentor. |
| 4 | Северный лес | `assets/images/levels/level_04_northern_forest/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. |
| 5 | Ледяная пещера | `assets/images/levels/level_05_ice_cave/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. |
| 6 | Снежная долина | `assets/images/levels/level_06_snowy_valley/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. |
| 7 | Горный перевал | `assets/images/levels/level_07_mountain_pass/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. |
| 8 | Полярная ночь | `assets/images/levels/level_08_polar_night/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. |
| 9 | Северное сияние | `assets/images/levels/level_09_northern_lights/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. |
| 10 | Северный океан | `assets/images/levels/level_10_northern_ocean/background.png` | yes | no | no | has_baked_in_bear | Copied current file to `source_with_bear/background_with_bear.png`; needs clean replacement in `clean_source/`. |

## Clean Background Status

No clean production replacements were found in the level folders. The current
`background.png` files temporarily remain in place only because no verified
clean replacements exist yet.

Each level now has:

- `source_with_bear/background_with_bear.png` for the audited baked-in-bear file;
- `clean_source/` prepared for the future clean environment-only source.

## Replacement Needed

Add clean environment-only backgrounds for all 10 levels. Each replacement must
match the canonical location, preserve the intended ground/platform readability,
and contain no player bear, mentor sprite, UI, captions, or text.
