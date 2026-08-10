# BearMath visual baseline report

Recorded on 2026-08-10 from the owner-confirmed safe source
`686e22a18f05c3c85c8db882d33641aed1b6a274`. The harness is compile-time
guarded and the screenshots come from a release build made with
`ENABLE_VISUAL_TEST_MODE=true`; no production deployment was run.

## Automated matrix

The pinned Playwright 1.62.0 browser is Chromium 151.0.7922.34. Baselines are
JPEG files in `test/visual_baselines/`; failed comparisons write expected,
actual and PNG diff files to `artifacts/visual-diffs/`.

- Level 1 `start`, `beforeFirstObstacle`, `onFirstObstacle`,
  `beforeSecondObstacle` and `mentor` at 1280 × 720, 1440 × 900,
  1920 × 1080 and 2048 × 1000: 20 screenshots.
- Level 3, 5 and 9 `start` at 1280 × 720: 3 screenshots.
- Main menu, fully unlocked location map and the first level-1 math task at
  1280 × 720: 3 screenshots.
- Level-1 collision overlay at 1280 × 720: 1 screenshot. The ordinary level-1
  start image is its non-overlay comparison.
- Level-1 1280 × 720 → 1920 × 1080 → 1280 × 720 resize round trip: 1
  screenshot, with level, score and checkpoint asserted before and after both
  resizes.

Total: 28 screenshots. The final local comparison passed 28/28 with 0.000%
pixel difference. A per-pixel threshold of 0.12 and a maximum 0.3% differing
pixels are allowed to absorb minimal renderer noise; this local run did not use
that allowance.

## Visual review

- Level-1 ground and both obstacle collider rectangles align with the painted
  ground and rocks.
- The player collision rectangle and foot line align with the bear's stance on
  the ground and first obstacle.
- The mentor interaction circle is rendered in the same world coordinate
  system as the scene.
- Main menu, map, first task dialog and the sampled level 3/5/9 starts load real
  tracked assets; no placeholder or missing-asset frame was observed.

## Existing behavior intentionally not fixed here

Changing a desktop viewport size causes `GameScreen` to create a new
`BearMathGame` instance. The deterministic fixture reloads the same level,
score and checkpoint, so the required observable resize assertions pass, but
this does not prove that arbitrary live in-memory gameplay state survives a
real fullscreen transition. This behavior existed in the safe source and is
recorded for the future viewport/fullscreen task; it is not changed in this
branch.

Programmatic `page.setViewportSize` is not a Fullscreen API test. Before any
production release, manually enter and exit real browser fullscreen at every
required desktop size and verify the active player position, current question,
score, both obstacles, mentor interaction and background composition.

## Reproduction

```bash
flutter build web --release --dart-define=ENABLE_VISUAL_TEST_MODE=true
pnpm install --frozen-lockfile
pnpm exec playwright install chromium
pnpm run test:visual
```

To intentionally regenerate owner-reviewed baselines, replace the final command
with `pnpm run baseline:visual`.
