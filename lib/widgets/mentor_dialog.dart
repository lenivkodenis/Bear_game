import 'package:flutter/material.dart';

import '../game/bear_math_game.dart';
import '../models/question_answer_result.dart';

class MentorDialog extends StatefulWidget {
  const MentorDialog({
    required this.game,
    required this.onClose,
    super.key,
  });

  final BearMathGame game;
  final VoidCallback onClose;

  @override
  State<MentorDialog> createState() => _MentorDialogState();
}

class _MentorDialogState extends State<MentorDialog> {
  bool _showIntro = true;
  bool _isSubmitting = false;
  QuestionAnswerResult? _answerResult;

  @override
  Widget build(BuildContext context) {
    final level = widget.game.currentLevel;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 12,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: level == null
                    ? _buildLoadingContent()
                    : _buildLevelContent(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLoadingContent() {
    return const [
      Text('Мудрец готовит задачу...'),
      SizedBox(height: 16),
      Center(child: CircularProgressIndicator()),
    ];
  }

  List<Widget> _buildLevelContent(BuildContext context) {
    final level = widget.game.currentLevel!;

    if (_showIntro) {
      return [
        _DialogTitle(title: level.mentorName, subtitle: level.locationName),
        const SizedBox(height: 12),
        Text(level.introText, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => setState(() => _showIntro = false),
          child: const Text('К задаче'),
        ),
      ];
    }

    if (widget.game.isLevelComplete && _answerResult == null) {
      return [
        _DialogTitle(title: level.mentorName, subtitle: level.locationName),
        const SizedBox(height: 12),
        const Text(
          'Все задачи этой льдины решены. Морская чайка показывает путь дальше.',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.onClose,
          child: const Text('Закрыть'),
        ),
      ];
    }

    final result = _answerResult;
    if (result != null && result.isCorrect) {
      return [
        _DialogTitle(title: level.mentorName, subtitle: level.locationName),
        const SizedBox(height: 12),
        Text(result.message, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: result.isLevelComplete ? widget.onClose : _showNextQuestion,
          child: Text(result.isLevelComplete ? 'Закрыть' : 'Следующий вопрос'),
        ),
      ];
    }

    final question = widget.game.currentQuestion;
    if (question == null) {
      return [
        _DialogTitle(title: level.mentorName, subtitle: level.locationName),
        const SizedBox(height: 12),
        const Text('Задачи закончились.', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: widget.onClose,
          child: const Text('Закрыть'),
        ),
      ];
    }

    return [
      _DialogTitle(
        title: level.mentorName,
        subtitle:
            'Вопрос ${widget.game.currentQuestionNumber} из ${widget.game.totalQuestions}',
      ),
      const SizedBox(height: 12),
      Text(question.questionText, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 8),
      Text(
        question.expression,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
      if (result != null && !result.isCorrect) ...[
        const SizedBox(height: 12),
        Text(
          result.message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
      const SizedBox(height: 20),
      for (final option in question.options) ...[
        FilledButton.tonal(
          onPressed: _isSubmitting ? null : () => _submitAnswer(option),
          child: Text(option.toString()),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  Future<void> _submitAnswer(int option) async {
    setState(() => _isSubmitting = true);
    final result = await widget.game.submitAnswer(option);

    if (!mounted) {
      return;
    }

    setState(() {
      _answerResult = result;
      _isSubmitting = false;
    });
  }

  void _showNextQuestion() {
    setState(() => _answerResult = null);
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      ],
    );
  }
}
