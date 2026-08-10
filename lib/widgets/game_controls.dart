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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLandscape = constraints.maxHeight < 420;
        final controlSize = compactLandscape ? 60.0 : 64.0;
        final touchTargetSize = compactLandscape ? 68.0 : 76.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            compactLandscape ? 12 : 16,
            0,
            compactLandscape ? 12 : 16,
            compactLandscape ? 8 : 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _HoldButton(
                    key: const ValueKey<String>('game-control-left'),
                    symbol: '‹',
                    semanticsLabel: 'Влево',
                    controlSize: controlSize,
                    touchTargetSize: touchTargetSize,
                    onHoldStart: onMoveLeftStart,
                    onHoldEnd: onMoveEnd,
                  ),
                  const SizedBox(width: 4),
                  _HoldButton(
                    key: const ValueKey<String>('game-control-right'),
                    symbol: '›',
                    semanticsLabel: 'Вправо',
                    controlSize: controlSize,
                    touchTargetSize: touchTargetSize,
                    onHoldStart: onMoveRightStart,
                    onHoldEnd: onMoveEnd,
                  ),
                ],
              ),
              _TapButton(
                key: const ValueKey<String>('game-control-jump'),
                symbol: '↑',
                semanticsLabel: 'Прыжок',
                controlSize: controlSize,
                touchTargetSize: touchTargetSize,
                onPressed: onJump,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HoldButton extends StatefulWidget {
  const _HoldButton({
    super.key,
    required this.symbol,
    required this.semanticsLabel,
    required this.controlSize,
    required this.touchTargetSize,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final String symbol;
  final String semanticsLabel;
  final double controlSize;
  final double touchTargetSize;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  int? _activePointer;
  bool _isHolding = false;

  @override
  void dispose() {
    if (_isHolding) {
      widget.onHoldEnd();
    }
    super.dispose();
  }

  void _startHold(PointerDownEvent event) {
    if (_activePointer != null) {
      return;
    }

    _activePointer = event.pointer;
    setState(() => _isHolding = true);
    widget.onHoldStart();
  }

  void _finishHold(PointerEvent event) {
    if (_activePointer != event.pointer) {
      return;
    }

    _activePointer = null;
    setState(() => _isHolding = false);
    widget.onHoldEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _startHold,
        onPointerUp: _finishHold,
        onPointerCancel: _finishHold,
        child: SizedBox.square(
          dimension: widget.touchTargetSize,
          child: Center(
            child: AnimatedScale(
              scale: _isHolding ? 0.92 : 1,
              duration: const Duration(milliseconds: 70),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _isHolding ? AppTheme.deepBlue : AppTheme.softBlue,
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
                  dimension: widget.controlSize,
                  child: Center(
                    child: Text(
                      widget.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapButton extends StatefulWidget {
  const _TapButton({
    super.key,
    required this.symbol,
    required this.semanticsLabel,
    required this.controlSize,
    required this.touchTargetSize,
    required this.onPressed,
  });

  final String symbol;
  final String semanticsLabel;
  final double controlSize;
  final double touchTargetSize;
  final VoidCallback onPressed;

  @override
  State<_TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<_TapButton> {
  final Set<int> _activePointers = <int>{};

  void _press(PointerDownEvent event) {
    if (!_activePointers.add(event.pointer)) {
      return;
    }

    setState(() {});
    widget.onPressed();
  }

  void _release(PointerEvent event) {
    if (_activePointers.remove(event.pointer)) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPressed = _activePointers.isNotEmpty;

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _press,
        onPointerUp: _release,
        onPointerCancel: _release,
        child: SizedBox.square(
          dimension: widget.touchTargetSize,
          child: Center(
            child: AnimatedScale(
              scale: isPressed ? 0.92 : 1,
              duration: const Duration(milliseconds: 70),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isPressed
                      ? AppTheme.gentleGreenPressed
                      : AppTheme.gentleGreen,
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
                  dimension: widget.controlSize,
                  child: Center(
                    child: Text(
                      widget.symbol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
