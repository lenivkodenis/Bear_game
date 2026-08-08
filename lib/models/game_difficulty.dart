enum GameDifficulty {
  beginner(
    title: 'Я учусь',
    description: '3 варианта ответа и подробные подсказки.',
  ),
  training(
    title: 'Я тренируюсь',
    description: 'Сложнее варианты ответа и подсказки без прямого ответа.',
  ),
  expert(
    title: 'Я знаю',
    description: 'Ответ нужно будет вводить самостоятельно.',
  );

  const GameDifficulty({required this.title, required this.description});

  final String title;
  final String description;
}
