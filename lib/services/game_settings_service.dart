import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_difficulty.dart';
import '../models/round_settings.dart';

class GameSettingsService {
  static const _difficultyKey = 'game_difficulty';
  static const _progressDifficultyKey = 'progress_difficulty';
  static const _difficultyResetRequiredKey =
      'difficulty_progress_reset_required';
  static const _roundSettingsKey = 'round_settings';
  static const _scoreKey = 'score';
  static const _unlockedLocationKey = 'unlocked_location';
  static const _solvedExamplesKey = 'solved_examples';
  static const _currentQuestionIndexKey = 'current_question_index';
  static const _currentQuestionIndexesKey = 'current_question_indexes';
  static const _completedLevelIdsKey = 'completed_level_ids';
  static const _learningStatisticsKey = 'learning_statistics';
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
    final storedDifficulty = preferences.getString(_difficultyKey);
    final previousDifficulty = GameDifficulty.values.firstWhere(
      (candidate) => candidate.name == storedDifficulty,
      orElse: () => GameDifficulty.beginner,
    );
    final progressDifficulty =
        preferences.getString(_progressDifficultyKey) ??
        (_hasLegacyProgress(preferences)
            ? GameDifficulty.beginner.name
            : previousDifficulty.name);

    await preferences.setString(_progressDifficultyKey, progressDifficulty);
    await preferences.setString(_difficultyKey, difficulty.name);
    await preferences.setBool(
      _difficultyResetRequiredKey,
      difficulty.name != progressDifficulty,
    );
    difficultyNotifier.value = difficulty;
  }

  Future<bool> isDifficultyResetRequired() async {
    final preferences = await SharedPreferences.getInstance();
    final storedRequirement = preferences.getBool(_difficultyResetRequiredKey);
    if (storedRequirement != null) {
      return storedRequirement;
    }

    final progressDifficulty = preferences.getString(_progressDifficultyKey);
    final selectedDifficulty = preferences.getString(_difficultyKey);
    if (progressDifficulty != null) {
      return selectedDifficulty != null &&
          selectedDifficulty != progressDifficulty;
    }

    return _hasLegacyProgress(preferences) &&
        selectedDifficulty != null &&
        selectedDifficulty != GameDifficulty.beginner.name;
  }

  Future<void> confirmProgressResetForCurrentDifficulty() async {
    final preferences = await SharedPreferences.getInstance();
    final difficulty = await loadDifficulty();

    await Future.wait([
      preferences.setString(_progressDifficultyKey, difficulty.name),
      preferences.setBool(_difficultyResetRequiredKey, false),
    ]);
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

  bool _hasLegacyProgress(SharedPreferences preferences) {
    return (preferences.getInt(_scoreKey) ?? 0) > 0 ||
        (preferences.getInt(_unlockedLocationKey) ?? 1) > 1 ||
        (preferences.getInt(_solvedExamplesKey) ?? 0) > 0 ||
        (preferences.getInt(_currentQuestionIndexKey) ?? 0) > 0 ||
        preferences.getString(_currentQuestionIndexesKey) != null ||
        (preferences.getStringList(_completedLevelIdsKey)?.isNotEmpty ??
            false) ||
        preferences.getString(_learningStatisticsKey) != null;
  }
}
