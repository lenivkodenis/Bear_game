# Level Geometry Guide

Файл `assets/data/level_geometry.json` описывает упрощённую физическую
геометрию уровней. Он не должен повторять фон пиксель в пиксель: фон остаётся
артом, а геометрия задаёт понятный игровой маршрут.

## Coordinate System

Геометрия задана в дизайн-координатах `800x600` и масштабируется под текущий
размер сцены. `playerSpawn` и `mentorPosition` задают нижнюю точку контакта с
поверхностью: runtime ставит hitbox медвежонка и мудреца так, чтобы их нижний
край стоял на указанной `y`.

## JSON Shape

```json
{
  "world": { "width": 800, "height": 600 },
  "levels": [
    {
      "levelId": 1,
      "backgroundAsset": "assets/images/levels/level_01_ice_floe/background.png",
      "playerSpawn": { "x": 72, "y": 420 },
      "mentorPosition": { "x": 670, "y": 420 },
      "groundColliders": [],
      "platformColliders": [],
      "obstacleColliders": [],
      "notes": "Route notes for validation and future tuning."
    }
  ]
}
```

## Ground Colliders

`groundColliders` are broad walkable rectangles. Use them for the main snow,
ice, shore, cave floor, or mountain shelf. A flat safe level usually needs one
ground collider from the left edge to the right edge.

Each collider uses top-left `x`, `y`, plus `width` and `height`.

## Platform Colliders

`platformColliders` are extra walkable steps or shelves. Keep them wide enough
for landing, avoid tall climbs, and keep gaps short. Level 5 uses platforms for
the ice-cave route: left start, lower center, small step, upper step, and final
right platform.

## Obstacle Colliders

`obstacleColliders` are simple solid rectangles for low logs, rocks, ice ridges,
crystals, snowdrifts, and similar jump targets. They should stay low and narrow:
the current validator allows obstacle heights up to `48` design pixels.

## Why Geometry Is Simplified

The backgrounds contain decorative snow, ice, branches, crystals, and cave
shapes. Giving every detail a collider would make the game brittle and hard to
tune. Instead, each level gets a simple route:

`start -> 1-3 obstacles/platforms -> clear mentor area`

This keeps levels readable, safe for children, and independent from tiny art
changes.

## Playability Rules

Before committing geometry changes, run:

```bash
python3 tools/validate_level_geometry.py
```

The validator checks that all 10 levels exist, backgrounds exist, starts and
mentors stand on walkable surfaces, obstacles are jumpable, platforms are wide
enough, climbs are modest, and route notes are present.

When tuning by hand, prefer safer values:

- obstacle height below `48`;
- platform width at least `96`;
- upward step below `60`;
- horizontal gap below `130`;
- clean flat space before `mentorPosition`.

Do not change bear physics to fit a level. Adjust the rectangles instead.

## Debug Overlay

Collider rendering is controlled by:

```dart
const bool kLevelGeometryDebugOverlay = false;
```

The flag lives in `lib/game/level_geometry.dart`. Set it to `true` locally to
draw:

- blue ground colliders;
- green platform colliders;
- red obstacle colliders;
- yellow player spawn marker;
- purple mentor marker.

Keep the flag `false` in committed gameplay builds.

## Adding Or Editing A Level

1. Keep the level's `backgroundAsset` pointed at its own
   `assets/images/levels/level_XX_.../background.png`.
2. Place `playerSpawn` on the first walkable surface.
3. Place `mentorPosition` on a clean final surface near the right side.
4. Add one broad `groundCollider` for simple levels.
5. Add up to three low `obstacleColliders`.
6. Add `platformColliders` only when the route needs steps or shelves.
7. Update `notes` with the intended route.
8. Run the validator, `flutter test`, and `flutter analyze`.
