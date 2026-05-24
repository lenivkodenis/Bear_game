import 'package:bear_game/models/family_reward.dart';
import 'package:bear_game/services/family_reward_service.dart';
import 'package:bear_game/services/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reward is unavailable when snowflakes are below the cost', () {
    const reward = FamilyReward(
      id: 'test_reward',
      title: 'Тестовая награда',
      costSnowflakes: 50,
      description: FamilyReward.defaultDescription,
      isEnabled: true,
    );

    expect(
      FamilyRewardService().isRewardAvailable(snowflakes: 43, reward: reward),
      isFalse,
    );
  });

  test('reward is available when snowflakes reach the cost', () {
    const reward = FamilyReward(
      id: 'test_reward',
      title: 'Тестовая награда',
      costSnowflakes: 50,
      description: FamilyReward.defaultDescription,
      isEnabled: true,
    );

    expect(
      FamilyRewardService().isRewardAvailable(snowflakes: 50, reward: reward),
      isTrue,
    );
  });

  test('reward availability does not spend snowflakes automatically', () async {
    SharedPreferences.setMockInitialValues({'score': 50});
    final rewardService = FamilyRewardService();

    await rewardService.saveActiveReward(
      const FamilyReward(
        id: 'test_reward',
        title: 'Тестовая награда',
        costSnowflakes: 50,
        description: FamilyReward.defaultDescription,
        isEnabled: true,
      ),
    );

    final rewardIsAvailable = await rewardService.isActiveRewardAvailable(
      snowflakes: 50,
    );
    final progress = await ProgressService().loadProgress();

    expect(rewardIsAvailable, isTrue);
    expect(progress.score, 50);
  });

  test('default family rewards are created correctly', () {
    expect(FamilyReward.defaultRewards, hasLength(6));
    expect(
      FamilyReward.defaultRewards.map((reward) => reward.costSnowflakes),
      containsAll(<int>[50, 100, 150, 500]),
    );
    expect(
      FamilyReward.defaultRewards.map((reward) => reward.title),
      containsAll(<String>[
        '30 минут игры на приставке',
        '30 минут игры на улице',
        'Выбрать мультик вечером',
        'Семейный фильм',
        'Поход за мороженым',
        'Большая награда за прохождение всей игры',
      ]),
    );
  });

  test('custom reward is saved and loaded', () async {
    SharedPreferences.setMockInitialValues({});
    final rewardService = FamilyRewardService();
    const customReward = FamilyReward(
      id: 'custom_family_reward',
      title: 'Построить крепость из подушек',
      costSnowflakes: 75,
      description: 'Семейная договорённость на вечер.',
      isEnabled: true,
    );

    await rewardService.saveActiveReward(customReward);

    final rewards = await rewardService.loadRewards();
    final activeReward = await rewardService.loadActiveReward();

    expect(
      rewards,
      contains(
        predicate<FamilyReward>((reward) {
          return reward.id == customReward.id &&
              reward.title == customReward.title &&
              reward.costSnowflakes == customReward.costSnowflakes &&
              reward.description == customReward.description;
        }),
      ),
    );
    expect(activeReward?.id, customReward.id);
    expect(activeReward?.title, customReward.title);
  });
}
