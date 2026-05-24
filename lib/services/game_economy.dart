class GameEconomy {
  const GameEconomy._();

  static const int firstAttemptSnowflakes = 5;
  static const int afterHintSnowflakes = 3;
  static const int maxQuestionsPerLevel = 10;
  static const int maxSnowflakesPerLevel =
      firstAttemptSnowflakes * maxQuestionsPerLevel;

  static int snowflakesForCorrectAnswer({required bool hadWrongAttempt}) {
    return hadWrongAttempt ? afterHintSnowflakes : firstAttemptSnowflakes;
  }
}
