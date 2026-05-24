import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/bear_math_game.dart';
import '../models/game_difficulty.dart';
import '../models/question_answer_result.dart';
import '../theme/app_theme.dart';
import 'game_card.dart';
import 'primary_game_button.dart';

class MentorDialog extends StatefulWidget {
  const MentorDialog({
    required this.game,
    required this.onClose,
    required this.onLevelComplete,
    super.key,
  });

  final BearMathGame game;
  final VoidCallback onClose;
  final VoidCallback onLevelComplete;

  @override
  State<MentorDialog> createState() => _MentorDialogState();
}

class _MentorDialogState extends State<MentorDialog> {
  bool _showIntro = true;
  bool _isSubmitting = false;
  QuestionAnswerResult? _answerResult;
  final TextEditingController _numericAnswerController =
      TextEditingController();

  @override
  void dispose() {
    _numericAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.game.currentLevel;
    final canOpenQuestion = level != null && _showIntro;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: canOpenQuestion
                ? () => setState(() => _showIntro = false)
                : null,
            child: GameCard(
              borderColor: _answerResult == null
                  ? AppTheme.iceBlue
                  : _answerResult!.isCorrect
                  ? AppTheme.gentleGreen
                  : AppTheme.softCoral,
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
        Text(level.introText, style: AppTheme.bodyStyle),
        const SizedBox(height: 20),
        PrimaryGameButton(
          icon: Icons.calculate_rounded,
          symbol: '×',
          label: 'К задаче',
          onPressed: () => setState(() => _showIntro = false),
        ),
      ];
    }

    if (widget.game.isLevelComplete && _answerResult == null) {
      return [
        _DialogTitle(title: level.mentorName, subtitle: level.locationName),
        const SizedBox(height: 12),
        const Text(
          'Все задачи этой льдины решены. Морская чайка показывает путь дальше.',
          style: AppTheme.bodyStyle,
        ),
        const SizedBox(height: 20),
        PrimaryGameButton(
          icon: Icons.check_rounded,
          symbol: '✓',
          label: 'Закрыть',
          onPressed: widget.onClose,
        ),
      ];
    }

    final result = _answerResult;
    if (result != null && result.isCorrect) {
      return [
        _DialogTitle(title: level.mentorName, subtitle: level.locationName),
        const SizedBox(height: 12),
        _FeedbackBox(result: result),
        const SizedBox(height: 20),
        PrimaryGameButton(
          icon: result.isLevelComplete
              ? Icons.emoji_events_rounded
              : Icons.arrow_forward_rounded,
          symbol: result.isLevelComplete ? '★' : '›',
          label: result.isLevelComplete ? 'К итогам' : 'Следующий вопрос',
          onPressed: result.isLevelComplete
              ? widget.onLevelComplete
              : _showNextQuestion,
        ),
      ];
    }

    final question = widget.game.currentQuestion;
    if (question == null) {
      return [
        _DialogTitle(title: level.mentorName, subtitle: level.locationName),
        const SizedBox(height: 12),
        const Text('Задачи закончились.', style: AppTheme.bodyStyle),
        const SizedBox(height: 20),
        PrimaryGameButton(
          icon: Icons.check_rounded,
          symbol: '✓',
          label: 'Закрыть',
          onPressed: widget.onClose,
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
      DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.frostBlue,
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          border: Border.all(color: AppTheme.iceBlue),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(
                question.questionText,
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle,
              ),
              const SizedBox(height: 8),
              Text(
                question.expression,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.deepBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
      if (result != null && !result.isCorrect) ...[
        const SizedBox(height: 12),
        _FeedbackBox(result: result),
      ],
      const SizedBox(height: 20),
      if (widget.game.difficulty == GameDifficulty.expert)
        ..._buildNumericAnswerContent()
      else
        for (final option in widget.game.currentAnswerOptions) ...[
          PrimaryGameButton(
            icon: Icons.panorama_fish_eye_rounded,
            symbol: '•',
            label: option.toString(),
            secondary: true,
            onPressed: _isSubmitting ? null : () => _submitAnswer(option),
          ),
          const SizedBox(height: 8),
        ],
    ];
  }

  List<Widget> _buildNumericAnswerContent() {
    return [
      TextField(
        controller: _numericAnswerController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        enabled: !_isSubmitting,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.deepBlue,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppTheme.snowWhite,
          hintText: 'Ответ',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
        ),
        onSubmitted: (_) => _submitNumericAnswer(),
      ),
      const SizedBox(height: 12),
      PrimaryGameButton(
        icon: Icons.check_rounded,
        symbol: '✓',
        label: 'Проверить',
        onPressed: _isSubmitting ? null : _submitNumericAnswer,
      ),
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

  Future<void> _submitNumericAnswer() async {
    setState(() => _isSubmitting = true);
    final result = await widget.game.submitNumericAnswer(
      _numericAnswerController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _answerResult = result;
      _isSubmitting = false;
    });
  }

  void _showNextQuestion() {
    setState(() {
      _answerResult = null;
      _numericAnswerController.clear();
    });
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: AppTheme.frostBlue,
          child: Text(
            '✦',
            style: TextStyle(
              color: AppTheme.softBlue,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.deepBlue,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTheme.helperStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  const _FeedbackBox({required this.result});

  final QuestionAnswerResult result;

  @override
  Widget build(BuildContext context) {
    final isCorrect = result.isCorrect;
    final color = isCorrect ? AppTheme.gentleGreen : AppTheme.softCoral;
    final backgroundColor = isCorrect ? AppTheme.paleGreen : AppTheme.paleCoral;
    final symbol = isCorrect ? '✓' : '!';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              symbol,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                result.message,
                style: const TextStyle(
                  color: AppTheme.deepBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
