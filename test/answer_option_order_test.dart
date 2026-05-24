import 'dart:math' as math;

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
}
