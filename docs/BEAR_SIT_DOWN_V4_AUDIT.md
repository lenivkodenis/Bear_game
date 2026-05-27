# Bear Sit-Down V4 Audit

Date: 2026-05-27

## Goal

Replace the previous sitting transition, where the standing and seated bear read
as different characters and the animation visibly jittered.

## Final Active Assets

```text
assets/images/characters/bear_cub/animations/sit_down_v4/bear_sit_down_v4_01.png
assets/images/characters/bear_cub/animations/sit_down_v4/bear_sit_down_v4_02.png
assets/images/characters/bear_cub/animations/sit_down_v4/bear_sit_down_v4_03.png
assets/images/characters/bear_cub/animations/sit_down_v4/bear_sit_down_v4_04.png
assets/images/characters/bear_cub/animations/sit_down_v4/bear_sit_down_v4_05.png
assets/images/characters/bear_cub/animations/sit_down_v4/bear_sit_down_v4_06.png
assets/images/characters/bear_cub/animations/sit_down_v4/bear_sit_down_v4_07.png
assets/images/characters/bear_cub/animations/sit_down_v4/bear_sit_down_v4_08.png
assets/images/characters/bear_cub/animations/sit_down_v4/bear_sit_down_v4_09.png
```

All active frames are `350x302` RGBA PNGs.

## Source Assets

```text
assets/_incoming/bear_cub/sit_down_v4/source_sheet_green.png
assets/_incoming/bear_cub/sit_down_v4/source_sheet_alpha_contract1.png
```

The generated sheet was prompted as a 12-frame, 4-by-3 sit-down sequence on a
flat green chroma-key background. The rightmost column was rejected because some
poses touched the image edge. The active v4 runtime set selects the intact poses
`1, 2, 3, 5, 6, 7, 9, 10, 11`.

## Build Tool

```text
.venv-tools/bin/python tools/build_bear_sit_down_animation.py
```

The tool:

- extracts the bear poses as connected alpha components instead of fixed cells;
- sorts components by sheet order;
- selects the intact v4 poses;
- neutralizes chroma-key edge spill;
- aligns all frames to one front-paw anchor;
- aligns all frames to one bottom contact line;
- writes runtime frames, a contact-sheet preview, and a motion GIF.

## Runtime Calibration

`PlayerBear` now uses:

```text
directory: characters/bear_cub/animations/sit_down_v4
frame size: 350x302
stepTime: 0.085
visualHeight: 124
groundInset: 7.4
softBlendMaxAlpha: 0.64
```

Old per-frame alignment offsets are disabled for this sequence because the
frames are already aligned by the build tool.

## Verification

Passed:

```text
.venv-tools/bin/python tools/check_bear_animation_frames.py
FLUTTER_SUPPRESS_ANALYTICS=true flutter test --no-pub
FLUTTER_SUPPRESS_ANALYTICS=true dart analyze lib/game/components/player_bear.dart test/player_bear_sitting_test.dart
```

`flutter analyze --no-pub` crashed inside the Flutter analysis server in this
workspace, so the changed Dart files were checked with `dart analyze` directly.

Browser verification:

- Flutter web was restarted after `flutter pub get --offline`.
- `http://127.0.0.1:8777/#/game` loaded the new asset folder.
- The bear reached the seated pose in-scene after the idle delay.
