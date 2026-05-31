import 'package:bear_game/game/bear_math_game.dart';
import 'package:bear_game/models/level.dart';
import 'package:bear_game/models/question.dart';
import 'package:bear_game/widgets/mentor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mentor dialog can be closed from the intro', (tester) async {
    var closed = false;
    final game = BearMathGame(levelId: 9)
      ..currentLevel = const Level(
        id: 9,
        title: 'Северное сияние',
        locationName: 'Северное сияние',
        mentorName: 'Песец-мудрец',
        table: 9,
        rewardPoints: 1,
        penaltyPoints: 0,
        introText: 'Здравствуйте!',
        completionText: 'Готово.',
        questions: [
          Question(
            id: 1,
            level: 9,
            table: 9,
            questionText: 'Сколько будет?',
            expression: '9 x 1',
            options: [8, 9, 10],
            correctAnswer: 9,
            hint: 'Девять.',
            rewardPoints: 1,
            penaltyPoints: 0,
          ),
        ],
      );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MentorDialog(
            game: game,
            onClose: () => closed = true,
            onLevelComplete: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Закрыть'));

    expect(closed, isTrue);
  });
}
