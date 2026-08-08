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
