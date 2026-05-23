import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    required this.child,
    this.padding = AppTheme.cardPadding,
    this.margin = EdgeInsets.zero,
    this.backgroundColor = AppTheme.snowWhite,
    this.borderColor = AppTheme.iceBlue,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.softShadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
