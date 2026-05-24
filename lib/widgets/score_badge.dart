import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    required this.score,
    this.label = 'Снежинки',
    this.compact = false,
    super.key,
  });

  final int score;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 22.0 : 28.0;
    final valueSize = compact ? 18.0 : 20.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.paleYellow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.snowWhite, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.softShadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '★',
              style: TextStyle(
                color: AppTheme.warmYellow,
                fontSize: iconSize,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.lockedBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  score.toString(),
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.deepBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
