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

- `flutter analyze`
- `flutter test`
- Mentor question opening
- Correct and wrong answer behavior
- Level completion
- Next location unlock

Manual browser flow:

1. Map -> level -> mentor -> dialog -> question.
2. Wrong answer -> hint.
3. Correct answer -> points.
4. Level completion -> next location unlock.
