import 'package:bear_game/app.dart';
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
}
