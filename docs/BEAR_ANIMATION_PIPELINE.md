# Bear Animation Pipeline

Date: 2026-05-24

## Current static sprite

The first level currently uses one cleaned RGBA PNG:

```text
assets/images/characters/bear_cub/processed/bear_cub_base_5_clean_v2_conservative.png
```

It is loaded by `PlayerBear` and rendered as a visual sprite over the stable gameplay hitbox. The physical hitbox remains separate from the image bounds so transparent PNG padding and future animation frames do not change collision behavior.

## Grounding

Grounding is handled with explicit visual alignment constants in `PlayerBear`:

- `visualSize` controls the rendered sprite size.
- `visualGroundInset` accounts for the transparent/soft bottom edge of the PNG.
- `visualSnowContactOffset` accounts for the visual snow surface being lower than the current physics ground line.
- `visualFeetAnchor` is the local point where the bear's feet should touch the snow.
- `visualOffset` is derived from that contact point so the visible bottom of the sprite aligns with the intended feet line.

The gameplay hitbox, gravity, jump impulse, movement speed, and collision clamp are unchanged. A temporary `kBearDebugOverlay` flag is available and defaults to `false`. When enabled, it draws the hitbox, visual sprite bounds, physics ground line, visible sprite bottom, and feet anchor line.

## Prepared animation states

`BearAnimationState` is prepared for:

- `idle`
- `walking`
- `jumping`
- `interacting`
- `sitting`

The `sitting` state is a future state. Until a dedicated sitting PNG exists, it falls back to the same calm visual behavior as `interacting`/`idle`.

## Procedural animation now

The current one-PNG implementation uses temporary procedural motion:

- `idle`: subtle scale breathing around the feet anchor.
- `walking`: small bob, gentle tilt, and mild squash/stretch.
- `jumping`: slight tilt plus stretch while rising and compression while falling.
- `interacting`: calm idle behavior near the mentor.
- `sitting`: prepared fallback to calm idle behavior.

The walking bob is deliberately tiny so it does not break the grounded pose.

## Needed PNG frames

The next asset step should prepare real transparent PNG frames:

- idle frames with a stable feet anchor;
- walk frames with consistent canvas size and foot contact policy;
- one or more jump frames;
- a sit frame for mentor interaction.

Each frame should use RGBA transparency, matching scale, matching side-view direction, and a consistent anchor at the bottom center of the feet.

## Future sprite-sheet animation

A future sprite-sheet stage should:

1. Build a consistent frame manifest for each animation state.
2. Preserve the current gameplay hitbox.
3. Use per-state visual anchors rather than image bounds for collision.
4. Replace the procedural walking/idle/jump transforms only after real frames are verified in the scene.
5. Keep debug overlay support while tuning frame pivots and contact points.
