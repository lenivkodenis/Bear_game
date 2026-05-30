# Snow Bunny Ambient

The snow bunny is a decorative-only ambient character for level 4,
`Северный лес`.

Evidence for the forest level:

- `assets/data/levels.json` has level `id: 4` with title and `locationName`
  `Северный лес`.
- `assets/data/level_geometry.json` maps `levelId: 4` to
  `assets/images/levels/level_04_northern_forest/background.png`.
- `docs/LEVEL_BACKGROUND_RUNTIME.md` also documents level 4 as
  `Северный лес`.

Source frames remain in:

`assets/images/characters/snow_bunny/animations/hop_turn/`

Those source PNGs are RGB files with a checkerboard background and no alpha
channel, so the runtime uses corrected gameplay copies in:

`assets/images/characters/snow_bunny/animations/hop_turn/alpha/`

The `alpha/` folder is explicitly listed in `pubspec.yaml` so Flame can load
the runtime frames.

Runtime frame order:

1. `snow_bunny_01_crouch_right.png`
2. `snow_bunny_02_push_right.png`
3. `snow_bunny_03_jump_right.png`
4. `snow_bunny_04_fly_right.png`
5. `snow_bunny_05_land_right.png`
6. `snow_bunny_06_turn_start.png`
7. `snow_bunny_07_turn_pivot.png`
8. `snow_bunny_08_crouch_left.png`
9. `snow_bunny_09_push_left.png`
10. `snow_bunny_10_jump_left.png`
11. `snow_bunny_11_fly_left.png`
12. `snow_bunny_12_land_left.png`

The component is `SnowBunnyAmbient`. It is connected only for level 4 through
`AmbientEffectsFactory`, uses the right-facing hop frames to enter from the
left edge, holds the seated turn/crouch frames for the 2-second visible pause,
then uses the left-facing hop frames to return offscreen. After leaving, it
waits 10 seconds before the next appearance.

The animation is gated by the player position. It can start only after the
bear's left side has moved beyond the right edge of the first obstacle in the
forest level. If the bear moves back before that threshold, the bunny resets
offscreen and will not jump out. This keeps the bunny decorative and prevents
the player from trying to catch it.

It has no collision hitbox and does not change player physics, obstacle
collision, or level geometry.
