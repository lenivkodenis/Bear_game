class PlayerProgress {
  const PlayerProgress({
    required this.score,
    required this.unlockedLocation,
    required this.solvedExamples,
    required this.currentQuestionIndex,
  });

  final int score;
  final int unlockedLocation;
  final int solvedExamples;
  final int currentQuestionIndex;

  factory PlayerProgress.initial() {
    return const PlayerProgress(
      score: 0,
      unlockedLocation: 1,
      solvedExamples: 0,
      currentQuestionIndex: 0,
    );
  }

  PlayerProgress copyWith({
    int? score,
    int? unlockedLocation,
    int? solvedExamples,
    int? currentQuestionIndex,
  }) {
    return PlayerProgress(
      score: score ?? this.score,
      unlockedLocation: unlockedLocation ?? this.unlockedLocation,
      solvedExamples: solvedExamples ?? this.solvedExamples,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
    );
  }
}
