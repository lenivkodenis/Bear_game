import 'dart:convert';

import 'package:bear_game/game/bear_math_game.dart';
import 'package:bear_game/models/game_difficulty.dart';
import 'package:bear_game/models/question_answer_result.dart';
import 'package:bear_game/models/round_settings.dart';
import 'package:bear_game/services/game_economy.dart';
import 'package:bear_game/services/progress_service.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('correct answer adds 1 snowflake', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;

    final result = await game.submitAnswer(question.correctAnswer);

    expect(result.isCorrect, isTrue);
    expect(result.score, GameEconomy.correctAnswerSnowflakes);
    expect(game.scoreNotifier.value, GameEconomy.correctAnswerSnowflakes);
    expect(game.levelSnowflakes, GameEconomy.correctAnswerSnowflakes);
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
    expect(result.score, GameEconomy.correctAnswerSnowflakes);
  });

  test('wrong answer subtracts 2 snowflakes', () async {
    SharedPreferences.setMockInitialValues({'score': 10});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final wrongAnswer = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );

    final result = await game.submitAnswer(wrongAnswer);

    expect(result.isCorrect, isFalse);
    expect(result.requiresRestart, isFalse);
    expect(result.score, 8);
    expect(game.scoreNotifier.value, 8);
  });

  test('game records time and mistakes for each question', () async {
    SharedPreferences.setMockInitialValues({'score': 10});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final wrongAnswer = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );

    game.startQuestionTimer();
    await Future<void>.delayed(const Duration(milliseconds: 15));
    await game.submitAnswer(wrongAnswer);
    await Future<void>.delayed(const Duration(milliseconds: 15));
    await game.submitAnswer(question.correctAnswer);

    final progress = await ProgressService().loadProgress();
    final statistics = progress.learningStatistics.forLevel(1)!;
    final questionStatistics = statistics.questions[question.id]!;

    expect(questionStatistics.wrongAnswers, 1);
    expect(questionStatistics.correctAnswers, 1);
    expect(questionStatistics.attempts, 2);
    expect(questionStatistics.elapsedMilliseconds, greaterThan(0));
    expect(statistics.accuracyPercent, 50);
  });

  test('wrong answer with balance below 2 requires restart', () async {
    SharedPreferences.setMockInitialValues({'score': 1});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final wrongAnswer = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );

    final result = await game.submitAnswer(wrongAnswer);

    expect(result.isCorrect, isFalse);
    expect(result.requiresRestart, isTrue);
    expect(
      result.restartRequiredReason,
      RestartRequiredReason.notEnoughSnowflakes,
    );
    expect(result.score, 1);
    expect(game.scoreNotifier.value, 1);
  });

  test('too many mistakes in a round require restart', () async {
    SharedPreferences.setMockInitialValues({
      'score': 10,
      'round_settings': jsonEncode(
        const RoundSettings(
          roundQuestionCount: 10,
          maxMistakesPerRound: 0,
          wrongAnswerPenalty: 2,
        ).toJson(),
      ),
    });
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final wrongAnswer = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );

    final result = await game.submitAnswer(wrongAnswer);

    expect(result.isCorrect, isFalse);
    expect(result.requiresRestart, isTrue);
    expect(result.restartRequiredReason, RestartRequiredReason.tooManyMistakes);
    expect(result.score, 10);
    expect(game.scoreNotifier.value, 10);
  });

  test('score cannot become less than 0', () async {
    SharedPreferences.setMockInitialValues({'score': 2});
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;
    final wrongAnswer = question.options.firstWhere(
      (option) => option != question.correctAnswer,
    );

    final result = await game.submitAnswer(wrongAnswer);

    expect(result.score, 0);
    expect(game.scoreNotifier.value, 0);
  });

  test('score cannot become greater than 1000', () async {
    SharedPreferences.setMockInitialValues({
      'score': GameEconomy.maxTotalSnowflakes,
    });
    final game = await _loadGame(levelId: 1);
    final question = game.currentQuestion!;

    final result = await game.submitAnswer(question.correctAnswer);

    expect(result.score, GameEconomy.maxTotalSnowflakes);
    expect(game.scoreNotifier.value, GameEconomy.maxTotalSnowflakes);
    expect(game.levelSnowflakes, 0);
  });

  test('ten correct answers award maximum 10 level snowflakes', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await _loadGame(levelId: 1);

    while (game.currentQuestion != null) {
      await game.submitAnswer(game.currentQuestion!.correctAnswer);
    }

    expect(game.scoreNotifier.value, GameEconomy.maxSnowflakesPerLevel);
    expect(game.levelSnowflakes, GameEconomy.maxSnowflakesPerLevel);
  });

  test('game loads saved difficulty from settings', () async {
    SharedPreferences.setMockInitialValues({
      'game_difficulty': GameDifficulty.training.name,
    });

    final game = await _loadGame(levelId: 1);

    expect(game.difficulty, GameDifficulty.training);
  });

  test('beginner difficulty provides three answer options', () async {
    SharedPreferences.setMockInitialValues({
      'game_difficulty': GameDifficulty.beginner.name,
    });

    final game = await _loadGame(levelId: 1);

    expect(game.currentAnswerOptions, hasLength(3));
    expect(
      game.currentAnswerOptions,
      contains(game.currentQuestion!.correctAnswer),
    );
  });

  test('training difficulty provides five answer options', () async {
    SharedPreferences.setMockInitialValues({
      'game_difficulty': GameDifficulty.training.name,
    });

    final game = await _loadGame(levelId: 1);

    expect(game.currentAnswerOptions, hasLength(5));
    expect(game.currentAnswerOptions.toSet(), hasLength(5));
    expect(
      game.currentAnswerOptions,
      contains(game.currentQuestion!.correctAnswer),
    );
  });

  test('expert difficulty switches to manual input without options', () async {
    SharedPreferences.setMockInitialValues({
      'game_difficulty': GameDifficulty.expert.name,
    });

    final game = await _loadGame(levelId: 1);

    expect(game.isManualAnswerMode, isTrue);
    expect(game.currentAnswerOptions, isEmpty);
  });

  test('expert difficulty disables hints on wrong answers', () async {
    SharedPreferences.setMockInitialValues({
      'score': 10,
      'game_difficulty': GameDifficulty.expert.name,
    });
    final game = await _loadGame(levelId: 1);

    final result = await game.submitAnswer(999);

    expect(result.isCorrect, isFalse);
    expect(result.message, isNot(contains('Подсказка')));
    expect(result.message, isNot(contains(game.currentQuestion!.hint)));
  });

  test('reaching the mentor opens the question dialog', () async {
    SharedPreferences.setMockInitialValues({});
    final game = await _loadGame(levelId: 1);

    expect(
      game.sceneReadyNotifier.value,
      isFalse,
      reason: 'controls wait for the first rendered scene frame',
    );
    game.overlays.addEntry(
      BearMathGame.mentorDialogOverlay,
      (_, _) => const SizedBox.shrink(),
    );
    game.player.position = game.mentor.interactionPoint - game.player.size / 2;
    game.update(0);

    expect(game.mentorDialogOpenNotifier.value, isTrue);
    expect(game.overlays.isActive(BearMathGame.mentorDialogOverlay), isTrue);
  });
}

Future<BearMathGame> _loadGame({required int levelId}) async {
  final game = BearMathGame(levelId: levelId);
  game.onGameResize(Vector2(800, 600));
  await game.onLoad();

  return game;
}
