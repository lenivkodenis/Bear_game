import 'package:flutter/material.dart';

import '../models/map_location.dart';
import '../theme/app_theme.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({
    required this.location,
    required this.isUnlocked,
    required this.hasLevel,
    required this.isCompleted,
    required this.onTap,
    super.key,
  });

  final MapLocation location;
  final bool isUnlocked;
  final bool hasLevel;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrent = isUnlocked && !isCompleted && hasLevel;
    final borderColor = !isUnlocked
        ? AppTheme.lockedPanel
        : isCompleted
        ? AppTheme.warmYellow
        : isCurrent
        ? AppTheme.gentleGreen
        : AppTheme.iceBlue;
    final cardColor = !isUnlocked
        ? const Color(0xFFF1F5F7)
        : isCurrent
        ? AppTheme.paleGreen
        : AppTheme.snowWhite;
    final symbol = !isUnlocked
        ? '●'
        : isCompleted
        ? '★'
        : '•';
    final status = !isUnlocked
        ? 'Закрыто'
        : isCompleted
        ? 'Пройдено'
        : hasLevel
        ? 'Доступно'
        : 'Скоро откроется';

    return Opacity(
      opacity: isUnlocked ? 1 : 0.72,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: borderColor, width: isCurrent ? 3 : 2),
            boxShadow: const [
              BoxShadow(
                color: AppTheme.softShadow,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 66,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 6,
                          decoration: BoxDecoration(
                            color: borderColor.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: isCompleted
                          ? AppTheme.paleYellow
                          : isCurrent
                          ? const Color(0xFFCFF5E8)
                          : AppTheme.frostBlue,
                      child: Text(
                        symbol,
                        style: TextStyle(
                          color: isCompleted
                              ? AppTheme.warmYellow
                              : isUnlocked
                              ? AppTheme.deepBlue
                              : AppTheme.lockedBlue,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${location.id}. ${location.name}',
                      style: TextStyle(
                        color: isUnlocked
                            ? AppTheme.deepBlue
                            : AppTheme.lockedBlue,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: isCurrent
                            ? AppTheme.gentleGreen
                            : AppTheme.lockedBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Текущий шаг путешествия',
                        style: TextStyle(
                          color: AppTheme.deepBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                isUnlocked ? '›' : '●',
                style: TextStyle(
                  color: isUnlocked ? AppTheme.softBlue : AppTheme.lockedBlue,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
