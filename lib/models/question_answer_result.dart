enum RestartRequiredReason { notEnoughSnowflakes, tooManyMistakes }

class QuestionAnswerResult {
  const QuestionAnswerResult({
    required this.isCorrect,
    required this.message,
    required this.score,
    required this.isLevelComplete,
    this.restartRequiredReason,
  });

  final bool isCorrect;
  final String message;
  final int score;
  final bool isLevelComplete;
  final RestartRequiredReason? restartRequiredReason;

  bool get requiresRestart => restartRequiredReason != null;
}
