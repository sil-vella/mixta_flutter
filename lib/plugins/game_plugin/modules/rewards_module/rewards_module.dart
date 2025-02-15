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

  /// Save a specific amount of earned points to SharedPreferences and update the backend
  Future<Map<String, dynamic>> saveReward(int points) async {
    final sharedPref = _servicesManager.getService('shared_pref');
    final connectionModule = _moduleManager.getModule('connection_module');

    if (sharedPref == null || connectionModule == null) {
      Logger().error('❌ SharedPreferences or ConnectionModule service not available.');
      return {"points": 0, "endGame": false};
    }

    // ✅ Retrieve current user details from SharedPreferences
    final userId = await sharedPref.callServiceMethod('getInt', ['user_id']);
    final username = await sharedPref.callServiceMethod('getString', ['username']);
    final email = await sharedPref.callServiceMethod('getString', ['email']);

    if (userId == null || username == null || email == null) {
      Logger().error("❌ Missing user details in SharedPreferences. Cannot update rewards.");
      return {"points": 0, "endGame": false};
    }

    // ✅ Retrieve current points and level from SharedPreferences
    int currentPoints = await sharedPref.callServiceMethod('getInt', ['points']) ?? 0;
    int currentLevel = await sharedPref.callServiceMethod('getInt', ['level']) ?? 1;
    int updatedPoints = currentPoints + points;

    // ✅ Get max points for the current level
    double maxPoints = RewardsConfig.levelMaxPoints[currentLevel] ?? 1100;
    bool endGame = false;

    if (updatedPoints >= maxPoints) {
      // ✅ Check if the next level exists
      if (RewardsConfig.levelMaxPoints.containsKey(currentLevel + 1)) {
        currentLevel += 1; // ✅ Level up
        Logger().info("🎯 Level Up! New Level: $currentLevel");
      } else {
        endGame = true; // ✅ Set endGame flag instead of calling endGame()
        Logger().info("🏆 Max level reached. Setting endGame = true.");
      }
    }

    // ✅ Update SharedPreferences with new points and level
    await sharedPref.callServiceMethod('setInt', ['points', updatedPoints]);
    await sharedPref.callServiceMethod('setInt', ['level', currentLevel]);

    Logger().info("🏆 Total points updated in SharedPreferences: $updatedPoints | Level: $currentLevel | endGame: $endGame");

    // ✅ Backend request in try-catch (ensures return even if error)
    try {
      Logger().info("⚡ Sending updated rewards to backend...");

      final response = await connectionModule.callMethod('sendPostRequest', [
        "/update-rewards",
        {
          "user_id": userId,
          "username": username,
          "email": email,
          "points": updatedPoints,
          "level": currentLevel,
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

    // ✅ Return both updated points and the endGame flag
    return {
      "points": updatedPoints,
      "endGame": endGame
    };
  }


}
