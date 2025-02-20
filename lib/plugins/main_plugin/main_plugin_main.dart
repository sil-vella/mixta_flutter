import 'package:mixta_guess_who/core/managers/navigation_manager.dart';
import 'package:mixta_guess_who/plugins/main_plugin/modules/animations_module/animations_module.dart';
import 'package:mixta_guess_who/plugins/main_plugin/modules/login_module/login_module.dart';
import 'package:mixta_guess_who/plugins/main_plugin/modules/main_helper_module/main_helper_module.dart';
import 'package:mixta_guess_who/plugins/main_plugin/screens/home_screen.dart';
import 'package:mixta_guess_who/plugins/main_plugin/screens/preferences_screen/preferences_screen.dart';
import 'package:flutter/material.dart';
import '../../core/00_base/plugin_base.dart';
import '../../core/managers/module_manager.dart';
import '../../core/managers/hooks_manager.dart';
import '../../core/managers/services_manager.dart';
import '../../core/managers/state_manager.dart';
import '../../tools/logging/logger.dart';
import '../../utils/consts/config.dart';
import 'modules/connections_module/connections_module.dart';

class MainPlugin extends PluginBase {
  final ServicesManager servicesManager;
  final StateManager stateManager; // ✅ Add StateManager

  MainPlugin(HooksManager hooksManager, ModuleManager moduleManager, NavigationContainer navigationContainer,
  this.stateManager) // ✅ Pass StateManager
      : servicesManager = ServicesManager(),
  super(hooksManager, moduleManager) {
    moduleMap.addAll({
      'connection_module': () => ConnectionsModule(Config.apiUrl),
      'animations_module': () => AnimationsModule(),
      'main_helper_module': () => MainHelperModule(),
      'login_module': () => LoginModule(),
    });

    // Add hooks directly in hookMap
    hookMap.addAll({
      'app_startup': () {
        Logger().info('MainPlugin: app_startup hook triggered.');
      },
      'reg_nav': () {
        navigationContainer.registerRoute('/', (context) => HomeScreen());
        navigationContainer.registerRoute('/preferences', (context) => PreferencesScreen());

        navigationContainer.registerNavItem(DrawerItem(
          label: 'Home',
          route: '/',
          icon: Icons.home,
        ), position: 0);

        navigationContainer.registerNavItem(DrawerItem(
          label: 'Profile',
          route: '/preferences',
          icon: Icons.settings,
        ), position: 2);

        Logger().info('MainPlugin: Navigation items registered.');
      },
    });


    Logger().info('MainPlugin instance created.');
  }

  /// ✅ Define initial states for this plugin
  @override
  Map<String, Map<String, dynamic>> getInitialStates() {
    return {

    };
  }

  @override
  void dispose() {
    super.dispose();
    Logger().info('MainPlugin disposed.');
  }
}
