import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_progress.dart';
import '../models/learning_statistics.dart';
import 'game_economy.dart';

class ProgressService {
  static const _scoreKey = 'score';
  static const _unlockedLocationKey = 'unlocked_location';
  static const _solvedExamplesKey = 'solved_examples';
  static const _currentQuestionIndexKey = 'current_question_index';
  static const _currentQuestionIndexesKey = 'current_question_indexes';
  static const _completedLevelIdsKey = 'completed_level_ids';
  static const _learningStatisticsKey = 'learning_statistics';

  Future<PlayerProgress> loadProgress() async {
    final preferences = await SharedPreferences.getInstance();

    final questionIndexes = _loadQuestionIndexes(preferences);
    final completedLevelIds = _loadCompletedLevelIds(preferences);
    final storedUnlockedLocation =
        preferences.getInt(_unlockedLocationKey) ?? 1;

    return PlayerProgress(
      score: (preferences.getInt(_scoreKey) ?? 0)
          .clamp(0, GameEconomy.maxTotalSnowflakes)
          .toInt(),
      unlockedLocation: _normalizeUnlockedLocation(
        storedUnlockedLocation,
        completedLevelIds,
      ),
      solvedExamples: preferences.getInt(_solvedExamplesKey) ?? 0,
      currentQuestionIndexes: questionIndexes,
      completedLevelIds: completedLevelIds,
      learningStatistics: _loadLearningStatistics(preferences),
    );
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.setInt(_scoreKey, progress.score),
      preferences.setInt(_unlockedLocationKey, progress.unlockedLocation),
      preferences.setInt(_solvedExamplesKey, progress.solvedExamples),
      preferences.setString(
        _currentQuestionIndexesKey,
        jsonEncode(
          progress.currentQuestionIndexes.map(
            (levelId, questionIndex) =>
                MapEntry(levelId.toString(), questionIndex),
          ),
        ),
      ),
      preferences.setStringList(
        _completedLevelIdsKey,
        progress.completedLevelIds
            .map((levelId) => levelId.toString())
            .toList(),
      ),
      preferences.setInt(
        _currentQuestionIndexKey,
        progress.currentQuestionIndex,
      ),
      preferences.setString(
        _learningStatisticsKey,
        jsonEncode(progress.learningStatistics.toJson()),
      ),
    ]);
  }

  Future<void> resetProgress() async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.remove(_scoreKey),
      preferences.remove(_unlockedLocationKey),
      preferences.remove(_solvedExamplesKey),
      preferences.remove(_currentQuestionIndexKey),
      preferences.remove(_currentQuestionIndexesKey),
      preferences.remove(_completedLevelIdsKey),
      preferences.remove(_learningStatisticsKey),
    ]);
  }

  Future<PlayerProgress> rewindToLevel(int levelId) async {
    if (levelId < 1 || levelId > 10) {
      throw ArgumentError.value(levelId, 'levelId', 'must be from 1 to 10');
    }

    final progress = await loadProgress();
    final questionIndexes = Map<int, int>.of(progress.currentQuestionIndexes)
      ..removeWhere((savedLevelId, _) => savedLevelId >= levelId);
    final completedLevelIds = Set<int>.of(progress.completedLevelIds)
      ..removeWhere((savedLevelId) => savedLevelId >= levelId);
    final rewoundProgress = progress.copyWith(
      unlockedLocation: levelId,
      currentQuestionIndexes: questionIndexes,
      completedLevelIds: completedLevelIds,
    );

    await saveProgress(rewoundProgress);
    return rewoundProgress;
  }

  Map<int, int> _loadQuestionIndexes(SharedPreferences preferences) {
    final storedValue = preferences.getString(_currentQuestionIndexesKey);
    if (storedValue != null) {
      final decodedValue = jsonDecode(storedValue) as Map<String, Object?>;

      return decodedValue.map(
        (levelId, questionIndex) =>
            MapEntry(int.parse(levelId), questionIndex as int),
      );
    }

    final legacyQuestionIndex = preferences.getInt(_currentQuestionIndexKey);
    if (legacyQuestionIndex != null && legacyQuestionIndex > 0) {
      return {1: legacyQuestionIndex};
    }

    return {};
  }

  Set<int> _loadCompletedLevelIds(SharedPreferences preferences) {
    return preferences
            .getStringList(_completedLevelIdsKey)
            ?.map(int.parse)
            .toSet() ??
        {};
  }

  LearningStatistics _loadLearningStatistics(SharedPreferences preferences) {
    final storedValue = preferences.getString(_learningStatisticsKey);
    if (storedValue == null) {
      return LearningStatistics.empty;
    }

    try {
      return LearningStatistics.fromJson(
        jsonDecode(storedValue) as Map<String, Object?>,
      );
    } on Object {
      return LearningStatistics.empty;
    }
  }

  int _normalizeUnlockedLocation(
    int storedUnlockedLocation,
    Set<int> completedLevelIds,
  ) {
    var unlockedLocation = storedUnlockedLocation;
    for (final levelId in completedLevelIds) {
      if (levelId + 1 > unlockedLocation) {
        unlockedLocation = levelId + 1;
      }
    }

    return unlockedLocation;
  }
}
