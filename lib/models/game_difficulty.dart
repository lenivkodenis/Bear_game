enum GameDifficulty {
  beginner('beginner', 'Я учусь'),
  training('training', 'Я тренируюсь'),
  expert('expert', 'Я знаю');

  const GameDifficulty(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static GameDifficulty fromStorageValue(String? value) {
    return GameDifficulty.values.firstWhere(
      (difficulty) => difficulty.storageValue == value,
      orElse: () => GameDifficulty.beginner,
    );
  }
}
