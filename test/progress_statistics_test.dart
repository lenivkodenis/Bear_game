import 'dart:convert';

import 'package:bear_game/models/learning_statistics.dart';
import 'package:bear_game/screens/progress_screen.dart';
import 'package:bear_game/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('progress screen shows total, level, and task statistics', (
    tester,
  ) async {
    final statistics = LearningStatistics.empty
        .recordAttempt(
          levelId: 1,
          locationName: 'Льдина',
          questionId: 1,
          questionNumber: 1,
          expression: '1 x 1',
          isCorrect: false,
          elapsedMilliseconds: 12000,
        )
        .recordAttempt(
          levelId: 1,
          locationName: 'Льдина',
          questionId: 1,
          questionNumber: 1,
          expression: '1 x 1',
          isCorrect: true,
          elapsedMilliseconds: 18000,
        )
        .recordAttempt(
          levelId: 1,
          locationName: 'Льдина',
          questionId: 2,
          questionNumber: 2,
          expression: '1 x 2',
          isCorrect: true,
          elapsedMilliseconds: 30000,
        );
    SharedPreferences.setMockInitialValues({
      'score': 2,
      'solved_examples': 2,
      'unlocked_location': 2,
      'completed_level_ids': ['1'],
      'learning_statistics': jsonEncode(statistics.toJson()),
    });

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.theme, home: const ProgressScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await _scrollTo(tester, 'Накопительная статистика');
    expect(find.text('Накопительная статистика'), findsOneWidget);
    expect(find.text('Уровень 1 · Льдина'), findsOneWidget);
    expect(find.text('Ошибки'), findsNWidgets(2));
    expect(find.text('67%'), findsNWidgets(2));

    await _scrollTo(tester, 'Показать задачи (2)');
    await tester.tap(find.text('Показать задачи (2)'));
    await tester.pump();

    expect(find.text('1 x 1'), findsOneWidget);
    expect(find.text('1 x 2'), findsOneWidget);
    expect(find.text('Ошибки: 1'), findsOneWidget);
    expect(find.textContaining('Попыток: 2'), findsOneWidget);
  });
}

Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.dragUntilVisible(
    find.text(text),
    find.byType(ListView),
    const Offset(0, -300),
  );
  await tester.pump();
}
