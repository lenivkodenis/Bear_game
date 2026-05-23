import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'score_badge.dart';

class ScoreHud extends StatelessWidget {
  const ScoreHud({required this.scoreListenable, super.key});

  final ValueListenable<int> scoreListenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: scoreListenable,
      builder: (context, score, _) {
        return ScoreBadge(score: score);
      },
    );
  }
}
