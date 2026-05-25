# Level Geometry Guide

## Temporary Stable Baseline

Complex geometry is disabled again. All 10 levels use one visually calibrated
flat ground collider, with no platforms, no obstacles, no gaps, and no
multi-level routes.

The goal of this baseline is gameplay stability:

- each level keeps its own `background.png`;
- the bear spawns on the left side;
- the bear stands on one horizontal ground line;
- the bear can walk right and jump using the existing physics;
- the mentor stands on the same ground line on the right side;
- the mentor trigger can open the dialog and questions.

Do not add complex geometry back to all 10 levels at once. Future obstacles and
platforms should be added one level at a time, with coordinate calibration and
manual playtesting after each level.

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

# Geometry calibration workflow

Before any platform or obstacle rollout:

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

The former level 1 preview has been removed from runtime data. These were the
old coordinates before the ground line moved to `460`, so they are historical
only:

```json
{
  "id": "ice_ridge_preview_1",
  "x": 520,
  "y": 375,
  "width": 100,
  "height": 45,
  "notes": "Preview only. Not used for collision."
}
```

The preview `y` is calculated, not guessed:

```text
preview.y = main_ground.y - preview.height
preview.y = 460 - preview.height
```

## JSON Shape

`assets/data/level_geometry.json` uses design coordinates for an `800x600`
world. Runtime scales the flat baseline to the current game size.

All levels currently use the same flat baseline shape:

```json
{
  "levelId": 1,
  "backgroundAsset": "assets/images/levels/level_01_ice_floe/background.png",
  "playerSpawn": { "x": 72, "y": 460 },
  "mentorPosition": { "x": 688, "y": 460 },
  "groundColliders": [
    { "id": "main_ground", "x": 0, "y": 460, "width": 800, "height": 140 }
  ],
  "platformColliders": [],
  "obstacleColliders": [],
  "notes": "Stable flat baseline. Ground line visually recalibrated to the foreground snow surface."
}
```

Levels 1-10 keep `obstacleColliders: []`, `platformColliders: []`, and no
calibration previews.

## Ground

Baseline mode requires exactly one `main_ground` collider per level. It must
start at `x: 0`, span the full world width, and use the same `y` value as
`playerSpawn` and `mentorPosition`.

The current temporary baseline `y` is `460`, chosen from the debug screenshot
so the ground top line sits on the foreground snow surface instead of floating
above it. This is `76.7%` of a `600` px scene. `main_ground.height` is `140`
so the ground rectangle still ends at the bottom of the design world.

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
empty platforms, empty obstacles, no calibration previews, sane coordinates,
mentor to the right of the spawn, both contact points on the main ground, and a
foreground-range `main_ground.y`.
