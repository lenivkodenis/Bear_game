import '../models/learning_statistics.dart';
import '../models/player_progress.dart';

PlayerProgress visualTestGameProgress() => PlayerProgress.initial();

Future<PlayerProgress> visualTestMapProgress() async {
  return const PlayerProgress(
    score: 0,
    unlockedLocation: 10,
    solvedExamples: 0,
    currentQuestionIndexes: <int, int>{},
    completedLevelIds: <int>{1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
    learningStatistics: LearningStatistics.empty,
  );
}
