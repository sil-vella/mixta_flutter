import 'package:mixta_guess_who/plugins/game_plugin/modules/rewards_module/rewardsModule_config/config.dart';

import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';

class RewardsModule extends ModuleBase {
  static RewardsModule? _instance;
  final ServicesManager _servicesManager = ServicesManager();

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
    int basePoints = RewardsConfig.baseRewards[key] ?? 0;
    double multiplier = RewardsConfig.levelMultipliers[level] ?? 1.0;

    Logger().info('Calculating points for $key at level $level: Base = $basePoints, Multiplier = $multiplier');

    return (basePoints * multiplier).toInt();
  }

  /// Save a specific amount of earned points to SharedPreferences
  Future<int> saveReward(int points) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      Logger().error('SharedPreferences service not available.');
      return 0;
    }

    int currentPoints = await sharedPref.callServiceMethod('getInt', ['points']) ?? 0;
    int updatedPoints = currentPoints + points;

    await sharedPref.callServiceMethod('setInt', ['points', updatedPoints]);

    Logger().info("🏆 Total points updated: $updatedPoints");

    return updatedPoints;
  }
}
