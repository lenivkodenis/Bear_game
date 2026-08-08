import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'primary_game_button.dart';

Future<bool> showNorthConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Начать заново',
  String cancelLabel = 'Отмена',
}) async {
  return await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Подтверждение действия',
        barrierColor: const Color(0xD9001026),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (dialogContext, _, _) => NorthConfirmationDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onConfirm: () => Navigator.of(dialogContext).pop(true),
          onCancel: () => Navigator.of(dialogContext).pop(false),
        ),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeInCubic,
          );

          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.94,
                end: 1,
              ).animate(curvedAnimation),
              child: child,
            ),
          );
        },
      ) ??
      false;
}

class NorthConfirmationDialog extends StatelessWidget {
  const NorthConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 18 : 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 570),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFCF4),
                    AppTheme.frostBlue,
                    Color(0xFFD5EFFA),
                  ],
                  stops: [0, 0.58, 1],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.snowWhite, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000C1C),
                    blurRadius: 30,
                    offset: Offset(0, 14),
                  ),
                  BoxShadow(
                    color: Color(0x6696DDF4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: const _NorthDialogSnowPainter(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 22 : 34,
                    isCompact ? 24 : 32,
                    isCompact ? 22 : 34,
                    isCompact ? 22 : 30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SnowflakeBadge(),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTheme.screenTitleStyle.copyWith(
                                fontSize: isCompact ? 25 : 30,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.snowWhite.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.iceBlue,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: Text(
                            message,
                            style: AppTheme.bodyStyle.copyWith(
                              fontSize: isCompact ? 16 : 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      PrimaryGameButton(
                        label: confirmLabel,
                        icon: Icons.refresh_rounded,
                        symbol: '↻',
                        onPressed: onConfirm,
                      ),
                      const SizedBox(height: 12),
                      PrimaryGameButton(
                        label: cancelLabel,
                        icon: Icons.arrow_back_rounded,
                        symbol: '←',
                        secondary: true,
                        onPressed: onCancel,
                      ),
                    ],
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

class _SnowflakeBadge extends StatelessWidget {
  const _SnowflakeBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.snowWhite, AppTheme.iceBlue],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.snowWhite, width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.softShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const SizedBox.square(
        dimension: 52,
        child: Center(
          child: Text(
            '❄',
            style: TextStyle(
              color: AppTheme.softBlue,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _NorthDialogSnowPainter extends CustomPainter {
  const _NorthDialogSnowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final snowPaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.78);
    final snowPath = Path()
      ..moveTo(24, 0)
      ..lineTo(size.width - 24, 0)
      ..quadraticBezierTo(size.width - 72, 12, size.width - 116, 7)
      ..cubicTo(
        size.width * 0.64,
        2,
        size.width * 0.48,
        18,
        size.width * 0.34,
        8,
      )
      ..quadraticBezierTo(84, 1, 24, 0)
      ..close();
    canvas.drawPath(snowPath, snowPaint);

    final sparklePaint = Paint()
      ..color = AppTheme.snowWhite.withValues(alpha: 0.9);
    for (final sparkle in <Offset>[
      Offset(size.width * 0.84, 48),
      Offset(size.width * 0.91, 88),
      Offset(size.width * 0.09, size.height * 0.72),
    ]) {
      canvas.drawCircle(sparkle, 2.3, sparklePaint);
      canvas.drawLine(
        sparkle - const Offset(5, 0),
        sparkle + const Offset(5, 0),
        sparklePaint..strokeWidth = 1.2,
      );
      canvas.drawLine(
        sparkle - const Offset(0, 5),
        sparkle + const Offset(0, 5),
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NorthDialogSnowPainter oldDelegate) => false;
}
