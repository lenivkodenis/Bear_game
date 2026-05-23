import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_progress.dart';

class ProgressService {
  static const _scoreKey = 'score';
  static const _unlockedLocationKey = 'unlocked_location';
  static const _solvedExamplesKey = 'solved_examples';
  static const _currentQuestionIndexKey = 'current_question_index';
  static const _currentQuestionIndexesKey = 'current_question_indexes';
  static const _completedLevelIdsKey = 'completed_level_ids';

  Future<PlayerProgress> loadProgress() async {
    final preferences = await SharedPreferences.getInstance();

    final questionIndexes = _loadQuestionIndexes(preferences);
    final completedLevelIds = _loadCompletedLevelIds(preferences);
    final storedUnlockedLocation =
        preferences.getInt(_unlockedLocationKey) ?? 1;

    return PlayerProgress(
      score: preferences.getInt(_scoreKey) ?? 0,
      unlockedLocation: _normalizeUnlockedLocation(
        storedUnlockedLocation,
        completedLevelIds,
      ),
      solvedExamples: preferences.getInt(_solvedExamplesKey) ?? 0,
      currentQuestionIndexes: questionIndexes,
      completedLevelIds: completedLevelIds,
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
    ]);
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
