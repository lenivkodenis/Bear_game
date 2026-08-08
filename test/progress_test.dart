import 'package:bear_game/game/bear_math_game.dart';
import 'package:bear_game/models/question_answer_result.dart';
import 'package:bear_game/services/progress_service.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first level is available from the start', () async {
    SharedPreferences.setMockInitialValues({});

    final progress = await ProgressService().loadProgress();

    expect(progress.unlockedLocation, 1);
    expect(progress.isLevelCompleted(1), isFalse);
  });

  test('completing level N unlocks level N + 1', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await _loadGame(levelId: 1);

    await _completeCurrentLevel(game);

    final progress = await ProgressService().loadProgress();
    expect(progress.completedLevelIds, contains(1));
    expect(progress.isLevelCompleted(1), isTrue);
    expect(progress.questionIndexForLevel(1), 10);
    expect(progress.unlockedLocation, 2);
  });

  test('completing level 10 produces the final progress state', () async {
    SharedPreferences.setMockInitialValues({'unlocked_location': 10});
    final game = await _loadGame(levelId: 10);

    final result = await _completeCurrentLevel(game);

    final progress = await ProgressService().loadProgress();
    expect(result.isLevelComplete, isTrue);
    expect(progress.isLevelCompleted(10), isTrue);
    expect(progress.questionIndexForLevel(10), 10);
    expect(progress.unlockedLocation, 11);
  });

  test(
    'rewinding to a level closes later levels and restarts the target',
    () async {
      SharedPreferences.setMockInitialValues({
        'score': 47,
        'solved_examples': 73,
        'unlocked_location': 8,
        'current_question_indexes':
            '{"1":10,"2":10,"3":10,"4":10,"5":10,"6":10,"7":10,"8":4}',
        'completed_level_ids': ['1', '2', '3', '4', '5', '6', '7'],
      });

      final progress = await ProgressService().rewindToLevel(6);

      expect(progress.unlockedLocation, 6);
      expect(progress.completedLevelIds, {1, 2, 3, 4, 5});
      expect(progress.currentQuestionIndexes.keys, {1, 2, 3, 4, 5});
      expect(progress.questionIndexForLevel(6), 0);
      expect(progress.score, 47);
      expect(progress.solvedExamples, 73);

      final reloaded = await ProgressService().loadProgress();
      expect(reloaded.unlockedLocation, 6);
      expect(reloaded.completedLevelIds, {1, 2, 3, 4, 5});
    },
  );

  test('rewinding rejects locations outside the game map', () async {
    SharedPreferences.setMockInitialValues({});

    expect(ProgressService().rewindToLevel(11), throwsArgumentError);
  });
}

Future<BearMathGame> _loadGame({required int levelId}) async {
  final game = BearMathGame(levelId: levelId);
  game.onGameResize(Vector2(800, 600));
  await game.onLoad();

  return game;
}

Future<QuestionAnswerResult> _completeCurrentLevel(BearMathGame game) async {
  QuestionAnswerResult? latestResult;
  while (game.currentQuestion != null) {
    latestResult = await game.submitAnswer(game.currentQuestion!.correctAnswer);
  }

  return latestResult!;
}
