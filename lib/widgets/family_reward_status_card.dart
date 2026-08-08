import 'package:flutter/material.dart';

import '../models/family_reward.dart';
import '../services/family_reward_service.dart';
import '../theme/app_theme.dart';
import 'game_card.dart';
import 'north_sign_button.dart';
import 'primary_game_button.dart';

class FamilyRewardStatusCard extends StatelessWidget {
  const FamilyRewardStatusCard({
    required this.snowflakes,
    required this.onOpenMap,
    super.key,
  });

  final int snowflakes;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FamilyReward>>(
      future: FamilyRewardService().loadRewards(),
      builder: (context, snapshot) {
        final rewards = snapshot.data ?? const <FamilyReward>[];
        final reward = _rewardForScore(rewards);
        if (reward == null) {
          return const SizedBox.shrink();
        }

        final rewardIsAvailable =
            snowflakes >= reward.costSnowflakes && reward.isEnabled;
        final remainingSnowflakes = reward.costSnowflakes - snowflakes;

        return GameCard(
          backgroundColor: rewardIsAvailable
              ? AppTheme.paleGreen
              : AppTheme.snowWhite,
          borderColor: rewardIsAvailable
              ? AppTheme.gentleGreen
              : AppTheme.iceBlue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                rewardIsAvailable ? 'Награда доступна!' : 'Семейная награда',
                textAlign: TextAlign.center,
                style: AppTheme.sectionTitleStyle,
              ),
              const SizedBox(height: 12),
              Text(
                rewardIsAvailable
                    ? 'Ты накопил $snowflakes снежинок.\nНаграда: ${reward.title}.\nПокажи этот экран родителям.'
                    : 'Ты заработал $snowflakes снежинок.\nДо награды осталось $remainingSnowflakes снежинок.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle,
              ),
              if (reward.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  reward.description,
                  textAlign: TextAlign.center,
                  style: AppTheme.helperStyle,
                ),
              ],
              if (rewardIsAvailable) ...[
                const SizedBox(height: 16),
                PrimaryGameButton(
                  icon: Icons.family_restroom_rounded,
                  symbol: '♡',
                  tone: NorthSignTone.aurora,
                  snowCap: SnowCapVariant.doubleDrift,
                  onPressed: () => _showParentsDialog(context, reward),
                  label: 'Показать родителям',
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  FamilyReward? _rewardForScore(List<FamilyReward> rewards) {
    final enabledRewards = rewards.where((reward) => reward.isEnabled).toList()
      ..sort(
        (left, right) =>
            left.requiredSnowflakes.compareTo(right.requiredSnowflakes),
      );
    if (enabledRewards.isEmpty) {
      return null;
    }

    FamilyReward? availableReward;
    for (final reward in enabledRewards) {
      if (snowflakes >= reward.requiredSnowflakes) {
        availableReward = reward;
      }
    }
    if (availableReward != null) {
      return availableReward;
    }

    for (final reward in enabledRewards) {
      if (snowflakes < reward.requiredSnowflakes) {
        return reward;
      }
    }

    return enabledRewards.last;
  }

  void _showParentsDialog(BuildContext context, FamilyReward reward) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Покажи родителям'),
          content: Text(
            'Накоплено снежинок: $snowflakes\n'
            'Награда: ${reward.title}\n\n'
            'Покажи этот экран родителям, чтобы они подтвердили семейную награду.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Понятно'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOpenMap();
              },
              child: const Text('На карту'),
            ),
          ],
        );
      },
    );
  }
}
