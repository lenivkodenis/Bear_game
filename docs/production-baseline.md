# BearMath production baseline

This document records the last owner-confirmed safe production state before the
visual safety harness was introduced. It does not change or redeploy production.

## Recorded state

- Date: 2026-08-10 (Europe/Moscow)
- Source branch: `main`
- Source SHA: `686e22a18f05c3c85c8db882d33641aed1b6a274`
- Published branch: `web-deploy`
- Deploy SHA: `f774796c7695413611c06addb2225b1b3da231fb`
- Deploy commit: `Deploy Flutter Web from 686e22a18f05c3c85c8db882d33641aed1b6a274`
- Flutter: `3.44.9` (stable)
- Dart: `3.12.2`

## Required desktop baseline sizes

- 1280 × 720
- 1440 × 900
- 1920 × 1080
- 2048 × 1000

The automated matrix covers level 1 at all five deterministic checkpoints at
every size. The other mandatory screens are captured at 1280 × 720. Real
Fullscreen API behavior remains a manual check because changing a Playwright
viewport is not equivalent to entering browser fullscreen.

## Production admission criteria

1. CI formatting, analysis, Flutter tests and production Web release build pass.
2. `build/web` contains no Git LFS pointer files.
3. Browser screenshots match the approved baseline within the configured minimal
   tolerance, or every intentional difference has explicit owner approval.
4. Manual desktop checks pass at all required sizes, including a real fullscreen
   round trip and gameplay through both level 1 obstacles to the mentor.
5. The exact full source SHA is contained in `origin/main` and is entered in the
   manual production workflow.
6. The workflow summary shows the intended source SHA and commit message before
   production is considered released.

## Manual rollback

Rollback is a new manual production publication of the last known-safe source;
it does not rewrite `main` or edit generated `web-deploy` by hand.

1. Open **Actions → Build and deploy Flutter Web → Run workflow**.
2. Enter source SHA `686e22a18f05c3c85c8db882d33641aed1b6a274`.
3. Confirm the workflow summary displays that SHA and its commit message.
4. Wait for the build and `web-deploy` publication to complete successfully.
5. Verify `https://bearmath.ru` with a cache-bypassing reload at the required
   desktop sizes and with real fullscreen.

## Optional owner-created safety tag

After the owner completes the manual checks, the proposed tag is
`production-safe-2026-08-10`:

```bash
git tag -a production-safe-2026-08-10 686e22a18f05c3c85c8db882d33641aed1b6a274 -m "Owner-verified BearMath production baseline 2026-08-10"
git push origin production-safe-2026-08-10
```

Do not create this tag until the owner explicitly approves the baseline.
