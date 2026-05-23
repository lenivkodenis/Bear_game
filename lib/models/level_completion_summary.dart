class LevelCompletionSummary {
  const LevelCompletionSummary({
    required this.locationName,
    required this.mentorName,
    required this.score,
    required this.solvedQuestions,
  });

  final String locationName;
  final String mentorName;
  final int score;
  final int solvedQuestions;
}
