class QuestionAnswerResult {
  const QuestionAnswerResult({
    required this.isCorrect,
    required this.message,
    required this.score,
    required this.isLevelComplete,
  });

  final bool isCorrect;
  final String message;
  final int score;
  final bool isLevelComplete;
}
