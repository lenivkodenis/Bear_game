import 'package:flutter/material.dart';

import '../models/learning_statistics.dart';
import '../theme/app_theme.dart';
import '../utils/statistics_format.dart';
import 'game_card.dart';
import 'north_sign_button.dart';
import 'primary_game_button.dart';

class LearningStatisticsCard extends StatefulWidget {
  const LearningStatisticsCard({
    required this.title,
    required this.completedQuestions,
    required this.totalWrongAnswers,
    required this.totalAttempts,
    required this.totalElapsedMilliseconds,
    required this.averageMillisecondsPerQuestion,
    required this.accuracyPercent,
    this.questions = const [],
    this.detailsInitiallyExpanded = false,
    super.key,
  });

  factory LearningStatisticsCard.forLevel({
    required LevelStatistics statistics,
    bool detailsInitiallyExpanded = false,
  }) {
    return LearningStatisticsCard(
      key: ValueKey<String>('level-statistics-${statistics.levelId}'),
      title: 'Уровень ${statistics.levelId} · ${statistics.locationName}',
      completedQuestions: statistics.completedQuestions,
      totalWrongAnswers: statistics.totalWrongAnswers,
      totalAttempts: statistics.totalAttempts,
      totalElapsedMilliseconds: statistics.totalElapsedMilliseconds,
      averageMillisecondsPerQuestion: statistics.averageMillisecondsPerQuestion,
      accuracyPercent: statistics.accuracyPercent,
      questions: statistics.sortedQuestions,
      detailsInitiallyExpanded: detailsInitiallyExpanded,
    );
  }

  factory LearningStatisticsCard.total({
    required LearningStatistics statistics,
  }) {
    return LearningStatisticsCard(
      key: const ValueKey<String>('total-learning-statistics'),
      title: 'Накопительная статистика',
      completedQuestions: statistics.completedQuestions,
      totalWrongAnswers: statistics.totalWrongAnswers,
      totalAttempts: statistics.totalAttempts,
      totalElapsedMilliseconds: statistics.totalElapsedMilliseconds,
      averageMillisecondsPerQuestion: statistics.averageMillisecondsPerQuestion,
      accuracyPercent: statistics.accuracyPercent,
    );
  }

  final String title;
  final int completedQuestions;
  final int totalWrongAnswers;
  final int totalAttempts;
  final int totalElapsedMilliseconds;
  final int averageMillisecondsPerQuestion;
  final int accuracyPercent;
  final List<QuestionStatistics> questions;
  final bool detailsInitiallyExpanded;

  @override
  State<LearningStatisticsCard> createState() => _LearningStatisticsCardState();
}

class _LearningStatisticsCardState extends State<LearningStatisticsCard> {
  late bool _detailsExpanded;

  @override
  void initState() {
    super.initState();
    _detailsExpanded = widget.detailsInitiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: AppTheme.sectionTitleStyle),
          const SizedBox(height: 6),
          Text(
            'Решено задач: ${widget.completedQuestions} · '
            'Всего попыток: ${widget.totalAttempts}',
            style: AppTheme.bodyStyle,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final metricWidth = (constraints.maxWidth - 10) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StatisticMetric(
                    width: metricWidth,
                    symbol: '◷',
                    label: 'Общее время',
                    value: formatLearningDuration(
                      widget.totalElapsedMilliseconds,
                    ),
                  ),
                  _StatisticMetric(
                    width: metricWidth,
                    symbol: '×',
                    label: 'Ошибки',
                    value: widget.totalWrongAnswers.toString(),
                  ),
                  _StatisticMetric(
                    width: metricWidth,
                    symbol: '%',
                    label: 'Точность',
                    value: '${widget.accuracyPercent}%',
                  ),
                  _StatisticMetric(
                    width: metricWidth,
                    symbol: '≈',
                    label: 'Среднее на задачу',
                    value: formatLearningDuration(
                      widget.averageMillisecondsPerQuestion,
                    ),
                  ),
                ],
              );
            },
          ),
          if (widget.questions.isNotEmpty) ...[
            const SizedBox(height: 16),
            PrimaryGameButton(
              onPressed: () {
                setState(() => _detailsExpanded = !_detailsExpanded);
              },
              icon: _detailsExpanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              symbol: _detailsExpanded ? '⌃' : '⌄',
              secondary: true,
              tone: NorthSignTone.sand,
              snowCap: _detailsExpanded
                  ? SnowCapVariant.rightDrift
                  : SnowCapVariant.centerDrift,
              label: _detailsExpanded
                  ? 'Скрыть задачи'
                  : 'Показать задачи (${widget.questions.length})',
            ),
            if (_detailsExpanded) ...[
              const SizedBox(height: 12),
              for (final question in widget.questions) ...[
                _QuestionStatisticRow(statistics: question),
                if (question != widget.questions.last)
                  const Divider(height: 18),
              ],
            ],
          ],
        ],
      ),
    );
  }
}

class _StatisticMetric extends StatelessWidget {
  const _StatisticMetric({
    required this.width,
    required this.symbol,
    required this.label,
    required this.value,
  });

  final double width;
  final String symbol;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.frostBlue.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.iceBlue),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: AppTheme.softBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.lockedBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.deepBlue,
                  fontSize: 18,
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

class _QuestionStatisticRow extends StatelessWidget {
  const _QuestionStatisticRow({required this.statistics});

  final QuestionStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: AppTheme.frostBlue,
          child: Text(
            statistics.questionNumber.toString(),
            style: const TextStyle(
              color: AppTheme.deepBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statistics.expression,
                style: const TextStyle(
                  color: AppTheme.deepBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Время: ${formatLearningDuration(statistics.elapsedMilliseconds)} · '
                'Попыток: ${statistics.attempts}',
                style: const TextStyle(color: AppTheme.lockedBlue),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Ошибки: ${statistics.wrongAnswers}',
          style: TextStyle(
            color: statistics.wrongAnswers == 0
                ? AppTheme.gentleGreen
                : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
