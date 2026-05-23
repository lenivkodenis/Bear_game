import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BackTextButton extends StatelessWidget {
  const BackTextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Назад',
      child: TextButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Text(
          '‹',
          style: TextStyle(
            color: AppTheme.deepBlue,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}
