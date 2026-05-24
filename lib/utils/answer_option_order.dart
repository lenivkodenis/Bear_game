import 'dart:math' as math;

List<int> shuffledAnswerOptions(List<int> options, {math.Random? random}) {
  final shuffledOptions = List<int>.of(options);
  shuffledOptions.shuffle(random);
  return shuffledOptions;
}
