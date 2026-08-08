class RoundSettings {
  const RoundSettings({
    required this.roundQuestionCount,
    required this.maxMistakesPerRound,
    required this.wrongAnswerPenalty,
  });

  final int roundQuestionCount;
  final int maxMistakesPerRound;
  final int wrongAnswerPenalty;

  static const fixedRoundQuestionCount = 10;

  static const defaults = RoundSettings(
    roundQuestionCount: fixedRoundQuestionCount,
    maxMistakesPerRound: 2,
    wrongAnswerPenalty: 2,
  );

  factory RoundSettings.fromJson(Map<String, Object?> json) {
    return RoundSettings(
      roundQuestionCount:
          _readInt(json['roundQuestionCount']) ?? defaults.roundQuestionCount,
      maxMistakesPerRound:
          _readInt(json['maxMistakesPerRound']) ?? defaults.maxMistakesPerRound,
      wrongAnswerPenalty:
          _readInt(json['wrongAnswerPenalty']) ?? defaults.wrongAnswerPenalty,
    ).validated();
  }

  Map<String, Object?> toJson() {
    return {
      'roundQuestionCount': roundQuestionCount,
      'maxMistakesPerRound': maxMistakesPerRound,
      'wrongAnswerPenalty': wrongAnswerPenalty,
    };
  }

  RoundSettings validated() {
    return RoundSettings(
      roundQuestionCount: fixedRoundQuestionCount,
      maxMistakesPerRound: maxMistakesPerRound.clamp(0, 100).toInt(),
      wrongAnswerPenalty: wrongAnswerPenalty.clamp(1, 100).toInt(),
    );
  }

  RoundSettings copyWith({
    int? roundQuestionCount,
    int? maxMistakesPerRound,
    int? wrongAnswerPenalty,
  }) {
    return RoundSettings(
      roundQuestionCount: roundQuestionCount ?? this.roundQuestionCount,
      maxMistakesPerRound: maxMistakesPerRound ?? this.maxMistakesPerRound,
      wrongAnswerPenalty: wrongAnswerPenalty ?? this.wrongAnswerPenalty,
    );
  }

  static int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
