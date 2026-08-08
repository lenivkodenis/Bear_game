import 'package:flutter/material.dart';

import 'north_sign_button.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NorthSignButton(
      onPressed: onPressed,
      icon: icon,
      label: label,
      snowCap: SnowCapVariant.centerDrift,
    );
  }
}
