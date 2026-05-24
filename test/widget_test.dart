import 'dart:math';

import 'package:bear_game/app.dart';
import 'package:bear_game/models/game_difficulty.dart';
import 'package:bear_game/models/question.dart';
import 'package:bear_game/services/answer_options_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('main menu shows primary actions', (tester) async {
    await tester.pumpWidget(const BearGameApp());

    expect(find.text('Медвежонок и таблица умножения'), findsOneWidget);
    expect(find.text('Начать игру'), findsOneWidget);
    expect(find.text('Карта'), findsOneWidget);
    expect(find.text('Прогресс'), findsOneWidget);
    expect(find.text('Родителям'), findsOneWidget);
  });

  group('difficulty answer modes', () {
    test('beginner returns 3 shuffled options with the correct answer', () {
      final service = AnswerOptionsService(random: Random(1));

      final options = service.optionsFor(
        _question(),
        GameDifficulty.beginner,
      );

      expect(options, hasLength(3));
      expect(options, contains(25));
    });

    test('training returns 5 unique options with the correct answer', () {
      final service = AnswerOptionsService(random: Random(2));

      final options = service.optionsFor(
        _question(),
        GameDifficulty.training,
      );

      expect(options, hasLength(5));
      expect(options.toSet(), hasLength(5));
      expect(options, contains(25));
    });

    test('expert does not return choice options', () {
      final service = AnswerOptionsService(random: Random(3));

      final options = service.optionsFor(_question(), GameDifficulty.expert);

      expect(options, isEmpty);
    });

    test('correct answer position is not fixed', () {
      final positions = <int>{};

      for (var seed = 0; seed < 20; seed++) {
        final service = AnswerOptionsService(random: Random(seed));
        final options = service.optionsFor(
          _question(),
          GameDifficulty.training,
        );
        positions.add(options.indexOf(25));
      }

      expect(positions.length, greaterThan(1));
    });

    test('training hint does not reveal the correct answer directly', () {
      final service = AnswerOptionsService(random: Random(4));

      final hint = service.hintFor(_question(), GameDifficulty.training);

      expect(hint, isNot(contains('25')));
      expect(hint.toLowerCase(), isNot(contains('ответ: 25')));
    });

    test('expert numeric input accepts only the right value', () {
      final service = AnswerOptionsService(random: Random(5));

      expect(service.isCorrectNumericInput('25', 25), isTrue);
      expect(service.isCorrectNumericInput(' 25 ', 25), isTrue);
      expect(service.isCorrectNumericInput('24', 25), isFalse);
      expect(service.isCorrectNumericInput('', 25), isFalse);
    });

    test('snowflake rewards keep first try and retry economy', () {
      final service = AnswerOptionsService(random: Random(6));

      expect(service.rewardForCorrectAnswer(isFirstAttempt: true), 5);
      expect(service.rewardForCorrectAnswer(isFirstAttempt: false), 3);
    });
  });
}

Question _question() {
  return const Question(
    id: 1,
    level: 5,
    table: 5,
    questionText: 'На каждой льдине по 5 снежинок. Льдин 5.',
    expression: '5 x 5',
    options: [20, 25, 30],
    correctAnswer: 25,
    hint: '5 x 5 — это пять раз по пять: 5 + 5 + 5 + 5 + 5 = 25.',
    rewardPoints: 10,
    penaltyPoints: 3,
  );
}
