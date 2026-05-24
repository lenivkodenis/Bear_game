import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_difficulty.dart';

class GameSettingsService {
  static const _difficultyKey = 'game_difficulty';

  Future<GameDifficulty> loadDifficulty() async {
    final preferences = await SharedPreferences.getInstance();

    return GameDifficulty.fromStorageValue(
      preferences.getString(_difficultyKey),
    );
  }

  Future<void> saveDifficulty(GameDifficulty difficulty) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_difficultyKey, difficulty.storageValue);
  }
}
