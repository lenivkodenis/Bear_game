import 'dart:convert';

import 'package:bear_game/models/learning_statistics.dart';
import 'package:bear_game/models/player_progress.dart';
import 'package:bear_game/services/progress_service.dart';
import 'package:bear_game/utils/statistics_format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('learning statistics calculate level and total metrics', () {
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

    final level = statistics.forLevel(1)!;
    expect(level.completedQuestions, 2);
    expect(level.totalWrongAnswers, 1);
    expect(level.totalCorrectAnswers, 2);
    expect(level.totalAttempts, 3);
    expect(level.totalElapsedMilliseconds, 60000);
    expect(level.averageMillisecondsPerQuestion, 30000);
    expect(level.accuracyPercent, 67);
    expect(statistics.completedQuestions, 2);
    expect(statistics.totalWrongAnswers, 1);
    expect(statistics.accuracyPercent, 67);
  });

  test('repeated correct answers after a restart remain separate attempts', () {
    final statistics = LearningStatistics.empty
        .recordAttempt(
          levelId: 1,
          locationName: 'Льдина',
          questionId: 1,
          questionNumber: 1,
          expression: '1 x 1',
          isCorrect: true,
          elapsedMilliseconds: 5000,
        )
        .recordAttempt(
          levelId: 1,
          locationName: 'Льдина',
          questionId: 1,
          questionNumber: 1,
          expression: '1 x 1',
          isCorrect: true,
          elapsedMilliseconds: 4000,
        );

    final question = statistics.forLevel(1)!.questions[1]!;
    expect(question.correctAnswers, 2);
    expect(question.attempts, 2);
    expect(statistics.completedQuestions, 1);
    expect(statistics.accuracyPercent, 100);
  });

  test('average time includes a task that only has a wrong attempt', () {
    final statistics = LearningStatistics.empty.recordAttempt(
      levelId: 1,
      locationName: 'Льдина',
      questionId: 1,
      questionNumber: 1,
      expression: '1 x 1',
      isCorrect: false,
      elapsedMilliseconds: 7000,
    );

    expect(statistics.forLevel(1)!.averageMillisecondsPerQuestion, 7000);
    expect(statistics.averageMillisecondsPerQuestion, 7000);
  });

  test('learning statistics are saved and loaded with progress', () async {
    SharedPreferences.setMockInitialValues({});
    final statistics = LearningStatistics.empty.recordAttempt(
      levelId: 2,
      locationName: 'Река',
      questionId: 3,
      questionNumber: 3,
      expression: '2 x 3',
      isCorrect: false,
      elapsedMilliseconds: 42000,
    );
    final progress = PlayerProgress.initial().copyWith(
      learningStatistics: statistics,
    );

    await ProgressService().saveProgress(progress);
    final loaded = await ProgressService().loadProgress();

    final question = loaded.learningStatistics.forLevel(2)!.questions[3]!;
    expect(question.expression, '2 x 3');
    expect(question.wrongAnswers, 1);
    expect(question.elapsedMilliseconds, 42000);
  });

  test('full progress reset removes learning statistics', () async {
    SharedPreferences.setMockInitialValues({
      'learning_statistics': jsonEncode(
        LearningStatistics.empty
            .recordAttempt(
              levelId: 1,
              locationName: 'Льдина',
              questionId: 1,
              questionNumber: 1,
              expression: '1 x 1',
              isCorrect: true,
              elapsedMilliseconds: 10000,
            )
            .toJson(),
      ),
    });

    await ProgressService().resetProgress();
    final progress = await ProgressService().loadProgress();

    expect(progress.learningStatistics.levels, isEmpty);
  });

  test(
    'damaged stored statistics do not damage the rest of progress',
    () async {
      SharedPreferences.setMockInitialValues({
        'score': 25,
        'learning_statistics': 'not json',
      });

      final progress = await ProgressService().loadProgress();

      expect(progress.score, 25);
      expect(progress.learningStatistics.levels, isEmpty);
    },
  );

  test('learning duration uses a readable parent-friendly format', () {
    expect(formatLearningDuration(0), '0 сек');
    expect(formatLearningDuration(12000), '12 сек');
    expect(formatLearningDuration(65000), '1 мин 5 сек');
    expect(formatLearningDuration(3720000), '1 ч 2 мин');
  });
}
