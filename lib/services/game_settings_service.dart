import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_difficulty.dart';
import '../models/round_settings.dart';

class GameSettingsService {
  static const _difficultyKey = 'game_difficulty';
  static const _roundSettingsKey = 'round_settings';
  static final ValueNotifier<GameDifficulty> difficultyNotifier =
      ValueNotifier<GameDifficulty>(GameDifficulty.beginner);
  static final ValueNotifier<RoundSettings> roundSettingsNotifier =
      ValueNotifier<RoundSettings>(RoundSettings.defaults);

  GameDifficulty get currentDifficulty => difficultyNotifier.value;
  RoundSettings get currentRoundSettings => roundSettingsNotifier.value;

  Future<GameDifficulty> loadDifficulty() async {
    final preferences = await SharedPreferences.getInstance();
    final storedDifficulty = preferences.getString(_difficultyKey);

    for (final difficulty in GameDifficulty.values) {
      if (difficulty.name == storedDifficulty) {
        difficultyNotifier.value = difficulty;
        return difficulty;
      }
    }

    difficultyNotifier.value = GameDifficulty.beginner;
    return GameDifficulty.beginner;
  }

  Future<void> saveDifficulty(GameDifficulty difficulty) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_difficultyKey, difficulty.name);
    difficultyNotifier.value = difficulty;
  }

  Future<RoundSettings> loadRoundSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final storedSettings = preferences.getString(_roundSettingsKey);
    if (storedSettings == null) {
      roundSettingsNotifier.value = RoundSettings.defaults;
      return RoundSettings.defaults;
    }

    try {
      final decodedSettings =
          jsonDecode(storedSettings) as Map<String, Object?>;
      final settings = RoundSettings.fromJson(decodedSettings);
      roundSettingsNotifier.value = settings;
      return settings;
    } on Object {
      roundSettingsNotifier.value = RoundSettings.defaults;
      return RoundSettings.defaults;
    }
  }

  Future<void> saveRoundSettings(RoundSettings settings) async {
    final validatedSettings = settings.validated();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _roundSettingsKey,
      jsonEncode(validatedSettings.toJson()),
    );
    roundSettingsNotifier.value = validatedSettings;
  }
}
