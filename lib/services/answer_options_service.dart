import 'dart:math';

import '../models/game_difficulty.dart';
import '../models/question.dart';

class AnswerOptionsService {
  AnswerOptionsService({Random? random}) : _random = random ?? Random();

  static const firstTryReward = 5;
  static const retryReward = 3;
  static const expertRetryMessage = 'Почти. Попробуй ещё раз.';

  final Random _random;

  List<int> optionsFor(Question question, GameDifficulty difficulty) {
    return switch (difficulty) {
      GameDifficulty.beginner => _beginnerOptions(question),
      GameDifficulty.training => _trainingOptions(question),
      GameDifficulty.expert => const <int>[],
    };
  }

  String hintFor(Question question, GameDifficulty difficulty) {
    return switch (difficulty) {
      GameDifficulty.beginner => question.hint,
      GameDifficulty.training =>
        'Попробуй представить пример как несколько одинаковых групп и посчитать их по очереди.',
      GameDifficulty.expert => '',
    };
  }

  bool isCorrectNumericInput(String input, int correctAnswer) {
    return int.tryParse(input.trim()) == correctAnswer;
  }

  int rewardForCorrectAnswer({required bool isFirstAttempt}) {
    return isFirstAttempt ? firstTryReward : retryReward;
  }

  List<int> _beginnerOptions(Question question) {
    final options = <int>{question.correctAnswer, ...question.options}
        .where((option) => option > 0)
        .toList();

    var candidate = question.correctAnswer + 1;
    while (options.length < 3) {
      if (candidate > 0 && !options.contains(candidate)) {
        options.add(candidate);
      }
      candidate++;
    }

    return (options.take(3).toList()..shuffle(_random));
  }

  List<int> _trainingOptions(Question question) {
    final correctAnswer = question.correctAnswer;
    final options = <int>{correctAnswer};

    for (final candidate in [
      correctAnswer - question.table,
      correctAnswer + question.table,
      correctAnswer + question.table * 2,
      correctAnswer - question.table * 2,
      correctAnswer - 1,
      correctAnswer + 1,
    ]) {
      if (candidate > 0 && options.length < 4) {
        options.add(candidate);
      }
    }

    while (options.length < 5) {
      final spread = correctAnswer + question.table + 12;
      final upperBound = spread.clamp(5, 120).toInt();
      final candidate = 1 + _random.nextInt(upperBound);
      options.add(candidate);
    }

    return options.toList()..shuffle(_random);
  }
}
