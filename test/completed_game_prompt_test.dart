import 'package:bear_game/widgets/completed_game_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('declining a level replay offers a full game restart', (
    tester,
  ) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompletedGamePrompt(
            mentorName: 'Рысь-мудрец',
            locationName: 'Северный лес',
            onReplayLevel: () async {},
            onRestartGame: () async {},
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    expect(find.text('Игра уже пройдена!'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Нет'));
    await tester.pump();

    expect(find.text('Начать всё путешествие заново?'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Нет, остаться здесь'),
    );

    expect(closed, isTrue);
  });

  testWidgets('both confirmations call the matching action', (tester) async {
    var replayed = false;
    var restarted = false;

    Widget buildPrompt() {
      return MaterialApp(
        home: Scaffold(
          body: CompletedGamePrompt(
            mentorName: 'Морж-мудрец',
            locationName: 'Льдина',
            onReplayLevel: () async {
              replayed = true;
            },
            onRestartGame: () async {
              restarted = true;
            },
            onClose: () {},
          ),
        ),
      );
    }

    await tester.pumpWidget(buildPrompt());
    await tester.tap(find.text('Да, решить ещё раз'));
    await tester.pump();
    expect(replayed, isTrue);

    await tester.pumpWidget(buildPrompt());
    await tester.tap(find.widgetWithText(OutlinedButton, 'Нет'));
    await tester.pump();
    await tester.tap(find.text('Да, начать заново'));
    await tester.pump();
    expect(restarted, isTrue);
  });
}
