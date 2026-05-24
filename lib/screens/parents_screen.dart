import 'package:flutter/material.dart';

import '../models/family_reward.dart';
import '../models/game_difficulty.dart';
import '../services/family_reward_service.dart';
import '../services/game_settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/back_text_button.dart';
import '../widgets/game_card.dart';

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  static const routeName = '/parents';

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  static const _customRewardId = 'custom_family_reward';

  final FamilyRewardService _rewardService = FamilyRewardService();
  final GameSettingsService _settingsService = GameSettingsService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _costController = TextEditingController();
  final _descriptionController = TextEditingController();

  late Future<FamilyReward?> _activeRewardFuture;
  late Future<GameDifficulty> _difficultyFuture;
  GameDifficulty _selectedDifficulty = GameDifficulty.beginner;
  String? _selectedTemplateId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _activeRewardFuture = _loadActiveReward();
    _difficultyFuture = _loadDifficulty();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<FamilyReward?> _loadActiveReward() async {
    final reward = await _rewardService.loadActiveReward();
    final activeReward = reward ?? FamilyReward.defaultRewards.first;
    _applyReward(activeReward);
    return activeReward;
  }

  Future<GameDifficulty> _loadDifficulty() async {
    final difficulty = await _settingsService.loadDifficulty();
    _selectedDifficulty = difficulty;
    return difficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackTextButton(),
        title: const Text('Родителям'),
      ),
      body: DecoratedBox(
        decoration: AppTheme.snowyGradient,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(24),
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
                _buildRewardCard(),
              ],
            ),
          ),
        ),
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
                'Сейчас выбор режима только сохраняется. Механика вопросов пока остаётся прежней: 3 варианта ответа, перемешивание и подсказки.',
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardCard() {
    return GameCard(
      child: FutureBuilder<FamilyReward?>(
        future: _activeRewardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Семейная награда',
                  style: AppTheme.sectionTitleStyle,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Настройте семейную награду за снежинки. Приложение не выдаёт награды автоматически — ребёнок показывает результат, а решение остаётся за родителями.',
                  style: AppTheme.bodyStyle,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTemplateId,
                  decoration: const InputDecoration(
                    labelText: 'Готовый шаблон',
                    border: OutlineInputBorder(),
                  ),
                  items: FamilyReward.defaultRewards
                      .map(
                        (reward) => DropdownMenuItem<String>(
                          value: reward.id,
                          child: Text(
                            '${reward.costSnowflakes} снежинок — ${reward.title}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _selectTemplate,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название награды',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите название награды';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(
                    labelText: 'Стоимость в снежинках',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final cost = int.tryParse(value ?? '');
                    if (cost == null || cost <= 0) {
                      return 'Введите число больше нуля';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание или комментарий',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _isSaving ? null : _saveReward,
                  child: Text(_isSaving ? 'Сохраняем...' : 'Сохранить награду'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectTemplate(String? rewardId) {
    if (rewardId == null) {
      return;
    }

    final reward = FamilyReward.defaultRewards.firstWhere(
      (reward) => reward.id == rewardId,
    );

    setState(() {
      _selectedTemplateId = rewardId;
      _applyReward(reward);
    });
  }

  Future<void> _selectDifficulty(GameDifficulty? difficulty) async {
    if (difficulty == null) {
      return;
    }

    setState(() => _selectedDifficulty = difficulty);
    await _settingsService.saveDifficulty(difficulty);
  }

  Future<void> _saveReward() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final reward = FamilyReward(
      id: _customRewardId,
      title: _titleController.text.trim(),
      costSnowflakes: int.parse(_costController.text),
      description: _descriptionController.text.trim(),
      isEnabled: true,
    );

    await _rewardService.saveActiveReward(reward);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedTemplateId = null;
      _isSaving = false;
      _activeRewardFuture = Future.value(reward);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Семейная награда сохранена')));
  }

  void _applyReward(FamilyReward reward) {
    _titleController.text = reward.title;
    _costController.text = reward.costSnowflakes.toString();
    _descriptionController.text = reward.description;
  }
}
