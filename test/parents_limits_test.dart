import 'dart:convert';

import 'package:bear_game/models/family_reward.dart';
import 'package:bear_game/screens/parents_screen.dart';
import 'package:bear_game/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reward budget shows one remaining snowflake after 999', (
    tester,
  ) async {
    _ignoreKnownParentsScreenErrors();
    SharedPreferences.setMockInitialValues({
      'family_rewards': jsonEncode([
        const FamilyReward(
          id: 'almost_all',
          title: 'Почти весь бюджет',
          requiredSnowflakes: 999,
          description: FamilyReward.defaultDescription,
          isEnabled: true,
        ).toJson(),
      ]),
    });

    await _pumpParentsScreen(tester);
    await _scrollTo(tester, 'Семейная награда');

    expect(find.text('Распределено: 999 из 1000'), findsOneWidget);
    expect(find.text('Осталась 1 снежинка.'), findsOneWidget);
  });

  testWidgets(
    'reward budget warns immediately when distribution exceeds 1000',
    (tester) async {
      _ignoreKnownParentsScreenErrors();
      SharedPreferences.setMockInitialValues({
        'family_rewards': jsonEncode([
          const FamilyReward(
            id: 'first',
            title: 'Первая награда',
            requiredSnowflakes: 600,
            description: FamilyReward.defaultDescription,
            isEnabled: true,
          ).toJson(),
          const FamilyReward(
            id: 'second',
            title: 'Вторая награда',
            requiredSnowflakes: 400,
            description: FamilyReward.defaultDescription,
            isEnabled: true,
          ).toJson(),
        ]),
      });

      await _pumpParentsScreen(tester);
      await _scrollTo(tester, 'Семейная награда');

      final snowflakeFields = find.widgetWithText(TextFormField, 'Снежинки');
      expect(snowflakeFields, findsNWidgets(2));

      await tester.enterText(snowflakeFields.at(1), '601');
      await tester.pump();

      expect(
        find.textContaining(
          'Распределение наград превышает максимальное количество снежинок',
        ),
        findsOneWidget,
      );
    },
  );
}

void _ignoreKnownParentsScreenErrors() {
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('ListTile background color or ink splashes') ||
        message.contains('A RenderFlex overflowed')) {
      return;
    }

    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);
}

Future<void> _pumpParentsScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.theme, home: const ParentsScreen()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _scrollTo(WidgetTester tester, String text) async {
  await tester.dragUntilVisible(
    find.text(text),
    find.byType(ListView),
    const Offset(0, -300),
  );
  await tester.pump();
}
