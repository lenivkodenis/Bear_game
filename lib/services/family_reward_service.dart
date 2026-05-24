import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/family_reward.dart';

class FamilyRewardService {
  static const _rewardsKey = 'family_rewards';
  static const _activeRewardIdKey = 'active_family_reward_id';

  Future<List<FamilyReward>> loadRewards() async {
    final preferences = await SharedPreferences.getInstance();
    final storedRewards = preferences.getString(_rewardsKey);
    if (storedRewards == null) {
      return FamilyReward.defaultRewards;
    }

    final decodedRewards = jsonDecode(storedRewards) as List<Object?>;
    return decodedRewards
        .cast<Map<String, Object?>>()
        .map(FamilyReward.fromJson)
        .toList();
  }

  Future<void> saveRewards(List<FamilyReward> rewards) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _rewardsKey,
      jsonEncode(rewards.map((reward) => reward.toJson()).toList()),
    );
  }

  Future<FamilyReward?> loadActiveReward() async {
    final preferences = await SharedPreferences.getInstance();
    final activeRewardId = preferences.getString(_activeRewardIdKey);
    final rewards = await loadRewards();

    if (activeRewardId != null) {
      for (final reward in rewards) {
        if (reward.id == activeRewardId && reward.isEnabled) {
          return reward;
        }
      }
    }

    for (final reward in rewards) {
      if (reward.isEnabled) {
        return reward;
      }
    }

    return null;
  }

  Future<void> selectActiveReward(String rewardId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_activeRewardIdKey, rewardId);
  }

  Future<void> saveActiveReward(FamilyReward reward) async {
    final rewards = await loadRewards();
    final updatedRewards = <FamilyReward>[];
    var rewardWasUpdated = false;

    for (final currentReward in rewards) {
      if (currentReward.id == reward.id) {
        updatedRewards.add(reward);
        rewardWasUpdated = true;
      } else {
        updatedRewards.add(currentReward);
      }
    }

    if (!rewardWasUpdated) {
      updatedRewards.add(reward);
    }

    await saveRewards(updatedRewards);
    await selectActiveReward(reward.id);
  }

  Future<void> disableReward(String rewardId) async {
    final rewards = await loadRewards();
    await saveRewards(
      rewards
          .map(
            (reward) => reward.id == rewardId
                ? reward.copyWith(isEnabled: false)
                : reward,
          )
          .toList(),
    );
  }

  bool isRewardAvailable({
    required int snowflakes,
    required FamilyReward reward,
  }) {
    return reward.isEnabled && snowflakes >= reward.costSnowflakes;
  }

  Future<bool> isActiveRewardAvailable({required int snowflakes}) async {
    final reward = await loadActiveReward();
    if (reward == null) {
      return false;
    }

    return isRewardAvailable(snowflakes: snowflakes, reward: reward);
  }
}
