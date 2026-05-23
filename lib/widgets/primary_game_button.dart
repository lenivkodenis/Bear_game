import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrimaryGameButton extends StatelessWidget {
  const PrimaryGameButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.secondary = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = secondary ? AppTheme.snowWhite : AppTheme.softBlue;
    final foregroundColor = secondary ? AppTheme.deepBlue : AppTheme.snowWhite;
    final pressedColor = secondary
        ? AppTheme.frostBlue
        : AppTheme.softBluePressed;

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label, textAlign: TextAlign.center),
      ),
      style:
          FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            minimumSize: const Size.fromHeight(AppTheme.minButtonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            disabledBackgroundColor: AppTheme.lockedPanel,
            disabledForegroundColor: AppTheme.lockedBlue,
            side: secondary ? const BorderSide(color: AppTheme.iceBlue) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return AppTheme.lockedPanel;
              }
              if (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered)) {
                return pressedColor;
              }
              return backgroundColor;
            }),
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return AppTheme.snowWhite.withValues(alpha: 0.14);
              }
              if (states.contains(WidgetState.hovered)) {
                return AppTheme.snowWhite.withValues(alpha: 0.08);
              }
              return null;
            }),
            elevation: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return 0;
              }
              if (states.contains(WidgetState.pressed)) {
                return 1;
              }
              if (states.contains(WidgetState.hovered)) {
                return 6;
              }
              return 3;
            }),
          ),
    );
  }
}
