# Mountain Eagle Assets

The original mountain eagle source PNGs are kept unchanged in:

`assets/images/characters/mountain_eagle/animations/fly_land-takeoff/`

Those 11 source files are 1254x1254 RGB PNGs with a baked checkerboard
background and no alpha channel, so they should not be loaded directly by game
code.

The normalized gameplay-ready PNGs are generated into:

`assets/images/characters/mountain_eagle/animations/fly_land_takeoff/`

The new folder uses an underscore because `fly_land_takeoff` is the normalized
runtime asset path requested for game code, while the source folder currently
uses a hyphen. Keeping both folders preserves the original files and gives the
runtime a clean, predictable asset location.

There are 11 frames. A 12th frame is not present and is not expected.

| Source file | Role | Normalized target |
|---|---|---|
| `mountain_eagle_06_settle.png` | `glide` | `mountain_eagle_01_glide.png` |
| `mountain_eagle_07_stand.png` | `approach` | `mountain_eagle_02_approach.png` |
| `mountain_eagle_05_touchdown.png` | `descent` | `mountain_eagle_03_descent.png` |
| `mountain_eagle_04_brake.png` | `brake` | `mountain_eagle_04_brake.png` |
| `mountain_eagle_10_takeoff_upstroke.png` | `touchdown` | `mountain_eagle_05_touchdown.png` |
| `mountain_eagle_02_approach.png` | `settle` | `mountain_eagle_06_settle.png` |
| `mountain_eagle_01_glide.png` | `stand` | `mountain_eagle_07_stand.png` |
| `mountain_eagle_09_takeoff_push.png` | `takeoff_prepare` | `mountain_eagle_08_takeoff_prepare.png` |
| `mountain_eagle_03_descent.png` | `takeoff_push` | `mountain_eagle_09_takeoff_push.png` |
| `mountain_eagle_11_depart_power.png` | `takeoff_upstroke` | `mountain_eagle_10_takeoff_upstroke.png` |
| `mountain_eagle_08_takeoff_prepare.png` | `depart` | `mountain_eagle_11_depart.png` |

The normalized files are RGBA PNGs, remain 1254x1254, and remove only the
edge-connected checkerboard background. Future game code should use the
normalized `fly_land_takeoff/` assets, not the RGB source files.

Regenerate them with:

`python3 scripts/prepare_mountain_eagle_assets.py`
