import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_progress.dart';

class ProgressService {
  static const _scoreKey = 'score';
  static const _unlockedLocationKey = 'unlocked_location';
  static const _solvedExamplesKey = 'solved_examples';

  Future<PlayerProgress> loadProgress() async {
    final preferences = await SharedPreferences.getInstance();

    return PlayerProgress(
      score: preferences.getInt(_scoreKey) ?? 0,
      unlockedLocation: preferences.getInt(_unlockedLocationKey) ?? 1,
      solvedExamples: preferences.getInt(_solvedExamplesKey) ?? 0,
    );
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    final preferences = await SharedPreferences.getInstance();

    await Future.wait([
      preferences.setInt(_scoreKey, progress.score),
      preferences.setInt(_unlockedLocationKey, progress.unlockedLocation),
      preferences.setInt(_solvedExamplesKey, progress.solvedExamples),
    ]);
  }
}
