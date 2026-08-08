import 'dart:math' as math;

import 'package:bear_game/models/game_difficulty.dart';
import 'package:bear_game/models/question.dart';
import 'package:bear_game/utils/answer_option_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shuffled options keep exactly three answers including the correct one',
    () {
      const correctAnswer = 25;
      final options = <int>[20, correctAnswer, 30];

      final shuffledOptions = shuffledAnswerOptions(
        options,
        random: math.Random(1),
      );

      expect(shuffledOptions, hasLength(3));
      expect(shuffledOptions, contains(correctAnswer));
      expect(shuffledOptions.toSet(), options.toSet());
    },
  );

  test('shuffled options do not mutate source level data', () {
    final options = <int>[12, 15, 18];

    shuffledAnswerOptions(options, random: math.Random(2));

    expect(options, <int>[12, 15, 18]);
  });

  test(
    'correct answer can appear in different positions with seeded random',
    () {
      const correctAnswer = 25;
      final positions = <int>{};

      for (var seed = 0; seed < 20; seed += 1) {
        final shuffledOptions = shuffledAnswerOptions(const <int>[
          20,
          correctAnswer,
          30,
        ], random: math.Random(seed));
        positions.add(shuffledOptions.indexOf(correctAnswer));
      }

      expect(positions.length, greaterThan(1));
    },
  );

  test('beginner difficulty uses exactly three shuffled options', () {
    final options = answerOptionsForDifficulty(
      _question,
      GameDifficulty.beginner,
      random: math.Random(1),
    );

    expect(options, hasLength(3));
    expect(options, contains(_question.correctAnswer));
    expect(options.toSet(), hasLength(3));
  });

  test('training difficulty uses five close shuffled options', () {
    final options = answerOptionsForDifficulty(
      _question,
      GameDifficulty.training,
      random: math.Random(2),
    );

    expect(options, hasLength(5));
    expect(options, contains(_question.correctAnswer));
    expect(options.toSet(), hasLength(5));
    expect(
      options.where((option) => option != _question.correctAnswer),
      everyElement(
        predicate<int>(
          (option) => (option - _question.correctAnswer).abs() <= 6,
          'close to the correct answer',
        ),
      ),
    );
  });

  test('expert difficulty uses manual input without answer options', () {
    final options = answerOptionsForDifficulty(
      _question,
      GameDifficulty.expert,
    );

    expect(options, isEmpty);
    expect(usesManualAnswerInput(GameDifficulty.expert), isTrue);
  });

  test('training hint explains logic without naming the answer', () {
    final hint = answerHintForDifficulty(_question, GameDifficulty.training);

    expect(hint, isNot(contains(_question.correctAnswer.toString())));
    expect(hint, isNotEmpty);
  });

  test('expert difficulty disables hints', () {
    expect(hintsEnabledForDifficulty(GameDifficulty.expert), isFalse);
    expect(answerHintForDifficulty(_question, GameDifficulty.expert), isEmpty);
  });
}

const _question = Question(
  id: 1,
  level: 3,
  table: 3,
  questionText: 'Сколько будет?',
  expression: '3 x 4',
  options: [10, 12, 15],
  correctAnswer: 12,
  hint: 'Три раза по четыре дают двенадцать.',
  rewardPoints: 1,
  penaltyPoints: 0,
);
