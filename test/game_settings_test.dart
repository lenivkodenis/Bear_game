import 'package:bear_game/screens/parents_screen.dart';
import 'package:bear_game/models/game_difficulty.dart';
import 'package:bear_game/models/round_settings.dart';
import 'package:bear_game/services/game_settings_service.dart';
import 'package:bear_game/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default difficulty is beginner', () async {
    SharedPreferences.setMockInitialValues({});

    final difficulty = await GameSettingsService().loadDifficulty();

    expect(difficulty, GameDifficulty.beginner);
    expect(difficulty.title, 'Я учусь');
  });

  test('selected difficulty is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final settingsService = GameSettingsService();

    await settingsService.saveDifficulty(GameDifficulty.training);

    expect(await settingsService.loadDifficulty(), GameDifficulty.training);
    expect(await settingsService.isDifficultyResetRequired(), isTrue);
  });

  test('selected difficulty loads after reopening the service', () async {
    SharedPreferences.setMockInitialValues({});

    await GameSettingsService().saveDifficulty(GameDifficulty.expert);

    expect(await GameSettingsService().loadDifficulty(), GameDifficulty.expert);
  });

  test(
    'confirmed difficulty reset becomes the new progress baseline',
    () async {
      SharedPreferences.setMockInitialValues({
        'game_difficulty': GameDifficulty.beginner.name,
      });
      final settingsService = GameSettingsService();

      await settingsService.saveDifficulty(GameDifficulty.expert);
      expect(await settingsService.isDifficultyResetRequired(), isTrue);

      await settingsService.confirmProgressResetForCurrentDifficulty();
      expect(await settingsService.isDifficultyResetRequired(), isFalse);

      await settingsService.saveDifficulty(GameDifficulty.training);
      expect(await settingsService.isDifficultyResetRequired(), isTrue);
    },
  );

  test(
    'returning to the progress difficulty cancels the required reset',
    () async {
      SharedPreferences.setMockInitialValues({
        'game_difficulty': GameDifficulty.beginner.name,
      });
      final settingsService = GameSettingsService();

      await settingsService.saveDifficulty(GameDifficulty.expert);
      await settingsService.saveDifficulty(GameDifficulty.beginner);

      expect(await settingsService.isDifficultyResetRequired(), isFalse);
    },
  );

  test('legacy non-beginner progress requires a one-time reset', () async {
    SharedPreferences.setMockInitialValues({
      'game_difficulty': GameDifficulty.expert.name,
      'unlocked_location': 8,
      'completed_level_ids': ['1', '2', '3', '4', '5', '6', '7'],
    });
    final settingsService = GameSettingsService();

    expect(await settingsService.isDifficultyResetRequired(), isTrue);

    await settingsService.confirmProgressResetForCurrentDifficulty();
    expect(await settingsService.isDifficultyResetRequired(), isFalse);
  });

  test('default round settings are created correctly', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = await GameSettingsService().loadRoundSettings();

    expect(settings.roundQuestionCount, 10);
    expect(settings.maxMistakesPerRound, 2);
    expect(settings.wrongAnswerPenalty, 2);
  });

  test(
    'round settings are saved and loaded with fixed question count',
    () async {
      SharedPreferences.setMockInitialValues({});
      final settingsService = GameSettingsService();
      const settings = RoundSettings(
        roundQuestionCount: 8,
        maxMistakesPerRound: 1,
        wrongAnswerPenalty: 2,
      );

      await settingsService.saveRoundSettings(settings);

      final loadedSettings = await settingsService.loadRoundSettings();

      expect(loadedSettings.roundQuestionCount, 10);
      expect(loadedSettings.maxMistakesPerRound, 1);
      expect(loadedSettings.wrongAnswerPenalty, 2);
      expect(await settingsService.isDifficultyResetRequired(), isFalse);
    },
  );

  test('all three difficulty modes exist with readable titles', () {
    expect(GameDifficulty.values, hasLength(3));
    expect(
      GameDifficulty.values.map((difficulty) => difficulty.title),
      containsAll(<String>['Я учусь', 'Я тренируюсь', 'Я знаю']),
    );
  });

  testWidgets('settings screen saves difficulty only after save button', (
    tester,
  ) async {
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

    SharedPreferences.setMockInitialValues({
      'game_difficulty': GameDifficulty.training.name,
    });

    await _pumpParentsScreen(tester);

    await tester.dragUntilVisible(
      find.text('Я знаю'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.tap(find.text('Я знаю'));
    await tester.pump();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString('game_difficulty'),
      GameDifficulty.training.name,
    );

    await tester.dragUntilVisible(
      find.text('Сохранить настройки'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.pump();
    await tester.tap(find.text('Сохранить настройки'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      preferences.getString('game_difficulty'),
      GameDifficulty.expert.name,
    );
    expect(GameSettingsService().currentDifficulty, GameDifficulty.expert);

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpParentsScreen(tester);
    await tester.dragUntilVisible(
      find.text('Я знаю'),
      find.byType(ListView),
      const Offset(0, -100),
    );
    await tester.pump();

    final expertTile = tester.widget<RadioListTile<GameDifficulty>>(
      find.widgetWithText(RadioListTile<GameDifficulty>, 'Я знаю'),
    );
    expect(expertTile.selected, isTrue);
  });
}

Future<void> _pumpParentsScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.theme, home: const ParentsScreen()),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
