# Level Geometry Guide

## Temporary Stable Baseline

Complex geometry is temporarily disabled. All 10 levels now use one flat,
full-width ground collider, with no platforms, no obstacles, no gaps, and no
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

# Obstacle rollout paused

The first obstacle rollout on level 1 broke gameplay: the bear could hang in
the air and the obstacle height/ground contact was not reliable enough. The
rollout is paused, and all levels are back on flat baseline geometry.

Do not add obstacles by visual guessing. Before the next attempt:

- use `docs/LEVEL_GEOMETRY_COORDINATE_CONTRACT.md`;
- run a debug/calibration pass for ground top and obstacle bottom;
- add one obstacle only after the coordinate contract is verified;
- keep levels 2-10 on flat baseline until level 1 is proven stable.

# Geometry calibration workflow

Before any platform or obstacle rollout:

1. Manually enable `kLevelGeometryDebugOverlay` in
   `lib/game/level_geometry.dart`.
2. Check the main ground rectangle and its highlighted top line.
3. Check the player hitbox and feet/bottom line.
4. Confirm that `playerSpawn` is on the same surface line as the bear's feet.
5. Confirm that `mentorPosition` is on the same surface line and remains to the
   right of `playerSpawn`.
6. Add only one test collider after the baseline lines are visually confirmed.
7. Manually check movement, jumping, mentor reach, dialog, and task opening
   after every collider.
8. Do not add many obstacles at once, and do not roll geometry changes across
   all 10 levels in a single pass.

## JSON Shape

`assets/data/level_geometry.json` uses design coordinates for an `800x600`
world. Runtime scales the flat baseline to the current game size.

Each level has:

```json
{
  "levelId": 1,
  "backgroundAsset": "assets/images/levels/level_01_ice_floe/background.png",
  "playerSpawn": { "x": 72, "y": 420 },
  "mentorPosition": { "x": 688, "y": 420 },
  "groundColliders": [
    { "id": "main_ground", "x": 0, "y": 420, "width": 800, "height": 180 }
  ],
  "platformColliders": [],
  "obstacleColliders": [],
  "notes": "Stable flat baseline. Obstacles disabled until coordinate contract is verified."
}
```

## Ground

Baseline mode requires exactly one `main_ground` collider per level. It must
start at `x: 0`, span the full world width, and use the same `y` value as
`playerSpawn` and `mentorPosition`.

The current baseline `y` is `420`, matching the previous stable ground line
(`70%` of a `600` px scene).

## Platforms And Obstacles

Baseline mode requires:

- `platformColliders: []`
- `obstacleColliders: []`

No steps, gaps, crystals, logs, ridges, or blocked routes should be present
until a later coordinate-calibrated tuning pass.

## Runtime

`BearMathGame` loads the current level's geometry and uses only:

- `backgroundAsset`;
- `playerSpawn`;
- `mentorPosition`;
- the single `main_ground`.

When `kLevelGeometryDebugOverlay` is enabled manually, the runtime also draws
geometry guides for ground, future platform and obstacle preview colliders,
spawn points, mentor points, player hitbox, and player feet line. This overlay
is visual only and must not affect movement, collision, physics, or routes.

The bear still uses its original simple grounding logic from `PlayerBear`.
Hitbox, speed, gravity, jump force, visual offsets, feet anchor, and walk
animation are unchanged.

`kLevelGeometryDebugOverlay` exists in `lib/game/level_geometry.dart` and must
remain `false` by default. The baseline runtime does not need collider drawing.

## Validation

Run:

```bash
python3 tools/validate_level_geometry.py
```

The validator checks all 10 levels, per-level backgrounds, one main ground,
empty platforms, empty obstacles, sane coordinates, mentor to the right of the
spawn, and both contact points on the main ground.
