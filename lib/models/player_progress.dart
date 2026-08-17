import 'learning_statistics.dart';

class PlayerProgress {
  static const int totalLevelCount = 10;

  const PlayerProgress({
    required this.score,
    required this.unlockedLocation,
    required this.solvedExamples,
    required this.currentQuestionIndexes,
    required this.completedLevelIds,
    required this.learningStatistics,
  });

  final int score;
  final int unlockedLocation;
  final int solvedExamples;
  final Map<int, int> currentQuestionIndexes;
  final Set<int> completedLevelIds;
  final LearningStatistics learningStatistics;

  int get currentQuestionIndex => questionIndexForLevel(1);

  factory PlayerProgress.initial() {
    return const PlayerProgress(
      score: 0,
      unlockedLocation: 1,
      solvedExamples: 0,
      currentQuestionIndexes: {},
      completedLevelIds: {},
      learningStatistics: LearningStatistics.empty,
    );
  }

  int questionIndexForLevel(int levelId) {
    return currentQuestionIndexes[levelId] ?? 0;
  }

  bool isLevelCompleted(int levelId) {
    return completedLevelIds.contains(levelId);
  }

  bool get isGameCompleted {
    return completedLevelIds.containsAll(
      Iterable<int>.generate(totalLevelCount, (index) => index + 1),
    );
  }

  PlayerProgress copyWith({
    int? score,
    int? unlockedLocation,
    int? solvedExamples,
    Map<int, int>? currentQuestionIndexes,
    Set<int>? completedLevelIds,
    LearningStatistics? learningStatistics,
  }) {
    return PlayerProgress(
      score: score ?? this.score,
      unlockedLocation: unlockedLocation ?? this.unlockedLocation,
      solvedExamples: solvedExamples ?? this.solvedExamples,
      currentQuestionIndexes:
          currentQuestionIndexes ?? this.currentQuestionIndexes,
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
      learningStatistics: learningStatistics ?? this.learningStatistics,
    );
  }
}
