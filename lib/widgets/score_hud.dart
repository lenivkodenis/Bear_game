import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ScoreHud extends StatelessWidget {
  const ScoreHud({
    required this.scoreListenable,
    super.key,
  });

  final ValueListenable<int> scoreListenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: scoreListenable,
      builder: (context, score, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF9BD3E8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF7B733)),
                const SizedBox(width: 6),
                Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17435A),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
