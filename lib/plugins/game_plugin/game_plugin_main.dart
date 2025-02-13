import 'package:mixta_guess_who/plugins/game_plugin/modules/leaderboard_module/leaderboard_module.dart';
import 'package:mixta_guess_who/plugins/game_plugin/modules/rewards_module/rewards_module.dart';
import 'package:mixta_guess_who/plugins/game_plugin/screens/game_screen/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:mixta_guess_who/plugins/game_plugin/screens/leaderboard_screen/leaderboard_screen.dart';

import '../../core/00_base/plugin_base.dart';
import '../../core/managers/hooks_manager.dart';
import '../../core/managers/module_manager.dart';
import '../../core/managers/navigation_manager.dart';
import '../../core/managers/services_manager.dart';
import '../../core/managers/state_manager.dart';
import '../../tools/logging/logger.dart';
import 'modules/question_module/question_module.dart';

class GamePlugin extends PluginBase {
  final ServicesManager servicesManager;
  final StateManager stateManager; // ✅ Add StateManager

  GamePlugin(
      HooksManager hooksManager,
      ModuleManager moduleManager,
      NavigationContainer navigationContainer,
      this.stateManager) // ✅ Pass StateManager
      : servicesManager = ServicesManager(),
        super(hooksManager, moduleManager) {
    moduleMap.addAll({
      'question_module': () => QuestionModule(),
      'rewards_module': () => RewardsModule(),
      'leaderboard_module': () => LeaderboardModule(),
    });

    hookMap.addAll({
      'app_startup': () {
        Logger().info('GamePlugin initialized.');
        _initializeUserData(); // Initialize user data on startup
        _registerGameTimerState(); // ✅ Register game timer state
      },
      'reg_nav': () {
        navigationContainer.registerRoute('/game', (context) => GameScreen());
        navigationContainer.registerNavItem(DrawerItem(
          label: 'Guess Who',
          route: '/game',
          icon: Icons.quiz,
        ));
        navigationContainer.registerRoute('/leaderboard', (context) => LeaderboardScreen());
        navigationContainer.registerNavItem(DrawerItem(
          label: 'Leaderboard',
          route: '/leaderboard',
          icon: Icons.quiz,
        ));
      },
    });
  }

  /// ✅ Define initial states for this plugin
  @override
  Map<String, Map<String, dynamic>> getInitialStates() {
    return {
      "game_timer": {
        "isRunning": false,
        "duration": 30, // Default duration
      },
      "game_progress": {
        "currentLevel": 1,
        "score": 0,
      }
    };
  }

  /// ✅ Register game timer state in StateManager
  void _registerGameTimerState() {
    if (!stateManager.isPluginStateRegistered("game_timer")) {
      stateManager.registerPluginState("game_timer", {
        "isRunning": false,
        "duration": 30, // Default duration
      });

      Logger().info("✅ Game timer state registered.");
    }
  }

  /// Initialize user data in Shared Preferences
  Future<void> _initializeUserData() async {
    final sharedPref = servicesManager.getService('shared_pref');

    if (sharedPref != null) {
      await sharedPref.callServiceMethod('setString', ['username', 'Guest']);
      await sharedPref.callServiceMethod('setString', ['email', '']);
      await sharedPref.callServiceMethod('setString', ['password', '']);
      await sharedPref.callServiceMethod('setInt', ['points', 0]);
      await sharedPref.callServiceMethod('setInt', ['level', 1]); // ✅ Start at level 1

      Logger().info('✅ User data initialized in Shared Preferences.');
    } else {
      Logger().error('❌ SharedPrefManager not found.');
    }
  }
}
