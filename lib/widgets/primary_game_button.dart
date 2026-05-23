import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrimaryGameButton extends StatefulWidget {
  const PrimaryGameButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.symbol,
    this.secondary = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? symbol;
  final bool secondary;

  @override
  State<PrimaryGameButton> createState() => _PrimaryGameButtonState();
}

class _PrimaryGameButtonState extends State<PrimaryGameButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final backgroundColor = widget.secondary
        ? AppTheme.snowWhite
        : AppTheme.softBlue;
    final foregroundColor = widget.secondary
        ? AppTheme.deepBlue
        : AppTheme.snowWhite;
    final activeColor = widget.secondary
        ? AppTheme.frostBlue
        : AppTheme.softBluePressed;
    final color = !isEnabled
        ? AppTheme.lockedPanel
        : (_isHovered || _isPressed)
        ? activeColor
        : backgroundColor;
    final textColor = isEnabled ? foregroundColor : AppTheme.lockedBlue;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: isEnabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: isEnabled
              ? () => setState(() => _isPressed = false)
              : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            constraints: const BoxConstraints(
              minHeight: AppTheme.minButtonHeight,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              border: widget.secondary
                  ? Border.all(color: AppTheme.iceBlue, width: 1.5)
                  : null,
              boxShadow: isEnabled
                  ? const [
                      BoxShadow(
                        color: AppTheme.softShadow,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  widget.symbol ?? '•',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
