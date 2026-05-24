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
platforms should be added one level at a time, with manual playtesting after
each level.

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
  "notes": "Temporary stable flat baseline geometry. Obstacles and platforms will be added later per level."
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
until a later per-level tuning pass.

## Runtime

`BearMathGame` loads the current level's geometry and uses only:

- `backgroundAsset`;
- `playerSpawn`;
- `mentorPosition`;
- the single `main_ground`.

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
