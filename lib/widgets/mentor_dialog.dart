import 'package:flutter/material.dart';

import '../game/bear_math_game.dart';
import '../models/game_difficulty.dart';
import '../models/question.dart';
import '../models/question_answer_result.dart';

class MentorDialog extends StatefulWidget {
  const MentorDialog({
    required this.game,
    required this.onClose,
    required this.onLevelComplete,
    required this.onReturnToMap,
    super.key,
  });

  final BearMathGame game;
  final VoidCallback onClose;
  final VoidCallback onLevelComplete;
  final VoidCallback onReturnToMap;

  @override
  State<MentorDialog> createState() => _MentorDialogState();
}

class _MentorDialogState extends State<MentorDialog> {
  bool _showIntro = true;
  bool _isSubmitting = false;
  QuestionAnswerResult? _answerResult;
  int? _orderedQuestionId;
  GameDifficulty? _orderedDifficulty;
  List<int> _orderedOptions = const [];
  final TextEditingController _manualAnswerController = TextEditingController();

  @override
  void dispose() {
    _manualAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.game.currentLevel;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: SafeArea(
        minimum: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 480 || constraints.maxHeight < 620;
            final ultraShort =
                constraints.maxWidth > constraints.maxHeight &&
                constraints.maxHeight < 360;
            final outerPadding = ultraShort
                ? 2.0
                : compact
                ? 6.0
                : 16.0;
            final innerPadding = ultraShort
                ? 10.0
                : compact
                ? 16.0
                : 24.0;
            final children = level == null
                ? _buildLoadingContent()
                : _buildLevelContent(context, ultraShort: ultraShort);
            final pinnedCount = _pinnedActionCount();
            final title = children.firstOrNull;
            final contentStart = title is _DialogTitle ? 1 : 0;
            final contentEnd = (children.length - pinnedCount)
                .clamp(contentStart, children.length)
                .toInt();
            final scrollingChildren = children.sublist(
              contentStart,
              contentEnd,
            );
            final pinnedChildren = children.sublist(contentEnd);

            return Center(
              child: Padding(
                padding: EdgeInsets.all(outerPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ultraShort ? 760 : 420,
                    maxHeight: constraints.maxHeight - outerPadding * 2,
                  ),
                  child: Card(
                    elevation: 12,
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: EdgeInsets.all(innerPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (title is _DialogTitle) title,
                          if (title is _DialogTitle) const Divider(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: scrollingChildren,
                              ),
                            ),
                          ),
                          if (pinnedChildren.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ...pinnedChildren,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _pinnedActionCount() {
    final result = _answerResult;
    if (_showIntro ||
        (widget.game.isLevelComplete && result == null) ||
        (result != null && result.isCorrect) ||
        (!_showIntro && widget.game.currentQuestion == null)) {
      return 1;
    }
    if (result != null && result.requiresRestart) return 3;
    return 0;
  }

  List<Widget> _buildLoadingContent() {
    return const [
      Text('Мудрец готовит задачу...'),
      SizedBox(height: 16),
      Center(child: CircularProgressIndicator()),
    ];
  }

  List<Widget> _buildLevelContent(
    BuildContext context, {
    required bool ultraShort,
  }) {
    final level = widget.game.currentLevel!;

    if (_showIntro) {
      return [
        _DialogTitle(
          title: level.mentorName,
          subtitle: level.locationName,
          onClose: widget.onClose,
        ),
        const SizedBox(height: 12),
        Text(level.introText, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        FilledButton(onPressed: _startQuestions, child: const Text('К задаче')),
      ];
    }

    if (widget.game.isLevelComplete && _answerResult == null) {
      return [
        _DialogTitle(
          title: level.mentorName,
          subtitle: level.locationName,
          onClose: widget.onClose,
        ),
        const SizedBox(height: 12),
        const Text(
          'Все задачи этой льдины решены. Морская чайка показывает путь дальше.',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: widget.onClose, child: const Text('Закрыть')),
      ];
    }

    final result = _answerResult;
    if (result != null && result.requiresRestart) {
      return [
        _DialogTitle(
          title: 'Попробуем ещё раз?',
          subtitle: level.locationName,
          onClose: widget.onClose,
        ),
        const SizedBox(height: 12),
        Text(result.message, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _restartRound,
          child: const Text('Начать заново'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: widget.onReturnToMap,
          child: const Text('Вернуться на карту'),
        ),
      ];
    }

    if (result != null && result.isCorrect) {
      return [
        _DialogTitle(
          title: level.mentorName,
          subtitle: level.locationName,
          onClose: widget.onClose,
        ),
        const SizedBox(height: 12),
        Text(result.message, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: result.isLevelComplete
              ? widget.onLevelComplete
              : _showNextQuestion,
          child: Text(result.isLevelComplete ? 'К итогам' : 'Следующий вопрос'),
        ),
      ];
    }

    final question = widget.game.currentQuestion;
    if (question == null) {
      return [
        _DialogTitle(
          title: level.mentorName,
          subtitle: level.locationName,
          onClose: widget.onClose,
        ),
        const SizedBox(height: 12),
        const Text('Задачи закончились.', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        FilledButton(onPressed: widget.onClose, child: const Text('Закрыть')),
      ];
    }

    return [
      _DialogTitle(
        title: level.mentorName,
        subtitle:
            'Вопрос ${widget.game.currentQuestionNumber} из ${widget.game.totalQuestions}',
        onClose: widget.onClose,
      ),
      const SizedBox(height: 12),
      Text(question.questionText, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 8),
      Text(
        question.expression,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
      if (widget.game.isManualAnswerMode)
        _buildManualAnswerInput()
      else if (ultraShort)
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final option in _optionsFor(question))
              SizedBox(
                width: 112,
                height: 44,
                child: FilledButton.tonal(
                  onPressed: _isSubmitting ? null : () => _submitAnswer(option),
                  child: Text(option.toString()),
                ),
              ),
          ],
        )
      else
        for (final option in _optionsFor(question)) ...[
          FilledButton.tonal(
            onPressed: _isSubmitting ? null : () => _submitAnswer(option),
            child: Text(option.toString()),
          ),
          const SizedBox(height: 8),
        ],
    ];
  }

  List<int> _optionsFor(Question question) {
    if (_orderedQuestionId != question.id ||
        _orderedDifficulty != widget.game.difficulty) {
      _orderedQuestionId = question.id;
      _orderedDifficulty = widget.game.difficulty;
      _orderedOptions = widget.game.answerOptionsFor(question);
    }

    return _orderedOptions;
  }

  Widget _buildManualAnswerInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _manualAnswerController,
          enabled: !_isSubmitting,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Ответ',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitManualAnswer(),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: _isSubmitting ? null : _submitManualAnswer,
          child: Text(_isSubmitting ? 'Проверяем...' : 'Ответить'),
        ),
      ],
    );
  }

  Future<void> _submitManualAnswer() async {
    final answer = int.tryParse(_manualAnswerController.text.trim());
    if (answer == null) {
      setState(() {
        _answerResult = QuestionAnswerResult(
          isCorrect: false,
          message: 'Введите число.',
          score: widget.game.scoreNotifier.value,
          isLevelComplete: false,
        );
      });
      return;
    }

    await _submitAnswer(answer);
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

  Future<void> _restartRound() async {
    setState(() => _isSubmitting = true);
    await widget.game.restartRound();

    if (!mounted) {
      return;
    }

    setState(() {
      _showIntro = false;
      _answerResult = null;
      _isSubmitting = false;
      _orderedQuestionId = null;
      _orderedDifficulty = null;
      _orderedOptions = const [];
      _manualAnswerController.clear();
    });
    widget.game.startQuestionTimer();
  }

  void _showNextQuestion() {
    setState(() {
      _answerResult = null;
      _orderedQuestionId = null;
      _orderedDifficulty = null;
      _orderedOptions = const [];
      _manualAnswerController.clear();
    });
    widget.game.startQuestionTimer();
  }

  void _startQuestions() {
    setState(() => _showIntro = false);
    widget.game.startQuestionTimer();
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Закрыть',
        ),
      ],
    );
  }
}
