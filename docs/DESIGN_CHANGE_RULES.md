# Design Change Rules

Design changes must preserve the playable MVP mechanics.

## Do Not Change

Design-only tasks must not change:

- `assets/data/levels.json`
- `ProgressService`
- Level and question models
- Mentor/question opening logic
- Score and penalty logic
- Level unlock logic
- Final completion screen logic

## Before Any Design Task

1. Read `docs/MECHANICS_CONTRACT.md`.
2. Read `docs/MANUAL_QA_CHECKLIST.md`.
3. Check `git status`.
4. Create a separate branch.
5. Change only the UI layer.

## After Any Design Task

Always verify:

- Mentor question opening
- Correct and wrong answer behavior
- Level completion
- Next location unlock
