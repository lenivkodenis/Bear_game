# Level Geometry Guide

## Temporary Stable Baseline

Complex geometry is temporarily disabled. All 10 levels use one flat,
full-width ground collider, with no platforms, no gaps, and no multi-level
routes. Level 1 is the only exception in the current rollout: it has one small
test obstacle on the flat ground.

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
  "obstacleColliders": [
    { "id": "ice_ridge_1", "x": 280, "y": 382, "width": 88, "height": 38 }
  ],
  "notes": "Temporary flat baseline with one safe level 1 ice ridge. More obstacles and platforms will be added later per level."
}
```

## Ground

Baseline mode requires exactly one `main_ground` collider per level. It must
start at `x: 0`, span the full world width, and use the same `y` value as
`playerSpawn` and `mentorPosition`.

The current baseline `y` is `420`, matching the previous stable ground line
(`70%` of a `600` px scene).

## Platforms And Obstacles

For levels 2-10, baseline mode requires:

- `platformColliders: []`
- `obstacleColliders: []`

For level 1, `platformColliders` remains empty, and exactly one low
`obstacleCollider` is allowed for the first rollout. No steps, gaps, crystals,
logs, extra ridges, or blocked routes should be present until a later per-level
tuning pass.

## Step-by-step obstacle rollout

Do not add complex geometry back to all 10 levels at once. The safe rollout is:

1. Add one small obstacle to level 1.
2. Verify manually that the bear can walk to it, cannot walk through it, can
   jump past it, and can still reach the mentor.
3. Only after level 1 is verified, consider a second level 1 obstacle.
4. Only after level 1 is stable, move to level 2.

The current level 1 obstacle is `ice_ridge_1` at `x: 280`, `y: 382`, with
`width: 88` and `height: 38`. It sits on the `main_ground` at `y: 420`.

## Runtime

`BearMathGame` loads the current level's geometry and uses only:

- `backgroundAsset`;
- `playerSpawn`;
- `mentorPosition`;
- the single `main_ground`.
- the single level 1 obstacle, if present.

The bear still uses its original simple grounding logic from `PlayerBear`.
Hitbox, speed, gravity, jump force, visual offsets, feet anchor, and walk
animation are unchanged.

Obstacle collision is deliberately minimal during this rollout: it blocks the
bear while grounded, and jumping still uses the existing bear physics.

`kLevelGeometryDebugOverlay` exists in `lib/game/level_geometry.dart` and must
remain `false` by default. The baseline runtime does not need collider drawing.

## Validation

Run:

```bash
python3 tools/validate_level_geometry.py
```

The validator checks all 10 levels, per-level backgrounds, one main ground,
empty platforms, one safe level 1 obstacle, empty obstacles on levels 2-10,
sane coordinates, mentor to the right of the spawn, and both contact points on
the main ground.
