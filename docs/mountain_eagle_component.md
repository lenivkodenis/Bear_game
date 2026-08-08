# Mountain Eagle Ambient Component

Component file:

`lib/game/components/ambient/mountain_eagle_ambient.dart`

The component class is `MountainEagleAmbient`. It is a decorative-only Flame
component: it has no collision hitbox, does not touch `PlayerBear`, does not
change obstacle collision, and does not alter level geometry.

The component uses the normalized RGBA frames from:

`assets/images/characters/mountain_eagle/animations/fly_land_takeoff/`

Frame groups:

- Fly in: `mountain_eagle_01_glide.png`,
  `mountain_eagle_02_approach.png`,
  `mountain_eagle_03_descent.png`, repeated three times in code for denser
  wingbeats.
- Landing: `mountain_eagle_04_brake.png`,
  `mountain_eagle_05_touchdown.png`
- Perched pause: `mountain_eagle_06_settle.png`,
  `mountain_eagle_07_stand.png`
- Takeoff: `mountain_eagle_08_takeoff_prepare.png`,
  `mountain_eagle_09_takeoff_push.png`,
  `mountain_eagle_10_takeoff_upstroke.png`,
  `mountain_eagle_11_depart.png`, with the push/upstroke/depart beat repeated
  in code.
- Fly out: `mountain_eagle_10_takeoff_upstroke.png`,
  `mountain_eagle_11_depart.png`, repeated three times in code.

Public constructor parameters:

- `entryPoint`: offscreen point where the eagle begins the cycle.
- `perchPoint`: decorative landing/perch point.
- `exitPoint`: offscreen point where the eagle leaves.
- `size`: rendered sprite size.
- `spawnFromLeft`: default facing direction while idle.
- `cycleInterval`: wait time after one full cycle before starting again.
- `perchDuration`: time spent on the perch point.
- `initialDelay`: wait before the first cycle.
- `flyInDuration`, `landingDuration`, `takeoffDuration`, `flyOutDuration`:
  per-phase timing controls.
- `priority`: Flame render priority.
- `isActive`: optional predicate that pauses and resets the cycle until the
  ambient scene should run.

State machine:

`waiting -> flyIn -> landing -> perchedPause -> takeoff -> flyOut -> waiting`

Level hookup:

The component is connected only through `MountainPassAmbientEffect` in
`lib/game/components/ambient/level_ambient_effects.dart`. See
`docs/mountain_eagle_ambient.md` for the level-specific coordinates and timing.
