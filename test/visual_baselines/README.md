# Visual baselines

These owner-reviewable JPEG files are captured from the deterministic
`flutter build web --release --dart-define=ENABLE_VISUAL_TEST_MODE=true` build
with the Playwright-pinned Chromium version from `package-lock.json`.

Generate or intentionally replace them with:

```bash
pnpm run baseline:visual
```

Normal CI runs `pnpm run test:visual`, keeps these files unchanged, applies a
0.12 per-pixel threshold and permits at most 0.3% differing pixels. On failure,
expected, actual and PNG diff artifacts are written to
`artifacts/visual-diffs/` and uploaded by GitHub Actions.

The baseline matrix is defined in `tools/visual_baseline/run_visual_tests.mjs`.
It contains 28 images: 20 level-1 checkpoint/desktop-size combinations, level
3/5/9 starts, main menu, map, first task dialog, collision overlay and the final
1280 × 720 resize-round-trip frame.
