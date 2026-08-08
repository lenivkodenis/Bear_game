import 'package:flutter/material.dart';

import 'north_sign_button.dart';

class PrimaryGameButton extends StatelessWidget {
  const PrimaryGameButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.symbol,
    this.secondary = false,
    this.tone,
    this.snowCap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? symbol;
  final bool secondary;
  final NorthSignTone? tone;
  final SnowCapVariant? snowCap;

  @override
  Widget build(BuildContext context) {
    return NorthSignButton(
      label: label,
      icon: symbol == null ? icon : null,
      symbol: symbol,
      onPressed: onPressed,
      tone: tone ?? (secondary ? NorthSignTone.sand : NorthSignTone.ice),
      snowCap:
          snowCap ??
          (secondary ? SnowCapVariant.rightDrift : SnowCapVariant.leftDrift),
    );
  }
}
