import 'dart:math' as math;

import '../models/game_difficulty.dart';
import '../models/question.dart';

List<int> shuffledAnswerOptions(List<int> options, {math.Random? random}) {
  final shuffledOptions = List<int>.of(options);
  shuffledOptions.shuffle(random);
  return shuffledOptions;
}

List<int> answerOptionsForDifficulty(
  Question question,
  GameDifficulty difficulty, {
  math.Random? random,
}) {
  return switch (difficulty) {
    GameDifficulty.beginner => _beginnerOptions(question, random: random),
    GameDifficulty.training => _trainingOptions(question, random: random),
    GameDifficulty.expert => const <int>[],
  };
}

bool usesManualAnswerInput(GameDifficulty difficulty) {
  return difficulty == GameDifficulty.expert;
}

bool hintsEnabledForDifficulty(GameDifficulty difficulty) {
  return difficulty != GameDifficulty.expert;
}

String answerHintForDifficulty(Question question, GameDifficulty difficulty) {
  return switch (difficulty) {
    GameDifficulty.beginner => question.hint,
    GameDifficulty.training =>
      'Разложи пример на одинаковые группы и считай их по шагам. '
          'Проверь ход решения, а не угадывай по вариантам.',
    GameDifficulty.expert => '',
  };
}

List<int> _beginnerOptions(Question question, {math.Random? random}) {
  final options = _uniqueOptions(question.options, question.correctAnswer);
  _fillNearbyOptions(options, question, targetLength: 3);

  return shuffledAnswerOptions(options.take(3).toList(), random: random);
}

List<int> _trainingOptions(Question question, {math.Random? random}) {
  final options = <int>[question.correctAnswer];
  _fillNearbyOptions(options, question, targetLength: 5);

  return shuffledAnswerOptions(options, random: random);
}

List<int> _uniqueOptions(List<int> sourceOptions, int correctAnswer) {
  final options = <int>[];
  for (final option in [correctAnswer, ...sourceOptions]) {
    if (!options.contains(option)) {
      options.add(option);
    }
  }

  return options;
}

void _fillNearbyOptions(
  List<int> options,
  Question question, {
  required int targetLength,
}) {
  final correctAnswer = question.correctAnswer;
  final factors = _factorsFromExpression(question.expression);
  final table = question.table;
  final nearbyOffsets = <int>[
    1,
    -1,
    2,
    -2,
    table,
    -table,
    factors.$1,
    -factors.$1,
    factors.$2,
    -factors.$2,
    table + 1,
    -(table + 1),
  ];

  final candidates = <int>{};
  for (final offset in nearbyOffsets) {
    if (offset == 0) {
      continue;
    }

    final candidate = correctAnswer + offset;
    if (candidate > 0 && candidate != correctAnswer) {
      candidates.add(candidate);
    }
  }

  var radius = 3;
  while (candidates.length < targetLength * 2) {
    candidates
      ..add(correctAnswer + radius)
      ..add(math.max(1, correctAnswer - radius));
    radius += 1;
  }

  final sortedCandidates = candidates.toList()
    ..sort(
      (left, right) =>
          (left - correctAnswer).abs().compareTo((right - correctAnswer).abs()),
    );

  for (final candidate in sortedCandidates) {
    if (options.length >= targetLength) {
      return;
    }

    if (!options.contains(candidate)) {
      options.add(candidate);
    }
  }
}

(int, int) _factorsFromExpression(String expression) {
  final factors = RegExp(
    r'\d+',
  ).allMatches(expression).map((match) => int.parse(match.group(0)!)).toList();

  if (factors.length >= 2) {
    return (factors[0], factors[1]);
  }

  return (1, 1);
}
