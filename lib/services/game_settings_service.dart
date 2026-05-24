import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_difficulty.dart';

class GameSettingsService {
  static const _difficultyKey = 'game_difficulty';

  Future<GameDifficulty> loadDifficulty() async {
    final preferences = await SharedPreferences.getInstance();
    final storedDifficulty = preferences.getString(_difficultyKey);

    for (final difficulty in GameDifficulty.values) {
      if (difficulty.name == storedDifficulty) {
        return difficulty;
      }
    }

    return GameDifficulty.beginner;
  }

  Future<void> saveDifficulty(GameDifficulty difficulty) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_difficultyKey, difficulty.name);
  }
}
