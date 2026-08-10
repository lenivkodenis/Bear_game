import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GameControlsController extends ChangeNotifier {
  void interrupt() => notifyListeners();
}

class GameControls extends StatefulWidget {
  const GameControls({
    required this.onMoveLeftStart,
    required this.onMoveRightStart,
    required this.onMoveEnd,
    required this.onJump,
    this.enabled = true,
    this.controller,
    super.key,
  });

  final VoidCallback onMoveLeftStart;
  final VoidCallback onMoveRightStart;
  final VoidCallback onMoveEnd;
  final VoidCallback onJump;
  final bool enabled;
  final GameControlsController? controller;

  @override
  State<GameControls> createState() => _GameControlsState();
}

class _GameControlsState extends State<GameControls> {
  int _interruptRevision = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_interrupt);
  }

  @override
  void didUpdateWidget(GameControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_interrupt);
      widget.controller?.addListener(_interrupt);
    }
    if (oldWidget.enabled && !widget.enabled) {
      _interrupt();
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_interrupt);
    super.dispose();
  }

  void _interrupt() {
    if (!mounted) return;
    setState(() => _interruptRevision += 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ultraShort = constraints.maxHeight < 300;
        final compactLandscape = constraints.maxHeight < 420;
        final controlSize = ultraShort
            ? 50.0
            : compactLandscape
            ? 58.0
            : 64.0;
        final touchTargetSize = ultraShort
            ? 56.0
            : compactLandscape
            ? 64.0
            : 76.0;

        return IgnorePointer(
          ignoring: !widget.enabled,
          child: AnimatedOpacity(
            opacity: widget.enabled ? 1 : 0.55,
            duration: const Duration(milliseconds: 100),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compactLandscape ? 8 : 16,
                0,
                compactLandscape ? 8 : 16,
                ultraShort
                    ? 2
                    : compactLandscape
                    ? 6
                    : 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      KeyedSubtree(
                        key: ValueKey<String>('left-$_interruptRevision'),
                        child: _HoldButton(
                          key: const ValueKey<String>('game-control-left'),
                          symbol: '‹',
                          semanticsLabel: 'Влево',
                          controlSize: controlSize,
                          touchTargetSize: touchTargetSize,
                          onHoldStart: widget.onMoveLeftStart,
                          onHoldEnd: widget.onMoveEnd,
                        ),
                      ),
                      const SizedBox(width: 4),
                      KeyedSubtree(
                        key: ValueKey<String>('right-$_interruptRevision'),
                        child: _HoldButton(
                          key: const ValueKey<String>('game-control-right'),
                          symbol: '›',
                          semanticsLabel: 'Вправо',
                          controlSize: controlSize,
                          touchTargetSize: touchTargetSize,
                          onHoldStart: widget.onMoveRightStart,
                          onHoldEnd: widget.onMoveEnd,
                        ),
                      ),
                    ],
                  ),
                  KeyedSubtree(
                    key: ValueKey<String>('jump-$_interruptRevision'),
                    child: _TapButton(
                      key: const ValueKey<String>('game-control-jump'),
                      symbol: '↑',
                      semanticsLabel: 'Прыжок',
                      controlSize: controlSize,
                      touchTargetSize: touchTargetSize,
                      onPressed: widget.onJump,
                    ),
                  ),
                ],
              ),
            ),
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
