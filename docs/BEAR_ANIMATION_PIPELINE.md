# Bear Animation Pipeline

Date: 2026-05-24

# Next step: real sprite frames

The current procedural animation on one PNG is temporary. It can make the static sprite breathe, tilt, bob, and squash/stretch, but it cannot create real walking: paws, shoulders, body weight, and snow contact do not change as independent drawn poses.

Real walking requires real `walk` frames. Do not try to ship final walking by deforming one PNG, generating fake limbs from one PNG, or increasing procedural tilt/scale.

Prepared folders:

```text
assets/images/characters/bear_cub/animations/idle/
assets/images/characters/bear_cub/animations/walk/
assets/images/characters/bear_cub/animations/jump/
assets/images/characters/bear_cub/animations/sit/
```

Until real frames exist, these folders may contain only `.gitkeep`.

Frame requirements are documented in:

```text
docs/BEAR_SPRITE_ANIMATION_REQUIREMENTS.md
```

Check future frames with:

```text
.venv-tools/bin/python tools/check_bear_animation_frames.py
```

The checker validates folder presence, PNG names, alpha channel, canvas sizes, and matching walk-frame sizes. It does not modify images.

Next implementation rule: replace the procedural walking transform only after verified `walk_01.png` through at least `walk_06.png` exist with matching canvas size, matching scale, transparent background, and a stable ground line.

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
- `feetToGroundOffset` accounts for the visual snow surface being lower than the current physics ground line.
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

# Animation State Machine

## Available bear assets

Current files under `assets/images/characters/bear_cub/` are single-frame sources and processed PNGs, not animation sequences.

- Idle candidates: `bear_cub_base_2_clean_v2_conservative.png` for front idle, and the current side-view `bear_cub_base_5_clean_v2_conservative.png` as the gameplay idle fallback.
- Walk candidates: `bear_cub_base_1_clean.png`, `bear_cub_base_3_clean.png`, and `bear_cub_base_5_clean_v2_conservative.png` are side-view or walking-like single poses, but they do not form a consistent walk cycle.
- Jump candidates: no dedicated jump PNG exists yet.
- Sit candidates: `bear_cub_base_6_clean.png` is the closest sitting pose, but it is not yet cleaned/verified enough for gameplay.
- Side-view candidates: `bear_cub_base_1_clean.png`, `bear_cub_base_3_clean.png`, `bear_cub_base_5_clean.png`, `bear_cub_base_5_clean_v2_conservative.png`.
- Front-view candidates: `bear_cub_base_2_clean.png`, `bear_cub_base_2_clean_v2_conservative.png`.

## Active states

`PlayerBear` exposes `BearAnimationState` with:

- `idle`
- `walking`
- `jumping`
- `interacting`
- `sitting`

The current selector is:

- `sitting` when explicitly requested by future scene code;
- `interacting` when the mentor interaction starts;
- `jumping` while the bear is airborne;
- `walking` while horizontal velocity is active;
- `idle` otherwise.

## Current fallback behavior

All states currently render the same verified side-view static sprite:

```text
assets/images/characters/bear_cub/processed/bear_cub_base_5_clean_v2_conservative.png
```

State-specific motion is procedural:

- `idle`: subtle scale breathing only; no vertical bob, so the feet stay planted.
- `walking`: tiny bob, tilt, and squash/stretch around the grounded contact point.
- `jumping`: no walk bob; slight tilt/stretch while rising and mild compression while falling.
- `interacting`: calm idle fallback after the bear reaches the mentor.
- `sitting`: future state, currently calm idle fallback until a verified sit PNG exists.

## Future frame requirements

A true walk sequence needs multiple side-view PNG frames with:

- consistent RGBA transparency;
- matching canvas size;
- matching scale and direction;
- stable bottom-center feet anchor;
- frame names or manifest entries that map cleanly to `BearAnimationState.walking`.

A true sit animation needs at least one verified side-view sitting PNG with the same visual anchor policy. Dedicated jump and idle frames should follow the same frame manifest and grounding rules.
