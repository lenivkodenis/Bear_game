# Testing Strategy

These tests protect the playable MVP mechanics before future visual design work.

## Added Tests

- `test/level_data_test.dart` checks that `assets/data/levels.json` exists, loads 10 levels, and every level/question has the required educational fields.
- `test/game_math_test.dart` checks answer scoring: correct answers add points, wrong answers apply penalties, and the score never goes below zero.
- `test/progress_test.dart` checks progression: level 1 is available at the start, completing a level unlocks the next one, and completing level 10 creates the final progress state.
- `test/mechanics_contract_test.dart` checks that damaged level data fails fast when questions, answer options, or correct answers break the mechanics contract.

## What They Protect

The tests protect the data-driven level flow, mentor question contract, scoring rules, penalty rules, level unlocks, and final completion state. They are intentionally focused on mechanics, not visual design.

## Required Commands Before Each Commit

Run:

```sh
flutter pub get
flutter analyze
flutter test
```

For manual web QA, also run:

```sh
flutter run -d web-server --web-port=8081
```

Then open `http://127.0.0.1:8081` and verify the flow from the manual QA checklist.

## Design Task Rule

A design task is not complete until these tests pass. Visual changes can move buttons, colors, spacing, and presentation, but they must not break loading levels, reaching the mentor, opening questions, answer scoring, hints, level completion, next-level unlocks, or the final state.
