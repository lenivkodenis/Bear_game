# Mountain Eagle Ambient Level Hookup

The mountain eagle is connected only to level 7, "Gorny pereval" / Mountain
Pass, through `MountainPassAmbientEffect` in:

`lib/game/components/ambient/level_ambient_effects.dart`

Level 4 remains the snow bunny level. The eagle uses the branch marked on the
left side of the level 7 mountain-pass background.

Component:

`MountainEagleAmbient`

Assets:

`assets/images/characters/mountain_eagle/animations/fly_land_takeoff/`

`pubspec.yaml` lists this exact runtime folder so Flutter bundles the frames for
tests and gameplay.

Route:

- Perch point source anchor: `Offset(0.078, 0.445)` in the `1672x941`
  mountain-pass background, approximately `Vector2(130, 419)` before scaling.
- Entry point: left of the visible viewport, above the perch point.
- Exit point: left of the visible viewport, higher than the entry point.

The source anchor is converted to viewport coordinates with the same centered
`BoxFit.cover` math used by the background renderer. This keeps the eagle tied
to the marked branch when the level is shown at different aspect ratios.

Motion parameters:

- Eagle size: `min(width, height) * 0.10`, clamped to `52..68`.
- Cycle interval: `10.0` seconds.
- Initial delay: `0.9` seconds after the mountain-pass level is mounted.
- Fly in: `1.8` seconds.
- Landing: `0.72` seconds.
- Perched pause: `1.8` seconds.
- Takeoff: `1.1` seconds.
- Fly out: `1.45` seconds.

Wingbeat pacing:

The runtime uses the same PNG files, but repeats the flight wingbeat frame
sequence in code. Fly-in, takeoff, and fly-out now contain roughly three times
more wingbeat frame steps than the first hookup, without duplicating PNG files
on disk.

The eagle is decorative only. It has no hitbox, creates no colliders, does not
touch player movement, does not alter level geometry, and does not affect
obstacle collision.
