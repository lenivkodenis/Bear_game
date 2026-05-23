class PlayerProgress {
  const PlayerProgress({
    required this.score,
    required this.unlockedLocation,
    required this.solvedExamples,
    required this.currentQuestionIndexes,
    required this.completedLevelIds,
  });

  final int score;
  final int unlockedLocation;
  final int solvedExamples;
  final Map<int, int> currentQuestionIndexes;
  final Set<int> completedLevelIds;

  int get currentQuestionIndex => questionIndexForLevel(1);

  factory PlayerProgress.initial() {
    return const PlayerProgress(
      score: 0,
      unlockedLocation: 1,
      solvedExamples: 0,
      currentQuestionIndexes: {},
      completedLevelIds: {},
    );
  }

  int questionIndexForLevel(int levelId) {
    return currentQuestionIndexes[levelId] ?? 0;
  }

  bool isLevelCompleted(int levelId) {
    return completedLevelIds.contains(levelId);
  }

  PlayerProgress copyWith({
    int? score,
    int? unlockedLocation,
    int? solvedExamples,
    Map<int, int>? currentQuestionIndexes,
    Set<int>? completedLevelIds,
  }) {
    return PlayerProgress(
      score: score ?? this.score,
      unlockedLocation: unlockedLocation ?? this.unlockedLocation,
      solvedExamples: solvedExamples ?? this.solvedExamples,
      currentQuestionIndexes:
          currentQuestionIndexes ?? this.currentQuestionIndexes,
      completedLevelIds: completedLevelIds ?? this.completedLevelIds,
    );
  }
}
