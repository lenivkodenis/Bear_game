# World Content Audit

Date: 2026-05-24

## 1. Current state

The game already has 10 data-driven levels in `assets/data/levels.json`, and the progress map also exposes 10 stops. Each level has a title, `locationName`, multiplication table number, mentor name, intro text, completion text, and 10 questions.

Only one real level environment is currently drawn as image assets: `assets/images/locations/snowy_clearing/`. The runtime background component loads `locations/snowy_clearing/preview/snowy_clearing_full_preview.png` for the game scene, so this one environment is effectively reused for every level until per-level backgrounds are introduced.

Mentor characters are mostly content-only. The data names 10 mentors, but the game scene renders a single procedural `WiseMentor` placeholder. There are no dedicated mentor PNG assets yet.

There is a naming conflict around the first visual environment. Level 1 is called `Льдина` in data and on the map, while the existing art folder is `snowy_clearing` and visually reads closer to a snowy clearing/valley than a single ice floe. Separately, level 6 is already called `Снежная долина`, so treating the current art as level 6 would conflict with level 1 currently using it.

## 2. Canonical level table

| Level | id/key | Current name in data | Proposed canonical name | Multiplication topic | Mentor character | Asset status | Notes |
|---:|---:|---|---|---|---|---|---|
| 1 | `1` | `Льдина` | `Льдина` | Table of 1 | Морская чайка | Partial | Runtime uses the snowy clearing image, but data and questions describe ice floes, fish, snow mounds, and first safe steps. Canonical name should stay `Льдина` unless level 1 is intentionally redesigned. |
| 2 | `2` | `Ледяная река` | `Ледяная река` | Table of 2 | Бобр | Not started | No dedicated background, obstacles, or mentor PNG. |
| 3 | `3` | `Заснеженный берег` | `Заснеженный берег` | Table of 3 | Песец | Not started | No dedicated background, obstacles, or mentor PNG. |
| 4 | `4` | `Северный лес` | `Северный лес` | Table of 4 | Сова | Not started | No dedicated background, obstacles, or mentor PNG. |
| 5 | `5` | `Ледяная пещера` | `Ледяная пещера` | Table of 5 | Тюлень | Not started | No dedicated background, obstacles, or mentor PNG. |
| 6 | `6` | `Снежная долина` | `Снежная долина` | Table of 6 | Северный олень | Not started | Name overlaps with how the current `snowy_clearing` art may be perceived, but no level-6-specific asset folder exists. |
| 7 | `7` | `Горный перевал` | `Горный перевал` | Table of 7 | Овцебык | Not started | No dedicated background, obstacles, or mentor PNG. |
| 8 | `8` | `Полярная ночь` | `Полярная ночь` | Table of 8 | Волк | Not started | No dedicated background, obstacles, or mentor PNG. |
| 9 | `9` | `Северное сияние` | `Северное сияние` | Table of 9 | Нарвал | Not started | No dedicated background, obstacles, or mentor PNG. |
| 10 | `10` | `Северный океан` | `Северный океан` | Table of 10 | Белая медведица | Not started | No dedicated background, obstacles, or mentor PNG. |

## 3. Existing visual assets

### Level backgrounds

- `assets/images/locations/snowy_clearing/01_sky.png`
- `assets/images/locations/snowy_clearing/02_far_hills.png`
- `assets/images/locations/snowy_clearing/03_mid_forest.png`
- `assets/images/locations/snowy_clearing/04_ground_platform.png`
- `assets/images/locations/snowy_clearing/preview/snowy_clearing_full_preview.png`

These are the only complete location background assets currently present. The runtime uses the full preview image, not the separate parallax layers.

### Obstacles

- `assets/images/locations/snowy_clearing/obstacle_snowy_logs.png`
- `assets/images/locations/snowy_clearing/obstacle_stump.png`
- preview copies under `assets/images/locations/snowy_clearing/preview/layers/obstacles/`

These obstacles exist as art assets, but gameplay obstacle mechanics are not wired into the level flow.

### Characters

- Bear cub source, processed, and walk animation assets exist under `assets/images/bear_cub/` and `assets/images/characters/bear_cub/`.
- No mentor PNG assets exist.
- `WiseMentor` is drawn procedurally in code and currently looks like a generic gray tusked mentor placeholder, not the level-specific mentor from `levels.json`.

### Map assets

- `assets/images/map/progression_map.png`

The progress map UI also hardcodes 10 map stops that match the current level names in `levels.json`.

### Miscellaneous

- `assets/images/levels/level_01_ice_floe/` exists but contains no usable level art.
- `assets/data/locations.json` contains a stale single entry: `Снежная равнина`, `Мудрый морж`, table 1. The current runtime level flow uses `assets/data/levels.json`, not this file.

## 4. Naming conflicts

### `Льдина` vs `Снежная долина`

These should be treated as two different concepts, not one level with two names.

- `Льдина` is level 1 in `levels.json`, the progress map, completion fallback text, and the current question copy.
- `Снежная долина` is level 6 in `levels.json` and the progress map.
- Existing visual art is stored as `snowy_clearing`, which visually sits between a snowy clearing and a valley. It does not clearly communicate a single ice floe.

Recommendation: keep `Льдина` as the canonical level 1 name and keep `Снежная долина` as the canonical level 6 name. For production, either revise the current `snowy_clearing` art into a clearer level-1 ice-floe scene, or explicitly reserve it for a later snowy clearing/dolina location after approving a runtime rename. Do not rename runtime data yet.

### `Снежная равнина`

`docs/GAME_DESIGN.md` and `assets/data/locations.json` still mention `Снежная равнина`, but the active `levels.json` uses `Ледяная река` for level 2. Treat `levels.json` as the active source of truth until a separate content migration is approved.

## 5. Mentor status

| Level | Mentor in data | Status | Notes |
|---:|---|---|---|
| 1 | Морская чайка | Asset missing | Data and dialog name exist; runtime uses generic procedural placeholder. |
| 2 | Бобр | Asset missing | Data and dialog name exist; no PNG. |
| 3 | Песец | Asset missing | Data and dialog name exist; no PNG. |
| 4 | Сова | Asset missing | Data and dialog name exist; no PNG. |
| 5 | Тюлень | Asset missing | Data and dialog name exist; no PNG. |
| 6 | Северный олень | Asset missing | Data and dialog name exist; no PNG. |
| 7 | Овцебык | Asset missing | Data and dialog name exist; no PNG. |
| 8 | Волк | Asset missing | Data and dialog name exist; no PNG. |
| 9 | Нарвал | Asset missing | Data and dialog name exist; no PNG. |
| 10 | Белая медведица | Asset missing | Data and dialog name exist; no PNG. |

All 10 mentors need at least one calm full-body or three-quarter gameplay sprite. A second seated/listening or talking pose is recommended for dialog polish, but not required for the first asset pass.

## 6. Recommended next production order

1. Approve canonical level names from `assets/data/levels.json`, especially keeping `Льдина` and `Снежная долина` separate.
2. Decide whether the existing `snowy_clearing` art should be revised into level 1 `Льдина` or reserved for a future snowy clearing/dolina scene.
3. Write final one-paragraph art briefs for all 10 locations.
4. Write final one-paragraph character briefs for all 10 mentors.
5. Produce missing level backgrounds in order: level 1 cleanup/rename decision, then levels 2-10.
6. Produce mentor sprites in the same order as levels.
7. Introduce a level-to-background manifest only after assets exist and are approved.
8. Introduce mentor PNG loading only after at least the first real mentor sprite is approved.
