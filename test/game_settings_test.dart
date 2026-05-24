import 'package:bear_game/models/game_difficulty.dart';
import 'package:bear_game/services/game_settings_service.dart';
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
  });

  test('selected difficulty loads after reopening the service', () async {
    SharedPreferences.setMockInitialValues({});

    await GameSettingsService().saveDifficulty(GameDifficulty.expert);

    expect(await GameSettingsService().loadDifficulty(), GameDifficulty.expert);
  });

  test('all three difficulty modes exist with readable titles', () {
    expect(GameDifficulty.values, hasLength(3));
    expect(
      GameDifficulty.values.map((difficulty) => difficulty.title),
      containsAll(<String>['Я учусь', 'Я тренируюсь', 'Я знаю']),
    );
  });
}
