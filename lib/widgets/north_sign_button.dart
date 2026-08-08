import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum NorthSignTone { ice, sand, aurora, coral }

enum SnowCapVariant {
  softWave,
  leftDrift,
  centerDrift,
  rightDrift,
  doubleDrift,
}

class NorthSignButton extends StatefulWidget {
  const NorthSignButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.symbol,
    this.leading,
    this.tone = NorthSignTone.ice,
    this.snowCap = SnowCapVariant.softWave,
    this.prominent = false,
    super.key,
  }) : assert(icon != null || symbol != null || leading != null);

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? symbol;
  final Widget? leading;
  final NorthSignTone tone;
  final SnowCapVariant snowCap;
  final bool prominent;

  @override
  State<NorthSignButton> createState() => _NorthSignButtonState();
}

class _NorthSignButtonState extends State<NorthSignButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed != value) {
      setState(() => _isPressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final palette = _NorthSignPalette.forTone(widget.tone, enabled: isEnabled);
    final height = widget.prominent ? 72.0 : 58.0;
    final iconSize = widget.prominent ? 34.0 : 27.0;
    final foreground = palette.foreground;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: isEnabled ? (_) => setState(() => _isHovered = true) : null,
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: isEnabled ? (_) => _setPressed(true) : null,
          onTapUp: isEnabled ? (_) => _setPressed(false) : null,
          onTapCancel: isEnabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOutCubic,
            offset: Offset(0, _isPressed ? 0.035 : 0),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOutCubic,
              scale: _isPressed ? 0.985 : (_isHovered ? 1.008 : 1),
              child: SizedBox(
                height: height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _NorthSignPainter(
                        palette: palette,
                        snowCap: widget.snowCap,
                        prominent: widget.prominent,
                        pressed: _isPressed,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        widget.prominent ? 22 : 18,
                        widget.prominent ? 13 : 11,
                        widget.prominent ? 22 : 18,
                        widget.prominent ? 8 : 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox.square(
                            dimension: iconSize,
                            child: Center(child: _buildLeading(foreground)),
                          ),
                          SizedBox(width: widget.prominent ? 13 : 10),
                          Flexible(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: foreground,
                                fontSize: widget.prominent ? 20 : 17,
                                fontWeight: FontWeight.w900,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x4DFFFFFF),
                                    blurRadius: 2,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(Color color) {
    if (widget.leading != null) {
      return widget.leading!;
    }
    if (widget.icon != null) {
      return Icon(widget.icon, color: color, size: widget.prominent ? 32 : 25);
    }
    return Text(
      widget.symbol!,
      style: TextStyle(
        color: color,
        fontSize: widget.prominent ? 30 : 24,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    );
  }
}

class NorthSignSurface extends StatelessWidget {
  const NorthSignSurface({
    required this.child,
    this.tone = NorthSignTone.ice,
    this.snowCap = SnowCapVariant.softWave,
    this.padding = const EdgeInsets.fromLTRB(18, 20, 18, 13),
    this.minHeight = 74,
    super.key,
  });

  final Widget child;
  final NorthSignTone tone;
  final SnowCapVariant snowCap;
  final EdgeInsets padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: CustomPaint(
        painter: _NorthSignPainter(
          palette: _NorthSignPalette.forTone(tone),
          snowCap: snowCap,
          prominent: false,
          pressed: false,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _NorthSignPainter extends CustomPainter {
  const _NorthSignPainter({
    required this.palette,
    required this.snowCap,
    required this.prominent,
    required this.pressed,
  });

  final _NorthSignPalette palette;
  final SnowCapVariant snowCap;
  final bool prominent;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final signRect = Rect.fromLTWH(3, 8, size.width - 6, size.height - 12);
    final signRadius = Radius.circular(prominent ? 24 : 20);
    final signRRect = RRect.fromRectAndRadius(signRect, signRadius);
    final shadowPaint = Paint()
      ..color = const Color(
        0xFF001426,
      ).withValues(alpha: pressed ? 0.12 : (prominent ? 0.26 : 0.18))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, pressed ? 5 : 8);
    canvas.drawRRect(
      signRRect.shift(Offset(0, pressed ? 2.5 : 5)),
      shadowPaint,
    );

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: palette.colors,
        stops: const [0, 0.58, 1],
      ).createShader(signRect);
    canvas.drawRRect(signRRect, basePaint);

    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = prominent ? 2.2 : 1.8
      ..color = AppTheme.snowWhite.withValues(alpha: 0.9);
    canvas.drawRRect(signRRect.deflate(1.1), edgePaint);

    final lowEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = palette.foreground.withValues(alpha: 0.14);
    canvas.drawRRect(signRRect.deflate(3.8), lowEdgePaint);

    final snowPath = _snowPath(signRect, signRadius.x, snowCap, prominent);
    final snowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE9F8FF)],
      ).createShader(snowPath.getBounds());
    canvas.drawPath(snowPath, snowPaint);

    final snowEdgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0xFF8CCBE6).withValues(alpha: 0.38);
    canvas.drawPath(snowPath, snowEdgePaint);

    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = palette.foreground.withValues(alpha: 0.12);
    final grainY = signRect.top + size.height * 0.62;
    canvas.drawLine(
      Offset(signRect.left + 22, grainY),
      Offset(signRect.left + size.width * 0.34, grainY - 2),
      grainPaint,
    );
    canvas.drawLine(
      Offset(signRect.right - size.width * 0.34, grainY + 2),
      Offset(signRect.right - 24, grainY),
      grainPaint,
    );
  }

  Path _snowPath(
    Rect rect,
    double radius,
    SnowCapVariant variant,
    bool isProminent,
  ) {
    final left = rect.left + radius * 0.55;
    final right = rect.right - radius * 0.55;
    final top = rect.top + 1;
    final depth = isProminent ? 22.0 : 18.0;
    final path = Path()
      ..moveTo(left, top)
      ..lineTo(right, top);

    switch (variant) {
      case SnowCapVariant.softWave:
        path
          ..quadraticBezierTo(
            rect.right - 12,
            top + 8,
            rect.right - 22,
            top + 14,
          )
          ..cubicTo(
            rect.right - 70,
            top + depth,
            rect.left + 92,
            top + 8,
            rect.left + 54,
            top + depth - 3,
          );
      case SnowCapVariant.leftDrift:
        path
          ..quadraticBezierTo(
            rect.right - 13,
            top + 5,
            rect.right - 28,
            top + 10,
          )
          ..cubicTo(
            rect.width * 0.72,
            top + 13,
            rect.width * 0.38,
            top + 8,
            rect.left + 70,
            top + depth + 1,
          );
      case SnowCapVariant.centerDrift:
        path
          ..quadraticBezierTo(
            rect.right - 10,
            top + 8,
            rect.right - 27,
            top + 12,
          )
          ..cubicTo(
            rect.width * 0.73,
            top + 9,
            rect.width * 0.61,
            top + depth + 2,
            rect.width * 0.49,
            top + depth,
          )
          ..cubicTo(
            rect.width * 0.34,
            top + depth - 1,
            rect.width * 0.25,
            top + 9,
            rect.left + 54,
            top + 13,
          );
      case SnowCapVariant.rightDrift:
        path
          ..quadraticBezierTo(
            rect.right - 10,
            top + 12,
            rect.right - 36,
            top + depth + 1,
          )
          ..cubicTo(
            rect.width * 0.65,
            top + 9,
            rect.width * 0.34,
            top + 15,
            rect.left + 54,
            top + 10,
          );
      case SnowCapVariant.doubleDrift:
        path
          ..quadraticBezierTo(
            rect.right - 12,
            top + 9,
            rect.right - 26,
            top + 15,
          )
          ..cubicTo(
            rect.width * 0.72,
            top + depth,
            rect.width * 0.65,
            top + 8,
            rect.width * 0.54,
            top + 13,
          )
          ..cubicTo(
            rect.width * 0.43,
            top + depth + 1,
            rect.width * 0.29,
            top + 7,
            rect.left + 54,
            top + depth - 2,
          );
    }

    return path
      ..quadraticBezierTo(rect.left + 20, top + 16, left, top)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _NorthSignPainter oldDelegate) {
    return oldDelegate.palette != palette ||
        oldDelegate.snowCap != snowCap ||
        oldDelegate.prominent != prominent ||
        oldDelegate.pressed != pressed;
  }
}

class _NorthSignPalette {
  const _NorthSignPalette({required this.colors, required this.foreground});

  final List<Color> colors;
  final Color foreground;

  static _NorthSignPalette forTone(NorthSignTone tone, {bool enabled = true}) {
    if (!enabled) {
      return const _NorthSignPalette(
        colors: [Color(0xFFF1F5F6), Color(0xFFE3EAED), Color(0xFFCEDADF)],
        foreground: AppTheme.lockedBlue,
      );
    }

    return switch (tone) {
      NorthSignTone.ice => const _NorthSignPalette(
        colors: [Color(0xFFFDF9ED), Color(0xFFD7F1FF), Color(0xFF8FCFEC)],
        foreground: Color(0xFF12384F),
      ),
      NorthSignTone.sand => const _NorthSignPalette(
        colors: [Color(0xFFFFF8E9), Color(0xFFF1E0C1), Color(0xFFD3E9EF)],
        foreground: Color(0xFF173F58),
      ),
      NorthSignTone.aurora => const _NorthSignPalette(
        colors: [Color(0xFFFFF9E9), Color(0xFFDDF1D8), Color(0xFFBFE3DB)],
        foreground: Color(0xFF15534A),
      ),
      NorthSignTone.coral => const _NorthSignPalette(
        colors: [Color(0xFFFFF8ED), Color(0xFFF5DDD2), Color(0xFFE8D2DA)],
        foreground: Color(0xFF6A3944),
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is _NorthSignPalette &&
        other.foreground == foreground &&
        other.colors.length == colors.length &&
        List.generate(
          colors.length,
          (index) => other.colors[index] == colors[index],
        ).every((matches) => matches);
  }

  @override
  int get hashCode => Object.hash(foreground, Object.hashAll(colors));
}
