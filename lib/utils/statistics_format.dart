String formatLearningDuration(int milliseconds) {
  if (milliseconds <= 0) {
    return '0 сек';
  }

  final totalSeconds = (milliseconds / 1000).ceil();
  if (totalSeconds < 60) {
    return '$totalSeconds сек';
  }

  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return minutes == 0 ? '$hours ч' : '$hours ч $minutes мин';
  }

  return seconds == 0 ? '$minutes мин' : '$minutes мин $seconds сек';
}
