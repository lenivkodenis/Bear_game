import 'package:flutter/material.dart';

import '../models/family_reward.dart';
import '../models/game_difficulty.dart';
import '../models/round_settings.dart';
import '../services/family_reward_service.dart';
import '../services/game_settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/effects/snowfall_overlay.dart';
import '../widgets/game_card.dart';

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  static const routeName = '/parents';

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  static const _backgroundAsset =
      'public/assets/main_screen/main_screen_bear_bg.png';

  final FamilyRewardService _rewardService = FamilyRewardService();
  final GameSettingsService _settingsService = GameSettingsService();
  final _rewardFormKey = GlobalKey<FormState>();
  final _roundSettingsFormKey = GlobalKey<FormState>();
  final _maxMistakesController = TextEditingController();
  final _wrongAnswerPenaltyController = TextEditingController();

  late Future<List<FamilyReward>> _rewardsFuture;
  late Future<GameDifficulty> _difficultyFuture;
  late Future<RoundSettings> _roundSettingsFuture;
  final List<_RewardDraft> _rewardDrafts = <_RewardDraft>[];
  GameDifficulty _selectedDifficulty = GameDifficulty.beginner;
  String? _rewardError;
  bool _isSavingDifficulty = false;
  bool _isSavingRewards = false;
  bool _isResettingRewards = false;
  bool _isSavingRoundSettings = false;

  @override
  void initState() {
    super.initState();
    _rewardsFuture = _loadRewards();
    _difficultyFuture = _loadDifficulty();
    _roundSettingsFuture = _loadRoundSettings();
  }

  @override
  void dispose() {
    for (final draft in _rewardDrafts) {
      draft.dispose();
    }
    _maxMistakesController.dispose();
    _wrongAnswerPenaltyController.dispose();
    super.dispose();
  }

  Future<List<FamilyReward>> _loadRewards() async {
    final rewards = await _rewardService.loadRewards();
    _setRewardDrafts(rewards);
    return rewards;
  }

  Future<GameDifficulty> _loadDifficulty() async {
    final difficulty = await _settingsService.loadDifficulty();
    _selectedDifficulty = difficulty;
    return difficulty;
  }

  Future<RoundSettings> _loadRoundSettings() async {
    final settings = await _settingsService.loadRoundSettings();
    _applyRoundSettings(settings);
    return settings;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isCompact = screenSize.width < 760;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.snowWhite,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: const _SnowBackButton(),
        title: const Text('Родителям'),
        titleTextStyle: const TextStyle(
          color: AppTheme.snowWhite,
          fontSize: 26,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Color(0xB0001026),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _backgroundAsset,
              fit: BoxFit.cover,
              alignment: isCompact
                  ? const Alignment(-0.08, 0)
                  : Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          if (isCompact)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  _backgroundAsset,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          const Positioned.fill(
            child: IgnorePointer(
              child: SnowfallOverlay(intensity: SnowfallIntensity.medium),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    const GameCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.frostBlue,
                                child: Text(
                                  '♡',
                                  style: TextStyle(
                                    color: AppTheme.softBlue,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Родителям',
                                  style: AppTheme.screenTitleStyle,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Игра помогает ребёнку тренировать таблицу умножения через короткие уровни и добрые подсказки.',
                            style: AppTheme.bodyStyle,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'В текущей версии нет регистрации, рекламы, онлайн-платежей, аналитики и сбора персональных данных ребёнка.',
                            style: AppTheme.bodyStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDifficultyCard(),
                    const SizedBox(height: 20),
                    _buildRoundRulesCard(),
                    const SizedBox(height: 20),
                    _buildRewardCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyCard() {
    return GameCard(
      child: FutureBuilder<GameDifficulty>(
        future: _difficultyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Уровень сложности',
                style: AppTheme.sectionTitleStyle,
              ),
              const SizedBox(height: 12),
              const Text(
                'Смена сложности начинает путешествие заново. Перед сбросом прогресса игра попросит подтверждение.',
                style: AppTheme.bodyStyle,
              ),
              const SizedBox(height: 12),
              RadioGroup<GameDifficulty>(
                groupValue: _selectedDifficulty,
                onChanged: _selectDifficulty,
                child: Column(
                  children: [
                    for (final difficulty in GameDifficulty.values)
                      RadioListTile<GameDifficulty>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(difficulty.title),
                        subtitle: Text(difficulty.description),
                        value: difficulty,
                        selected: difficulty == _selectedDifficulty,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSavingDifficulty ? null : _saveDifficulty,
                child: const Text('Сохранить настройки'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardCard() {
    return GameCard(
      child: FutureBuilder<List<FamilyReward>>(
        future: _rewardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _rewardFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Семейная награда',
                  style: AppTheme.sectionTitleStyle,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Настройте список семейных наград за снежинки. Приложение не выдаёт награды автоматически — ребёнок показывает результат, а решение остаётся за родителями.',
                  style: AppTheme.bodyStyle,
                ),
                const SizedBox(height: 18),
                if (_rewardDrafts.isEmpty)
                  const Text(
                    'Добавьте хотя бы одну награду.',
                    style: AppTheme.bodyStyle,
                  )
                else
                  for (final draft in _rewardDrafts) ...[
                    _RewardEditorRow(
                      draft: draft,
                      canDelete: _rewardDrafts.length > 1,
                      onDelete: () => _deleteRewardDraft(draft),
                    ),
                    const SizedBox(height: 14),
                  ],
                if (_rewardError != null) ...[
                  Text(
                    _rewardError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: _addRewardDraft,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Добавить награду'),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSavingRewards ? null : _saveRewards,
                        child: Text(
                          _isSavingRewards ? 'Сохраняем...' : 'Сохранить',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isResettingRewards ? null : _resetRewards,
                        child: const Text('Сбросить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoundRulesCard() {
    return GameCard(
      child: FutureBuilder<RoundSettings>(
        future: _roundSettingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _roundSettingsFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Правила раунда', style: AppTheme.sectionTitleStyle),
                const SizedBox(height: 12),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF6F7880)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('Количество вопросов в раунде')),
                        Text(
                          '10',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _maxMistakesController,
                  decoration: const InputDecoration(
                    labelText: 'Сколько ошибок можно допустить',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: _requiredNonNegativeNumber,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _wrongAnswerPenaltyController,
                  decoration: const InputDecoration(
                    labelText: 'Штраф за ошибку',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _requiredPositiveNumber,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _isSavingRoundSettings ? null : _saveRoundSettings,
                  child: Text(
                    _isSavingRoundSettings
                        ? 'Сохраняем...'
                        : 'Сохранить правила',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectDifficulty(GameDifficulty? difficulty) {
    if (difficulty == null) {
      return;
    }

    setState(() => _selectedDifficulty = difficulty);
  }

  Future<void> _saveDifficulty() async {
    setState(() => _isSavingDifficulty = true);

    await _settingsService.saveDifficulty(_selectedDifficulty);
    final resetRequired = await _settingsService.isDifficultyResetRequired();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingDifficulty = false;
      _difficultyFuture = Future.value(_selectedDifficulty);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resetRequired
              ? 'Сложность изменена. Новая игра начнётся после подтверждения.'
              : 'Настройки сохранены',
        ),
      ),
    );
  }

  Future<void> _saveRewards() async {
    if (_rewardDrafts.isEmpty) {
      setState(() => _rewardError = 'Список наград не может быть пустым.');
      return;
    }

    if (!_rewardFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSavingRewards = true;
      _rewardError = null;
    });

    final rewards = _rewardDrafts.map((draft) {
      return FamilyReward(
        id: draft.id,
        title: draft.titleController.text.trim(),
        requiredSnowflakes: int.parse(draft.snowflakesController.text),
        description: FamilyReward.defaultDescription,
        isEnabled: true,
      );
    }).toList();

    await _rewardService.saveRewards(rewards);
    final savedRewards = await _rewardService.loadRewards();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingRewards = false;
      _rewardsFuture = Future.value(savedRewards);
      _setRewardDrafts(savedRewards);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Семейные награды сохранены')));
  }

  Future<void> _resetRewards() async {
    setState(() {
      _isResettingRewards = true;
      _rewardError = null;
    });

    await _rewardService.resetRewards();
    final rewards = await _rewardService.loadRewards();

    if (!mounted) {
      return;
    }

    setState(() {
      _isResettingRewards = false;
      _rewardsFuture = Future.value(rewards);
      _setRewardDrafts(rewards);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Стандартные награды восстановлены')),
    );
  }

  Future<void> _saveRoundSettings() async {
    if (!_roundSettingsFormKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSavingRoundSettings = true);

    final settings = RoundSettings(
      roundQuestionCount: RoundSettings.fixedRoundQuestionCount,
      maxMistakesPerRound: int.parse(_maxMistakesController.text),
      wrongAnswerPenalty: int.parse(_wrongAnswerPenaltyController.text),
    ).validated();

    await _settingsService.saveRoundSettings(settings);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSavingRoundSettings = false;
      _roundSettingsFuture = Future.value(settings);
      _applyRoundSettings(settings);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Правила раунда сохранены')));
  }

  void _addRewardDraft() {
    setState(() {
      _rewardError = null;
      _rewardDrafts.add(
        _RewardDraft(
          id: 'custom_reward_${DateTime.now().microsecondsSinceEpoch}',
          title: '',
          requiredSnowflakes: 10,
        ),
      );
    });
  }

  void _deleteRewardDraft(_RewardDraft draft) {
    setState(() {
      _rewardError = null;
      _rewardDrafts.remove(draft);
      draft.dispose();
    });
  }

  void _setRewardDrafts(List<FamilyReward> rewards) {
    for (final draft in _rewardDrafts) {
      draft.dispose();
    }
    _rewardDrafts
      ..clear()
      ..addAll(
        rewards.map(
          (reward) => _RewardDraft(
            id: reward.id,
            title: reward.title,
            requiredSnowflakes: reward.requiredSnowflakes,
          ),
        ),
      );
  }

  void _applyRoundSettings(RoundSettings settings) {
    _maxMistakesController.text = settings.maxMistakesPerRound.toString();
    _wrongAnswerPenaltyController.text = settings.wrongAnswerPenalty.toString();
  }

  String? _requiredPositiveNumber(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 1 || number > 100) {
      return 'Введите число от 1 до 100';
    }

    return null;
  }

  String? _requiredNonNegativeNumber(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0 || number > 100) {
      return 'Введите число от 0 до 100';
    }

    return null;
  }
}

class _RewardEditorRow extends StatelessWidget {
  const _RewardEditorRow({
    required this.draft,
    required this.canDelete,
    required this.onDelete,
  });

  final _RewardDraft draft;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: TextFormField(
            controller: draft.snowflakesController,
            decoration: const InputDecoration(
              labelText: 'Снежинки',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final snowflakes = int.tryParse(value ?? '');
              if (snowflakes == null || snowflakes < 1 || snowflakes > 100) {
                return '1-100';
              }

              return null;
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: draft.titleController,
            decoration: const InputDecoration(
              labelText: 'Текст награды',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Введите текст награды';
              }

              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: canDelete ? onDelete : null,
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Удалить награду',
        ),
      ],
    );
  }
}

class _RewardDraft {
  _RewardDraft({
    required this.id,
    required String title,
    required int requiredSnowflakes,
  }) : titleController = TextEditingController(text: title),
       snowflakesController = TextEditingController(
         text: requiredSnowflakes.toString(),
       );

  final String id;
  final TextEditingController titleController;
  final TextEditingController snowflakesController;

  void dispose() {
    titleController.dispose();
    snowflakesController.dispose();
  }
}

class _SnowBackButton extends StatelessWidget {
  const _SnowBackButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Назад',
      child: TextButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Text(
          '‹',
          style: TextStyle(
            color: AppTheme.snowWhite,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1,
            shadows: [
              Shadow(
                color: Color(0xB0001026),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
