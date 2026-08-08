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
      requiredSnowflakes: 50,
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
      requiredSnowflakes: 50,
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
        requiredSnowflakes: 50,
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
    expect(FamilyReward.defaultRewards, hasLength(7));
    expect(
      FamilyReward.defaultRewards.map((reward) => reward.requiredSnowflakes),
      orderedEquals(<int>[10, 20, 30, 40, 50, 75, 100]),
    );
    expect(
      FamilyReward.defaultRewards.map((reward) => reward.title),
      containsAll(<String>[
        'Выбрать наклейку / стикер',
        'Выбрать сказку перед сном',
        '20 минут игры на приставке',
        '30 минут игры на улице',
        'Выбрать мультфильм вечером',
        'Поход за мороженым',
        'Большая семейная награда за всю таблицу',
      ]),
    );
  });

  test('custom reward is saved and loaded', () async {
    SharedPreferences.setMockInitialValues({});
    final rewardService = FamilyRewardService();
    const customReward = FamilyReward(
      id: 'custom_family_reward',
      title: 'Построить крепость из подушек',
      requiredSnowflakes: 75,
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
              reward.requiredSnowflakes == customReward.requiredSnowflakes &&
              reward.description == customReward.description;
        }),
      ),
    );
    expect(activeReward?.id, customReward.id);
    expect(activeReward?.title, customReward.title);
  });

  test('custom rewards are saved, sorted, and loaded', () async {
    SharedPreferences.setMockInitialValues({});
    final rewardService = FamilyRewardService();

    await rewardService.saveRewards(const [
      FamilyReward(
        id: 'second',
        title: 'Вторая награда',
        requiredSnowflakes: 30,
        description: FamilyReward.defaultDescription,
        isEnabled: true,
      ),
      FamilyReward(
        id: 'first',
        title: 'Первая награда',
        requiredSnowflakes: 10,
        description: FamilyReward.defaultDescription,
        isEnabled: true,
      ),
    ]);

    final rewards = await rewardService.loadRewards();

    expect(rewards.map((reward) => reward.requiredSnowflakes), [10, 30]);
    expect(rewards.map((reward) => reward.title), [
      'Первая награда',
      'Вторая награда',
    ]);
  });

  test('reset rewards restores the default list', () async {
    SharedPreferences.setMockInitialValues({});
    final rewardService = FamilyRewardService();

    await rewardService.saveRewards(const [
      FamilyReward(
        id: 'custom',
        title: 'Своя награда',
        requiredSnowflakes: 42,
        description: FamilyReward.defaultDescription,
        isEnabled: true,
      ),
    ]);
    await rewardService.resetRewards();

    final rewards = await rewardService.loadRewards();

    expect(rewards.map((reward) => reward.toJson()), [
      for (final reward in FamilyReward.defaultRewards) reward.toJson(),
    ]);
  });

  test('damaged saved rewards restore the default list', () async {
    SharedPreferences.setMockInitialValues({'family_rewards': 'not json'});

    final rewards = await FamilyRewardService().loadRewards();

    expect(rewards.map((reward) => reward.toJson()), [
      for (final reward in FamilyReward.defaultRewards) reward.toJson(),
    ]);
  });
}
