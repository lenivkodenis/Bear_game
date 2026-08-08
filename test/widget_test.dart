import 'package:bear_game/app.dart';
import 'package:bear_game/widgets/game_controls.dart';
import 'package:flutter/material.dart';
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

  testWidgets('game movement controls react on pointer down', (tester) async {
    var rightStartCount = 0;
    var moveEndCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameControls(
            onMoveLeftStart: () {},
            onMoveRightStart: () {
              rightStartCount += 1;
            },
            onMoveEnd: () {
              moveEndCount += 1;
            },
            onJump: () {},
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('›')));
    await tester.pump();

    expect(rightStartCount, 1);
    expect(moveEndCount, 0);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 121));

    expect(moveEndCount, 1);
  });
}
