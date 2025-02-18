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
  /// Get points for a specific action, applying the multiplier for the provided level
  Future<int> getPoints(String key, String category, int level) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      Logger().error('SharedPreferences service not available.');
      return 0;
    }

    // ✅ Fetch the base points using `key`, since `category` is not used in `baseRewards`
    int basePoints = RewardsConfig.baseRewards[key] ?? 1;

    // ✅ Fetch the level multiplier based on the provided level
    double multiplier = RewardsConfig.levelMultipliers[level] ?? 1.0;

    Logger().info('Calculating points for $key at level $level: Base = $basePoints, Multiplier = $multiplier');

    return (basePoints * multiplier).toInt();
  }

  /// ✅ Save Reward and Update Backend
  Future<Map<String, dynamic>> saveReward({
    required int points,
    required String category,
    required int level,
    required String guessedActor,
  }) async {
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

    // ✅ Retrieve current level & points
    int currentLevel = level;
    int previousPoints = await sharedPref.callServiceMethod('getInt', ['points_${category}_level$currentLevel']) ?? 0;
    int updatedPoints = previousPoints + points;


    // ✅ Fetch guessed names for this level
    String guessedKey = "guessed_${category}_level$currentLevel";
    List<String> guessedList = await sharedPref.callServiceMethod('getStringList', [guessedKey]) ?? [];

    if (!guessedList.contains(guessedActor)) {
      guessedList.add(guessedActor);
      await sharedPref.callServiceMethod('setStringList', [guessedKey, guessedList]);
      Logger().info("📜 Updated guessed names for $category Level $currentLevel: $guessedList");
    }

    // ✅ Backend request to update rewards
    Map<String, dynamic> response = {};
    try {
      Logger().info("⚡ Sending updated rewards to backend...");

      response = await connectionModule.callMethod('sendPostRequest', [
        "/update-rewards",
        {
          "user_id": userId,
          "username": username,
          "email": email,
          "category": category,
          "level": currentLevel,
          "points": updatedPoints,
          "guessed_names": guessedList,
        }
      ]);

      Logger().info("✅ Response from backend: $response");

      if (response == null || !response.containsKey("message")) {
        Logger().error("❌ Invalid response from backend.");
        return {"points": updatedPoints, "endGame": false, "levelUp": false};
      }

      if (response["message"] != "Rewards updated successfully") {
        Logger().error("❌ Backend error: ${response["error"] ?? "Unknown error"}");
        return {"points": updatedPoints, "endGame": false, "levelUp": false};
      }
    } catch (e) {
      Logger().error("❌ Error while updating rewards: $e");
      return {"points": updatedPoints, "endGame": false, "levelUp": false};
    }

    // ✅ Update SharedPreferences based on backend response
    bool levelUp = response["levelUp"] ?? false;
    bool endGame = response["endGame"] ?? false;
    int newLevel = levelUp ? currentLevel + 1 : currentLevel;

    await sharedPref.callServiceMethod('setInt', ['points_${category}_level$currentLevel', updatedPoints]);
    await sharedPref.callServiceMethod('setInt', ['level_$category', newLevel]);

    Logger().info("🏆 Updated Rewards: Points: $updatedPoints | Level: $newLevel | Level Up: $levelUp | EndGame: $endGame");

    return {
      "points": updatedPoints,
      "endGame": endGame,
      "levelUp": levelUp
    };
  }

}
