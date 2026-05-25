# Level Geometry Coordinate Contract

This contract freezes how level geometry coordinates are interpreted before
obstacles are reintroduced.

## Scene Coordinates

`assets/data/level_geometry.json` is authored in an `800x600` design world.
`LevelGeometry.scaledTo(size)` scales every coordinate to the current Flame
scene size.

Flame `PositionComponent` coordinates use top-left positioning:

- `x` grows to the right;
- `y` grows downward;
- `position` is the top-left corner unless a component explicitly sets another
  anchor.

## Ground Colliders

Ground collider `x` and `y` are the top-left corner of the ground rectangle.

For the current baseline:

```json
{ "id": "main_ground", "x": 0, "y": 420, "width": 800, "height": 180 }
```

The top edge of the ground is:

```text
groundTopY = main_ground.y
```

The baseline ground top is `420` in the `800x600` design world.

## Player Spawn

`playerSpawn` is a foot/contact point on the main ground, not the top-left of
the bear hitbox.

Runtime places the bear with:

```text
player.position.x = playerSpawn.x
player.position.y = playerSpawn.y - PlayerBear.defaultSize.y
```

Therefore:

```text
playerSpawn.y must equal groundTopY
player hitbox bottom = player.position.y + PlayerBear.defaultSize.y
player hitbox bottom must equal playerSpawn.y
```

If the bear floats or sinks, fix the geometry contact line first. Do not adjust
bear hitbox, gravity, jump force, speed, visual offset, or feet anchor.

## Obstacle Colliders

Future obstacle collider `x` and `y` must mean the top-left corner of the
obstacle rectangle.

The project uses the top-left variant:

```text
obstacle.y = groundTopY - obstacle.height
```

If a future component uses center coordinates instead, the equivalent formula
would be:

```text
obstacle.centerY = groundTopY - obstacle.height / 2
```

But that is not the current project contract. Use top-left obstacle coordinates
unless the runtime is deliberately changed and documented.

## Ground Contact Rules

For every obstacle that sits on the ground:

```text
obstacleBottomY = obstacle.y + obstacle.height
obstacleBottomY must equal groundTopY
```

An obstacle must not float above ground:

```text
obstacle.y + obstacle.height < groundTopY
```

An obstacle must not be buried into the ground:

```text
obstacle.y + obstacle.height > groundTopY
```

Small visual softness in art is acceptable, but the physics rectangle must use
the exact formula.

## Next Calibration Step

Before adding obstacles again:

1. Keep `obstacleColliders` empty.
2. Add or enable a debug overlay for `main_ground`, `playerSpawn`, and a single
   test obstacle rectangle.
3. Confirm visually that `groundTopY`, bear hitbox bottom, and obstacle bottom
   coincide.
4. Only then add one obstacle to level 1 and validate it mathematically.

## Debug Overlay

`kLevelGeometryDebugOverlay` is defined in `lib/game/level_geometry.dart` and
must stay off by default:

```dart
const bool kLevelGeometryDebugOverlay = false;
```

The next step before any new obstacle rollout is a debug/calibration pass, not
new obstacle placement.
