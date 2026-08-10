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
            onReturnToMap: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Закрыть'));

    expect(closed, isTrue);
  });

  for (final viewport in const <Size>[
    Size(1280, 800),
    Size(390, 844),
    Size(762, 248),
    Size(848, 340),
    Size(667, 375),
  ]) {
    testWidgets('long story fits the ${viewport.width.toInt()}px viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final game = BearMathGame(levelId: 2)
        ..currentLevel = const Level(
          id: 2,
          title: 'Ледяная река',
          locationName: 'Ледяная река',
          mentorName: 'Выдра-мудрец',
          table: 2,
          rewardPoints: 1,
          penaltyPoints: 0,
          introText: 'Начнём?',
          completionText: 'Готово.',
          questions: [
            Question(
              id: 5,
              level: 2,
              table: 2,
              questionText:
                  'В школьной администрации готовят карточки для учеников. '
                  'В кабинете стоят два принтера. Они напечатали по пять '
                  'карточек. Сколько карточек они напечатали?',
              expression: '2 x 5',
              options: [8, 10, 12],
              correctAnswer: 10,
              hint: 'Два принтера напечатали по пять карточек: 2 × 5 = 10.',
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
              onClose: () {},
              onLevelComplete: () {},
              onReturnToMap: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('К задаче'));
      await tester.pump();

      expect(find.textContaining('В школьной администрации'), findsOneWidget);
      expect(find.text('2 x 5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('open question survives rotation without returning to intro', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final game = BearMathGame(levelId: 1)
      ..currentLevel = const Level(
        id: 1,
        title: 'Льдина',
        locationName: 'Льдина',
        mentorName: 'Чайка-мудрец',
        table: 1,
        rewardPoints: 1,
        penaltyPoints: 0,
        introText: 'Начнём?',
        completionText: 'Готово.',
        questions: [
          Question(
            id: 1,
            level: 1,
            table: 1,
            questionText: 'Сколько будет?',
            expression: '1 x 4',
            options: [3, 4, 5],
            correctAnswer: 4,
            hint: 'Один раз по четыре.',
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
            onClose: () {},
            onLevelComplete: () {},
            onReturnToMap: () {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('К задаче'));
    await tester.pump();
    await tester.binding.setSurfaceSize(const Size(762, 248));
    await tester.pump();

    expect(find.text('1 x 4'), findsOneWidget);
    expect(find.text('К задаче'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
