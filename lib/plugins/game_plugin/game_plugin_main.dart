import 'package:flush_me_im_famous/plugins/game_plugin/modules/rewards_module/rewards_module.dart';
import 'package:flush_me_im_famous/plugins/game_plugin/screens/game_screen/game_screen.dart';
import 'package:flutter/material.dart';

import '../../core/00_base/plugin_base.dart';
import '../../core/managers/hooks_manager.dart';
import '../../core/managers/module_manager.dart';
import '../../core/managers/navigation_manager.dart';
import '../../core/managers/services_manager.dart';
import '../../tools/logging/logger.dart';
import 'modules/question_module/question_module.dart';

class GamePlugin extends PluginBase {
  final ServicesManager servicesManager;

  GamePlugin(
      HooksManager hooksManager, ModuleManager moduleManager, NavigationContainer navigationContainer)
      : servicesManager = ServicesManager(),
        super(hooksManager, moduleManager) {
    moduleMap.addAll({
      'question_module': () => QuestionModule(),
      'rewards_module': () => RewardsModule(),

    });

    hookMap.addAll({
      'app_startup': () {
        Logger().info('GamePlugin initialized.');
        _initializeUserData(); // Initialize user data on startup
      },
      'reg_nav': () {
        navigationContainer.registerRoute('/game', (context) => GameScreen());
        navigationContainer.registerNavItem(DrawerItem(
          label: 'Guess the Actor',
          route: '/game',
          icon: Icons.quiz,
        ));
      },
    });
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
