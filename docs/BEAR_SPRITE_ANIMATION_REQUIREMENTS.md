# Bear Cub Sprite Animation Requirements

Date: 2026-05-24

## Goal

Replace procedural movement with real frame-by-frame bear cub animation.

## Why One PNG Is Not Enough

One static PNG can only move, scale, and tilt. It cannot show the paws changing position, the body shifting weight, or the bear settling into snow. Those details require separate sprite frames.

The current procedural animation is temporary. It must not be treated as final walking animation.

## Current Asset Classification

Static side-view candidates:

- `assets/images/characters/bear_cub/processed/bear_cub_base_1_clean.png`
- `assets/images/characters/bear_cub/processed/bear_cub_base_3_clean.png`
- `assets/images/characters/bear_cub/processed/bear_cub_base_5_clean.png`
- `assets/images/characters/bear_cub/processed/bear_cub_base_5_clean_v2_conservative.png`

Front idle candidates:

- `assets/images/characters/bear_cub/processed/bear_cub_base_2_clean.png`
- `assets/images/characters/bear_cub/processed/bear_cub_base_2_clean_v2_conservative.png`

Possible walk-frame references:

- `assets/images/characters/bear_cub/processed/bear_cub_base_1_clean.png`
- `assets/images/characters/bear_cub/processed/bear_cub_base_3_clean.png`
- `assets/images/characters/bear_cub/processed/bear_cub_base_5_clean_v2_conservative.png`

These are only separate single poses. They do not share a stable canvas, scale, ground line, or frame naming contract, so they are not a real walk cycle.

Possible jump frames:

- No dedicated jump PNG exists yet.

Possible sit frames:

- `assets/images/characters/bear_cub/processed/bear_cub_base_6_clean.png`

This is a sitting-pose candidate only. It still needs manual verification before gameplay use.

Processed files:

- All files in `assets/images/characters/bear_cub/processed/`.

Source files:

- All files in `assets/images/characters/bear_cub/source/`.

Real animation frames:

- No real `idle`, `walk`, `jump`, or `sit` animation frames exist yet.
- The folders under `assets/images/characters/bear_cub/animations/` currently contain only `.gitkeep` placeholders.

Full walking animation is currently impossible because the project does not yet have real walk frames.

## Required States

### idle

Minimum 2 frames:

- the bear cub calmly stands;
- subtle breathing;
- paws stay on the same ground line.

Files:

- `idle_01.png`
- `idle_02.png`

### walk

Minimum 6 frames:

- `walk_01.png`
- `walk_02.png`
- `walk_03.png`
- `walk_04.png`
- `walk_05.png`
- `walk_06.png`

Requirements:

- side view;
- the bear cub faces right;
- paws genuinely change position;
- body subtly shifts weight;
- identical scale;
- identical ground line;
- identical canvas size.

### jump

Minimum 1-3 frames:

- `jump_01.png`
- optional `jump_up.png`
- optional `jump_down.png`

### sit

Minimum 1-2 frames:

- `sit_01.png`
- optional `sit_02.png`

Needed for the meeting with the mentor.

## Technical Requirements For All Frames

- PNG format;
- real transparent background;
- no drawn checkerboard background;
- identical canvas size for all frames in one state;
- identical bear cub scale;
- identical ground line;
- no large unnecessary transparent padding;
- facing right;
- if left movement is needed, the game will use `flipX`;
- filenames must be strict `snake_case`;
- no spaces or Cyrillic characters in filenames.

## Recommended Canvas

The current processed side-view gameplay PNG is:

```text
assets/images/characters/bear_cub/processed/bear_cub_base_5_clean_v2_conservative.png
```

Actual size:

```text
1128x922 px
```

Recommended starting canvas for side-view animation frames:

- width: about `1128 px`, matching the current clean side-view sprite width;
- height: about `922 px`, matching the current clean side-view sprite height;
- add only a small top/bottom margin if the walk cycle needs room for bounce or fur outline;
- keep the same canvas size across every frame in one state;
- keep the paws on a shared ground line.

If a future hand-cleaned side-view sprite changes size, update this section before producing animation frames.

## Quality Check

Frames are ready only if:

- paws do not jump vertically when frames switch;
- the bear cub does not change size;
- the outline does not jitter;
- the ground line matches;
- the background is fully transparent;
- there are no white or gray artifacts around the fur.

## Future Folder Contract

Animation frames must be placed here:

```text
assets/images/characters/bear_cub/animations/idle/
assets/images/characters/bear_cub/animations/walk/
assets/images/characters/bear_cub/animations/jump/
assets/images/characters/bear_cub/animations/sit/
```

Until real frames exist, each folder may contain only `.gitkeep`.

## Checker Script

Use:

```text
.venv-tools/bin/python tools/check_bear_animation_frames.py
```

The checker validates folder presence, PNG names, alpha channel, frame dimensions, and matching walk-frame sizes. It does not edit images.

## Next Stage

After frames appear:

1. Check sizes and transparency.
2. Create a contact sheet preview.
3. Connect `walk` as `SpriteAnimation`.
4. Connect `idle` as `SpriteAnimation`.
5. Connect `jump` and `sit` states.
6. Verify grounding.
