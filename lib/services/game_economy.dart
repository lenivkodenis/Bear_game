class GameEconomy {
  const GameEconomy._();

  static const int correctAnswerSnowflakes = 1;
  static const int defaultWrongAnswerPenalty = 2;
  static const int maxQuestionsPerRound = 10;
  static const int maxTotalSnowflakes = 100;
  static const int maxSnowflakesPerLevel = maxQuestionsPerRound;

  static int snowflakesForCorrectAnswer({bool hadWrongAttempt = false}) {
    return correctAnswerSnowflakes;
  }

  static int scoreAfterCorrectAnswer(int score) {
    return (score + correctAnswerSnowflakes)
        .clamp(0, maxTotalSnowflakes)
        .toInt();
  }

  static int scoreAfterWrongAnswer({required int score, required int penalty}) {
    return (score - penalty).clamp(0, maxTotalSnowflakes).toInt();
  }
}
