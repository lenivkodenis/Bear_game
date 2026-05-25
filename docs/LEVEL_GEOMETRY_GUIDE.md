# Level Geometry Guide

## Production Per-Level Flat Baseline

The manual ground calibration pass is complete. The approved per-level
`groundY` values are now written to `assets/data/level_geometry.json`.

Complex geometry is still disabled. All 10 levels use one visually calibrated
flat ground collider per level, with no platforms, no obstacles, no gaps, and
no multi-level routes.

The goal of this baseline is gameplay stability:

- each level keeps its own `background.png`;
- the bear spawns on the left side;
- the bear stands on that level's calibrated horizontal ground line;
- the bear can walk right and jump using the existing physics;
- the mentor stands on the same per-level ground line on the right side;
- the mentor trigger can open the dialog and questions.

Do not add complex geometry back to all 10 levels at once. Future obstacles and
platforms should be added one level at a time, with coordinate calibration and
manual playtesting after each level. Obstacles and platforms may be added only
after stable verification of these production per-level ground values.

# Obstacle rollout paused again

The first real obstacle rollout was stopped after debug screenshots showed that
the obstacle was mathematically aligned to `groundTopY`, but `groundTopY` itself
was too high above the visual snow surface. The obstacle was removed and the
project returned to a flat baseline.

Do not add obstacles by visual guessing. Before the next attempt:

- use `docs/LEVEL_GEOMETRY_COORDINATE_CONTRACT.md`;
- run a debug/calibration pass for the visual ground top first;
- add only a calibration obstacle preview after the ground line is verified;
- keep all levels on flat baseline until level 1 is visually stable.

The ground line is now calibrated per level in production, but obstacle rollout
is still paused.

# Obstacle preview after ground calibration

Ground `groundY` values are now calibrated for all levels and persisted in
production geometry. Future obstacles still start as debug-only previews.

Level 1 currently has one `calibrationObstacles` preview:

```json
{
  "id": "ice_ridge_preview_1",
  "x": 440,
  "y": 455,
  "width": 90,
  "height": 34,
  "notes": "Preview only. Not used for collision."
}
```

After manual screenshot review, this preview was moved left and reduced in size
so it sits closer to the small snow/ice bump area instead of near the mentor.

The preview is visible only when `debugGeometry=1` is present in the URL. It is
not a gameplay collider, does not block movement, and must remain separate from
`obstacleColliders`.

After a screenshot and visual confirmation, a later separate step may convert
the approved preview into a real `obstacleCollider`.

# Obstacle calibration mode

Run the web build only when a manual obstacle preview calibration pass is
needed:

```bash
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8099 --release
```

Open level 1 with obstacle calibration enabled:

```text
http://127.0.0.1:8099/?debugGeometry=1&calibrateObstacle=1#/game
```

`calibrateObstacle=1` works only together with `debugGeometry=1`. The preview
is debug-only and remains separate from `obstacleColliders`.

Use the keyboard while the game is focused:

- `ArrowLeft` / `ArrowRight` moves the candidate by 10 px on X.
- `Shift + ArrowLeft` / `Shift + ArrowRight` moves it by 1 px on X.
- `A` / `D` decreases or increases width by 5 px.
- `W` / `S` increases or decreases height by 5 px.
- `Shift + A/D/W/S` changes width or height by 1 px.
- `R` resets the candidate to the values from `level_geometry.json`.
- `C` prints the current candidate JSON to the browser console.

The preview is ground-locked. Do not edit `y` manually while the obstacle is
standing on the ground:

```text
y = groundTopY - height
```

After calibration, send the printed JSON. A later separate step may copy the
approved preview into `level_geometry.json`, and only after that may another
separate gameplay step convert it into an `obstacleCollider`.

# Geometry calibration workflow

The first manual calibration pass is complete. Keep calibration mode as a debug
tool for future corrections, screenshots, and spot checks.

Before any future platform or obstacle rollout:

1. Launch the game with the geometry debug URL parameter.
2. Check that the highlighted `groundTopY` line lies on the visual snow
   surface in the background.
3. Check the visual feet line.
4. Check the player hitbox bottom line.
5. Confirm that `playerSpawn` is on the same surface line as the bear's feet.
6. Confirm that `mentorPosition` is on the same surface line and remains to the
   right of `playerSpawn`.
7. Add only one calibration obstacle preview after these lines coincide.
8. Manually check movement, jumping, mentor reach, dialog, and task opening
   after every preview and every future collider.
9. Do not add many obstacles at once, and do not roll geometry changes across
   all 10 levels in a single pass.

# How to enable geometry debug overlay

Run the web build only when a manual calibration pass is needed:

```bash
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8099 --release
```

Open the normal game with the debug URL parameter:

```text
http://127.0.0.1:8099/?debugGeometry=1
```

Then navigate to the map and open a level normally. For direct level 1
calibration, the hash route can also keep the parameter before the hash:

```text
http://127.0.0.1:8099/?debugGeometry=1#/game
```

The overlay is only for calibration. Before ordinary gameplay checks, remove
`debugGeometry=1` from the URL and reload. Do not commit a state where
`kLevelGeometryDebugOverlay` is enabled by default.

# Ground calibration mode

Run the web build only when a manual ground calibration pass is needed:

```bash
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=8099 --release
```

Open the calibration route:

```text
http://127.0.0.1:8099/?debugGeometry=1&calibrateGround=1#/game
```

`calibrateGround=1` works only together with `debugGeometry=1`. In ordinary
gameplay, without those URL parameters, the runtime uses
`assets/data/level_geometry.json` unchanged.

Use the keyboard while the game is focused:

- `ArrowUp` moves the temporary ground line up by 5 runtime pixels.
- `ArrowDown` moves the temporary ground line down by 5 runtime pixels.
- `Shift + ArrowUp` moves it up by 1 runtime pixel.
- `Shift + ArrowDown` moves it down by 1 runtime pixel.
- `R` resets the current level to the `main_ground.y` value from
  `level_geometry.json`.
- `C` prints the calibrated `groundY` values for all levels to the browser
  console as JSON.

The calibration mode moves the debug ground line, `playerSpawn`,
`mentorPosition`, the active player, and the hitbox/visual feet preview
together. It does not write to `level_geometry.json`.

The approved values from the completed calibration pass are already committed
to production geometry. After any future recalibration, send the exported
`groundY` JSON values so `level_geometry.json` can be updated in a separate
commit.

# Obstacle preview workflow

Future obstacles must start as calibration previews:

1. Add one `calibrationObstacles` preview to the target level.
2. Keep `obstacleColliders: []`; the preview is not collision and does not
   block the bear.
3. Enable `debugGeometry=1` and take a screenshot of the preview rectangle.
4. Confirm that the preview bottom sits exactly on `groundTopY` and does not
   overlap `playerSpawn` or `mentorPosition`.
5. Only after visual confirmation, move the calibrated rectangle into
   `obstacleColliders` in a separate gameplay change.

The current level 1 preview is:

```json
{
  "id": "ice_ridge_preview_1",
  "x": 440,
  "y": 455,
  "width": 90,
  "height": 34,
  "notes": "Preview only. Not used for collision."
}
```

The preview `y` is calculated, not guessed:

```text
preview.y = main_ground.y - preview.height
preview.y = 489 - 34 = 455
```

## JSON Shape

`assets/data/level_geometry.json` uses design coordinates for an `800x600`
world. Runtime scales the flat baseline to the current game size.

All levels currently use the same flat baseline shape, with a per-level
`main_ground.y`:

```json
{
  "levelId": 1,
  "backgroundAsset": "assets/images/levels/level_01_ice_floe/background.png",
  "playerSpawn": { "x": 72, "y": 489 },
  "mentorPosition": { "x": 688, "y": 489 },
  "groundColliders": [
    { "id": "main_ground", "x": 0, "y": 489, "width": 800, "height": 111 }
  ],
  "platformColliders": [],
  "obstacleColliders": [],
  "calibrationObstacles": [
    {
      "id": "ice_ridge_preview_1",
      "x": 440,
      "y": 455,
      "width": 90,
      "height": 34,
      "notes": "Preview only. Not used for collision."
    }
  ],
  "notes": "Stable flat baseline. Per-level ground line visually calibrated to this background's foreground snow surface."
}
```

Levels 1-10 keep `obstacleColliders: []` and `platformColliders: []`. Level 1
has one debug-only calibration preview; levels 2-10 have no calibration
previews.

## Ground

Baseline mode requires exactly one `main_ground` collider per level. It must
start at `x: 0`, span the full world width, use that level's approved `y`
value, and use the same `y` value as `playerSpawn` and `mentorPosition`.

`main_ground.height` should keep the ground rectangle ending at the bottom of
the design world:

```text
main_ground.height = 600 - main_ground.y
```

Approved production `groundY` values:

| Level | Background key | `groundY` |
| --- | --- | ---: |
| 1 | `level_01_ice_floe` | 489 |
| 2 | `level_02_icy_river` | 460 |
| 3 | `level_03_snowy_shore` | 460 |
| 4 | `level_04_northern_forest` | 498 |
| 5 | `level_05_ice_cave` | 409 |
| 6 | `level_06_snowy_valley` | 506 |
| 7 | `level_07_mountain_pass` | 464 |
| 8 | `level_08_polar_night` | 485 |
| 9 | `level_09_northern_lights` | 477 |
| 10 | `level_10_northern_ocean` | 519 |

## Platforms And Obstacles

Baseline mode requires every level to have:

- `platformColliders: []`
- `obstacleColliders: []`

`calibrationObstacles` may contain preview rectangles for debug overlay
calibration only. They are not gameplay colliders.

No steps, gaps, crystals, logs, ridges, or blocked routes should be present
until a later coordinate-calibrated tuning pass.

## Runtime

`BearMathGame` loads the current level's geometry and uses only:

- `backgroundAsset`;
- `playerSpawn`;
- `mentorPosition`;
- the single `main_ground`.

When `debugGeometry=1` is present in the URL, the runtime also draws geometry
guides for ground, future platform and obstacle preview colliders, spawn
points, mentor points, player hitbox, player feet line, visual sprite bounds,
and visual feet line. This overlay is visual only and must not affect movement,
collision, physics, or routes.

The bear still uses its original simple grounding logic from `PlayerBear`.
Hitbox, speed, gravity, jump force, and walk animation are unchanged. The visual
feet line must stay calibrated to the hitbox bottom before obstacle work
resumes.

`kLevelGeometryDebugOverlay` exists in `lib/game/level_geometry.dart` and must
remain `false` by default. The baseline runtime does not need collider drawing.

## Validation

Run:

```bash
python3 tools/validate_level_geometry.py
```

The validator checks all 10 levels, per-level backgrounds, one main ground,
approved per-level `groundY` values, empty platforms, empty obstacles, no
gameplay obstacle colliders, the level 1 debug-only preview, sane coordinates,
mentor to the right of the spawn, and both contact points on the main ground.
