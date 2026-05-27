# Bear sit animation regeneration task

Goal: replace the current sit-down animation frames with a new set that looks like
the same bear cub as the standing/walking side-view sprite.

Problem observed:
- The current sitting bear reads as a different character from the standing bear.
- Current sit frame visible centers and bottom margins vary between frames, which
  creates position and proportion wobble during playback.
- Runtime smoothing helps, but it cannot fully fix mismatched source artwork.

Reference style:
- Use the standing/walking side-view bear as the identity reference.
- Preserve the same head shape, muzzle, eye placement, fur texture, body length,
  paw style, and soft white polar-bear look.
- Keep a clean side-view game sprite pose on transparent background.

Current status:
- A new generated `sit_down_v4` source sheet has been saved under
  `assets/_incoming/bear_cub/sit_down_v4/source_sheet_green.png`.
- The green source was converted to alpha, component-split, edge-despilled, and
  reassembled into nine aligned runtime frames under
  `assets/images/characters/bear_cub/animations/sit_down_v4/`.
- Runtime now loads `sit_down_v4` through `PlayerBear`; the previous
  `sit_down` and inactive `sit_down_v2` sets remain as old drafts.
- The active v4 frames share a `350x302` canvas and a fixed alpha bottom line
  at `y=285`, so runtime no longer needs per-frame sit alignment offsets.

Verification:
- `.venv-tools/bin/python tools/build_bear_sit_down_animation.py`
- `.venv-tools/bin/python tools/check_bear_animation_frames.py`
- `FLUTTER_SUPPRESS_ANALYTICS=true flutter test --no-pub`
- `FLUTTER_SUPPRESS_ANALYTICS=true dart analyze lib/game/components/player_bear.dart test/player_bear_sitting_test.dart`
- Browser check on `http://127.0.0.1:8777/#/game` after a full Flutter web
  restart showed the bear entering the seated state in-scene.

Runtime note:
- `PlayerBear` still uses soft frame blending for smoother motion, but v4
  disables old per-frame alignment compensation because the frames are already
  anchored by the build step.
