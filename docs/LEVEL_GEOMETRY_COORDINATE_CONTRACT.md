# Level Geometry Coordinate Contract

This contract freezes how level geometry coordinates are interpreted before
platforms or obstacles are reintroduced.

## Scene Coordinates

`assets/data/level_geometry.json` is authored in an `800x600` design world.
`LevelGeometry.scaledTo(size)` scales every coordinate to the current Flame
scene size before the scene is built.

The project uses top-left positioning for collider rectangles:

- `x` grows to the right;
- `y` grows downward;
- collider `x` and `y` are the top-left corner;
- `width` grows right from `x`;
- `height` grows down from `y`.

This is not a center-based geometry model. If a future runtime component uses a
center anchor, it must convert from this top-left contract before rendering or
colliding.

## Ground Colliders

Ground collider `x` and `y` mean the top-left corner of the ground rectangle.
For a flat baseline level:

```json
{ "id": "main_ground", "x": 0, "y": 489, "width": 800, "height": 111 }
```

The top edge of any top-left ground collider is:

```text
groundTopY = collider.y
```

The production baseline now uses an individual `groundTopY` for every level.
There is no shared `groundY` baseline across all backgrounds. Do not assume one
value fits every `background.png`, because the visual snow surface is painted at
a different height in each background.

`main_ground.y` must match the visual upper line of the snow surface for that
specific level background. `main_ground.height` keeps the ground rectangle
ending at the bottom of the `800x600` design world.

Approved production `groundTopY` values:

| Level | Background key | `groundTopY` |
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

## Platform Colliders

Future platform collider `x` and `y` also mean the top-left corner of the
platform rectangle:

```text
platformTopY = platform.y
platformBottomY = platform.y + platform.height
```

For a standing surface on top of a platform, the bear's bottom line must match
`platformTopY`. Platforms are disabled in the current baseline and
`platformColliders` must stay empty until a calibrated rollout.

## Obstacle Colliders

Future obstacle collider `x` and `y` mean the top-left corner of the obstacle
rectangle. To place an obstacle on a ground surface:

```text
groundTopY = collider.y
obstacle.y = groundTopY - obstacle.height
obstacleBottomY = obstacle.y + obstacle.height
obstacleBottomY must equal groundTopY
```

Future real obstacles must follow this contract. Example for a level whose
`groundTopY` is `460`:

```text
groundTopY = 460
obstacle.height = 45
obstacle.y = groundTopY - obstacle.height
obstacle.y = 460 - 45 = 415
```

There are no active obstacles in the current flat baseline.

Calibration obstacle previews use the same top-left math, but they are not
gameplay colliders:

```text
previewObstacle.y = groundTopY - previewObstacle.height
preview.y = groundTopY - preview.height
previewBottomY = preview.y + preview.height
previewBottomY must equal groundTopY
```

If a future component uses center coordinates instead, the equivalent formula
would be:

```text
obstacle.centerY = groundTopY - obstacle.height / 2
```

That is not the current project contract. Use top-left obstacle coordinates
unless the runtime is deliberately changed and this document is updated.

## Player Spawn

`playerSpawn` is a foot/contact point on the surface where the bear starts, not
the top-left corner of the bear hitbox. Runtime places the bear with:

```text
player.position.x = playerSpawn.x
player.position.y = playerSpawn.y - PlayerBear.defaultSize.y
```

Therefore:

```text
playerSpawn.y must match the surface top Y
player hitbox bottom = player.position.y + PlayerBear.defaultSize.y
player hitbox bottom must equal playerSpawn.y while grounded
```

For the flat baseline, `playerSpawn.y` must always equal that level's
`main_ground.y`.

## Mentor Position

`mentorPosition` is also a contact point on the surface, not a top-left sprite
coordinate. Runtime places the mentor with:

```text
mentor.position.x = mentorPosition.x
mentor.position.y = mentorPosition.y - WiseMentor.defaultSize.y
```

For the flat baseline:

```text
mentorPosition.y must equal that level's main_ground.y
mentorPosition.x must be greater than playerSpawn.x
```

## Standing On A Surface

The bear is standing on a surface when the physical hitbox bottom line matches
the surface top line:

```text
playerBottomY = player.position.y + player.size.y
playerBottomY == surfaceTopY
```

If the bear floats or sinks, fix the geometry contact line first. Do not adjust
bear hitbox, gravity, jump force, or speed to hide a geometry problem. Visual
feet alignment may be calibrated only when the visual feet line and hitbox
bottom disagree.

# Player visual alignment

The player hitbox bottom must match the visual feet line. The visual sprite must
not live separately below the hitbox or float above it.

For a grounded bear:

```text
groundTopY == player hitbox bottom
player hitbox bottom == visual feet line
```

Future obstacles are placed relative to `groundTopY`. If the visual feet line
does not match the hitbox bottom, an obstacle that is mathematically correct
will still look visually wrong: it may appear buried, floating, or out of sync
with the bear's paws.

# Ground visual calibration

The player visual feet line already matches the hitbox bottom. Do not move the
bear sprite, hitbox, jump force, gravity, or speed to fix visual ground errors.

`groundTopY` must match the visual top line of the snow surface in the
background. If `groundTopY` is above the visual ground, the bear and any future
obstacle will look like they are floating. If `groundTopY` is below the visual
ground, the bear and obstacles will look sunken into the snow.

The current production flat baseline uses per-level values:

```text
main_ground.y = approved level groundTopY
playerSpawn.y = main_ground.y
mentorPosition.y = main_ground.y
```

Obstacles can only be added after the debug overlay confirms that the ground
line, hitbox bottom, visual feet line, `playerSpawn`, and `mentorPosition` all
sit on the visual snow surface.

## Debug Overlay

`kLevelGeometryDebugOverlay` is defined in `lib/game/level_geometry.dart` and
must stay off by default:

```dart
const bool kLevelGeometryDebugOverlay = false;
```

When enabled manually, the overlay draws ground rectangles, ground top lines,
future platform rectangles, calibration obstacle preview rectangles,
`playerSpawn`, `mentorPosition`, the current player hitbox, and the player
feet/bottom line. It is render-only and must not change collision, physics,
coordinates, movement, or level routes. For web calibration, enable it with
`debugGeometry=1` in the URL instead of changing the default code flag.

## Calibration Rule

Before adding platforms or obstacles again:

1. Keep `platformColliders` and `obstacleColliders` empty.
2. Enable the debug overlay with `debugGeometry=1`.
3. Confirm that `groundTopY`, `playerSpawn`, `mentorPosition`, and the bear
   bottom line all coincide on the main ground.
4. Add one test collider only after the coordinate contract is visually
   confirmed.
5. Validate and manually playtest after every collider.
