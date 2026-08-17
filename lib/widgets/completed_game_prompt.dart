import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CompletedGamePrompt extends StatefulWidget {
  const CompletedGamePrompt({
    required this.mentorName,
    required this.locationName,
    required this.onReplayLevel,
    required this.onRestartGame,
    required this.onClose,
    super.key,
  });

  final String mentorName;
  final String locationName;
  final Future<void> Function() onReplayLevel;
  final Future<void> Function() onRestartGame;
  final VoidCallback onClose;

  @override
  State<CompletedGamePrompt> createState() => _CompletedGamePromptState();
}

class _CompletedGamePromptState extends State<CompletedGamePrompt> {
  bool _offersFullRestart = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _offersFullRestart
                        ? 'Начать всё путешествие заново?'
                        : 'Игра уже пройдена!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.deepBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.locationName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isSubmitting ? null : widget.onClose,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Закрыть',
            ),
          ],
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.frostBlue.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.iceBlue, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _offersFullRestart
                  ? 'Герой ${widget.mentorName} предлагает снова пройти весь путь с первой льдины. Весь прогресс и снежинки будут сброшены. Начать игру заново?'
                  : 'Ты уже помог всем героям и нашёл маму. Хочешь ещё раз решить задания этого героя — ${widget.mentorName}?',
              style: const TextStyle(
                color: AppTheme.deepBlue,
                fontSize: 18,
                height: 1.35,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _confirm,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _offersFullRestart
                      ? Icons.restart_alt_rounded
                      : Icons.replay_rounded,
                ),
          label: Text(
            _isSubmitting
                ? 'Подожди…'
                : _offersFullRestart
                ? 'Да, начать заново'
                : 'Да, решить ещё раз',
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _isSubmitting ? null : _decline,
          child: Text(_offersFullRestart ? 'Нет, остаться здесь' : 'Нет'),
        ),
      ],
    );
  }

  Future<void> _confirm() async {
    setState(() => _isSubmitting = true);
    try {
      if (_offersFullRestart) {
        await widget.onRestartGame();
      } else {
        await widget.onReplayLevel();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _decline() {
    if (_offersFullRestart) {
      widget.onClose();
      return;
    }

    setState(() => _offersFullRestart = true);
  }
}
