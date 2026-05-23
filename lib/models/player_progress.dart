class PlayerProgress {
  const PlayerProgress({
    required this.score,
    required this.unlockedLocation,
    required this.solvedExamples,
  });

  final int score;
  final int unlockedLocation;
  final int solvedExamples;

  factory PlayerProgress.initial() {
    return const PlayerProgress(
      score: 0,
      unlockedLocation: 1,
      solvedExamples: 0,
    );
  }

  PlayerProgress copyWith({
    int? score,
    int? unlockedLocation,
    int? solvedExamples,
  }) {
    return PlayerProgress(
      score: score ?? this.score,
      unlockedLocation: unlockedLocation ?? this.unlockedLocation,
      solvedExamples: solvedExamples ?? this.solvedExamples,
    );
  }
}
