class LevelCompletionSummary {
  const LevelCompletionSummary({
    required this.locationName,
    required this.mentorName,
    required this.completionText,
    required this.score,
    required this.levelSnowflakes,
    required this.solvedQuestions,
  });

  final String locationName;
  final String mentorName;
  final String completionText;
  final int score;
  final int levelSnowflakes;
  final int solvedQuestions;
}
