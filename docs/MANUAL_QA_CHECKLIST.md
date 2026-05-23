# Manual QA Checklist

Run this checklist before any commit.

## Minimum Check

- [ ] `flutter pub get`
- [ ] `flutter analyze`
- [ ] `flutter run -d web-server --web-port=8081`

## Browser Check

Open `http://127.0.0.1:8081` and verify:

1. [ ] The main menu opens.
2. [ ] The map opens.
3. [ ] Level 1 starts.
4. [ ] The player can reach the mentor.
5. [ ] The mentor dialog opens.
6. [ ] The question opens after the dialog intro.
7. [ ] A wrong answer shows the hint and applies the penalty.
8. [ ] The score never goes below zero.
9. [ ] A correct answer awards points.
10. [ ] The level can be completed.
11. [ ] The next level unlocks after completion.
12. [ ] Progress remains saved after restarting the browser page.
13. [ ] The final screen opens after level 10.
