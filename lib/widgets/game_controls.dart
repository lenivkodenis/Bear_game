import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GameControls extends StatelessWidget {
  const GameControls({
    required this.onMoveLeftStart,
    required this.onMoveRightStart,
    required this.onMoveEnd,
    required this.onJump,
    super.key,
  });

  final VoidCallback onMoveLeftStart;
  final VoidCallback onMoveRightStart;
  final VoidCallback onMoveEnd;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _HoldButton(
                symbol: '‹',
                tooltip: 'Влево',
                onHoldStart: onMoveLeftStart,
                onHoldEnd: onMoveEnd,
              ),
              const SizedBox(width: 12),
              _HoldButton(
                symbol: '›',
                tooltip: 'Вправо',
                onHoldStart: onMoveRightStart,
                onHoldEnd: onMoveEnd,
              ),
            ],
          ),
          _TapButton(symbol: '↑', tooltip: 'Прыжок', onPressed: onJump),
        ],
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.symbol,
    required this.tooltip,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final String symbol;
  final String tooltip;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onHoldStart(),
      onTapUp: (_) => onHoldEnd(),
      onTapCancel: onHoldEnd,
      child: Tooltip(
        message: tooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.softBlue,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.snowWhite, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.softShadow,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: 56,
            child: Center(
              child: Text(
                symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapButton extends StatelessWidget {
  const _TapButton({
    required this.symbol,
    required this.tooltip,
    required this.onPressed,
  });

  final String symbol;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.gentleGreen,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.snowWhite, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.softShadow,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: 56,
            child: Center(
              child: Text(
                symbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
