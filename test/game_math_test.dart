import 'package:bear_game/game/bear_math_game.dart';
import 'package:bear_game/services/game_economy.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('correct answer on first attempt awards 5 snowflakes', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;

    final result = await game.submitAnswer(question.correctAnswer);

    expect(result.isCorrect, isTrue);
    expect(result.score, GameEconomy.firstAttemptSnowflakes);
    expect(game.scoreNotifier.value, GameEconomy.firstAttemptSnowflakes);
    expect(game.levelSnowflakes, GameEconomy.firstAttemptSnowflakes);
  });

  test('answer correctness is checked by value, not option index', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final reorderedOptions = [
      ...question.options.where((option) => option != question.correctAnswer),
      question.correctAnswer,
    ];

    expect(reorderedOptions.last, question.correctAnswer);

    final result = await game.submitAnswer(reorderedOptions.last);

    expect(result.isCorrect, isTrue);
    expect(result.score, GameEconomy.firstAttemptSnowflakes);
  });

  test('correct answer after a wrong attempt awards 3 snowflakes', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final wrongAnswer = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );

    final wrongResult = await game.submitAnswer(wrongAnswer);
    final correctResult = await game.submitAnswer(question.correctAnswer);

    expect(wrongResult.isCorrect, isFalse);
    expect(wrongResult.score, 0);
    expect(correctResult.isCorrect, isTrue);
    expect(correctResult.score, GameEconomy.afterHintSnowflakes);
    expect(game.scoreNotifier.value, GameEconomy.afterHintSnowflakes);
    expect(game.levelSnowflakes, GameEconomy.afterHintSnowflakes);
  });

  test('wrong answer does not reduce snowflakes', () async {
    SharedPreferences.setMockInitialValues({'score': 10});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final wrongAnswer = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );

    final result = await game.submitAnswer(wrongAnswer);

    expect(result.isCorrect, isFalse);
    expect(result.score, 10);
    expect(game.scoreNotifier.value, 10);
  });

  test('wrong answer never makes snowflakes negative', () async {
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

  test(
    'ten first-attempt correct answers award maximum 50 snowflakes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = await _loadGame(levelId: 1);

      while (game.currentQuestion != null) {
        await game.submitAnswer(game.currentQuestion!.correctAnswer);
      }

      expect(game.scoreNotifier.value, GameEconomy.maxSnowflakesPerLevel);
      expect(game.levelSnowflakes, GameEconomy.maxSnowflakesPerLevel);
    },
  );

  test(
    'wrong-attempt state resets after moving to the next question',
    () async {
      SharedPreferences.setMockInitialValues({});
      final game = await _loadGame(levelId: 1);
      final firstQuestion = game.currentQuestion!;
      final wrongAnswer = firstQuestion.options.firstWhere(
        (option) => option != firstQuestion.correctAnswer,
      );

      await game.submitAnswer(wrongAnswer);
      await game.submitAnswer(firstQuestion.correctAnswer);
      final secondQuestion = game.currentQuestion!;
      final secondResult = await game.submitAnswer(
        secondQuestion.correctAnswer,
      );

      expect(secondResult.isCorrect, isTrue);
      expect(
        secondResult.score,
        GameEconomy.afterHintSnowflakes + GameEconomy.firstAttemptSnowflakes,
      );
      expect(
        game.levelSnowflakes,
        GameEconomy.afterHintSnowflakes + GameEconomy.firstAttemptSnowflakes,
      );
    },
  );
}

Future<BearMathGame> _loadGame({required int levelId}) async {
  final game = BearMathGame(levelId: levelId);
  game.onGameResize(Vector2(800, 600));
  await game.onLoad();

  return game;
}
