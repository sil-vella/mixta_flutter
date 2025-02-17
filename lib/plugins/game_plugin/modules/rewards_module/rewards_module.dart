import 'package:mixta_guess_who/plugins/game_plugin/modules/rewards_module/rewardsModule_config/config.dart';
import 'package:provider/provider.dart';

import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../core/managers/state_manager.dart';
import '../../../../tools/logging/logger.dart';

class RewardsModule extends ModuleBase {
  static RewardsModule? _instance;
  final ServicesManager _servicesManager = ServicesManager();
  final ModuleManager _moduleManager = ModuleManager();

  RewardsModule._internal() {
    Logger().info('RewardsModule initialized.');
  }

  /// Factory method to ensure singleton
  factory RewardsModule() {
    _instance ??= RewardsModule._internal();
    return _instance!;
  }

  /// Get points for a specific action, applying the multiplier for the current level
  Future<int> getPoints(String key) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      Logger().error('SharedPreferences service not available.');
      return 0;
    }

    final int level = await sharedPref.callServiceMethod('getInt', ['level']) ?? 1;
    int basePoints = RewardsConfig.baseRewards[key] ?? 1;
    double multiplier = RewardsConfig.levelMultipliers[level] ?? 1.0;

    Logger().info('Calculating points for $key at level $level: Base = $basePoints, Multiplier = $multiplier');

    return (basePoints * multiplier).toInt();
  }

  /// ✅ Save Reward and Update Backend
  Future<Map<String, dynamic>> saveReward(int points) async {
    final sharedPref = _servicesManager.getService('shared_pref');
    final connectionModule = _moduleManager.getModule('connection_module');

    if (sharedPref == null || connectionModule == null) {
      Logger().error('❌ SharedPreferences or ConnectionModule service not available.');
      return {"points": 0, "endGame": false, "levelUp": false};
    }

    // ✅ Retrieve user details
    final userId = await sharedPref.callServiceMethod('getInt', ['user_id']);
    final username = await sharedPref.callServiceMethod('getString', ['username']);
    final email = await sharedPref.callServiceMethod('getString', ['email']);

    if (userId == null || username == null || email == null) {
      Logger().error("❌ Missing user details in SharedPreferences. Cannot update rewards.");
      return {"points": 0, "endGame": false, "levelUp": false};
    }

    // ✅ Retrieve selected category from SharedPreferences
    final category = await sharedPref.callServiceMethod('getString', ['category']) ?? "mixed";
    int currentLevel = await sharedPref.callServiceMethod('getInt', ['level_$category']) ?? 1;

    // ✅ Fetch current points for the selected category & level
    int currentPoints = await sharedPref.callServiceMethod('getInt', ['points_${category}_level$currentLevel']) ?? 0;
    int updatedPoints = currentPoints + points;

    // ✅ Fetch guessed names for this category & level
    String guessedKey = "guessed_${category}_level$currentLevel";
    List<String> guessedList = await sharedPref.callServiceMethod('getStringList', [guessedKey]) ?? [];

    Logger().info("📜 Current Guessed Names for $category Level $currentLevel: $guessedList");

    // ✅ Handle Leveling Up & EndGame conditions
    bool levelUp = false;
    bool endGame = false;
    String? rewardMethod = RewardsConfig.rewardSystem['method'];

    if (rewardMethod == "max_points") {
      // ✅ Check if points exceed level threshold
      double maxPoints = RewardsConfig.levelMaxPoints[currentLevel] ?? 1100;
      if (updatedPoints >= maxPoints) {
        if (RewardsConfig.levelMaxPoints.containsKey(currentLevel + 1)) {
          currentLevel += 1;
          levelUp = true;
          Logger().info("🎯 Level Up! New Level: $currentLevel");
        } else {
          endGame = true;
          Logger().info("🏆 Max level reached. Setting endGame = true.");
        }
      }
    } else if (rewardMethod == "guess_all") {
      // ✅ Check if all guesses have been made for this level
      if (RewardsConfig.levelMaxPoints.containsKey(currentLevel + 1)) {
        currentLevel += 1;
        levelUp = true;
        Logger().info("🎯 Level Up! New Level: $currentLevel");
      } else {
        endGame = true;
        Logger().info("🏆 Max level reached. Setting endGame = true.");
      }
    }

    // ✅ Update SharedPreferences with new points & level
    await sharedPref.callServiceMethod('setInt', ['points_${category}_level$currentLevel', updatedPoints]);
    await sharedPref.callServiceMethod('setInt', ['level_$category', currentLevel]);

    Logger().info("🏆 Updated Rewards: Points: $updatedPoints | Level: $currentLevel | Level Up: $levelUp | EndGame: $endGame");

    // ✅ Backend request to update rewards
    try {
      Logger().info("⚡ Sending updated rewards and guessed names to backend...");

      final response = await connectionModule.callMethod('sendPostRequest', [
        "/update-rewards",
        {
          "user_id": userId,
          "username": username,
          "email": email,
          "category": category,
          "level": currentLevel,
          "points": updatedPoints,
          "guessed_names": guessedList, // ✅ Send guessed names for the current level
        }
      ]);

      if (response != null && response.containsKey("message") && response["message"] == "Rewards updated successfully") {
        Logger().info("✅ Rewards successfully updated in backend.");
      } else {
        Logger().error("❌ Failed to update rewards in backend: ${response?["error"] ?? "Unknown error"}");
      }
    } catch (e) {
      Logger().error("❌ Error while updating rewards: $e");
    }

    return {
      "points": updatedPoints,
      "endGame": endGame,
      "levelUp": levelUp
    };
  }


}
