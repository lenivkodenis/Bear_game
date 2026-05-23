import 'package:bear_game/game/bear_math_game.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('correct answer awards points', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;

    final result = await game.submitAnswer(question.correctAnswer);

    expect(result.isCorrect, isTrue);
    expect(result.score, question.rewardPoints);
    expect(game.scoreNotifier.value, question.rewardPoints);
  });

  test('wrong answer applies penalty', () async {
    SharedPreferences.setMockInitialValues({'score': 10});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final wrongAnswer = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );

    final result = await game.submitAnswer(wrongAnswer);

    expect(result.isCorrect, isFalse);
    expect(result.score, 10 - question.penaltyPoints);
    expect(game.scoreNotifier.value, 10 - question.penaltyPoints);
  });

  test('wrong answer never makes score negative', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final wrongAnswer = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );

    final result = await game.submitAnswer(wrongAnswer);

    expect(result.isCorrect, isFalse);
    expect(result.score, 0);
    expect(game.scoreNotifier.value, 0);
  });
}

Future<BearMathGame> _loadGame({required int levelId}) async {
  final game = BearMathGame(levelId: levelId);
  game.onGameResize(Vector2(800, 600));
  await game.onLoad();

  return game;
}
