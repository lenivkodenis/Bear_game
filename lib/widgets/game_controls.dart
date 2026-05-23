import 'package:flutter/material.dart';

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
                icon: Icons.keyboard_arrow_left_rounded,
                tooltip: 'Влево',
                onHoldStart: onMoveLeftStart,
                onHoldEnd: onMoveEnd,
              ),
              const SizedBox(width: 12),
              _HoldButton(
                icon: Icons.keyboard_arrow_right_rounded,
                tooltip: 'Вправо',
                onHoldStart: onMoveRightStart,
                onHoldEnd: onMoveEnd,
              ),
            ],
          ),
          IconButton.filled(
            onPressed: onJump,
            icon: const Icon(Icons.arrow_upward_rounded),
            iconSize: 32,
            tooltip: 'Прыжок',
          ),
        ],
      ),
    );
  }
}

class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.icon,
    required this.tooltip,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final IconData icon;
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
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(
            dimension: 56,
            child: Icon(icon, color: Colors.white, size: 36),
          ),
        ),
      ),
    );
  }
}
