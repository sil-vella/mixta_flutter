import 'package:flush_me_im_famous/core/managers/navigation_manager.dart';
import 'package:flush_me_im_famous/plugins/main_plugin/modules/animations_module/animations_module.dart';
import 'package:flush_me_im_famous/plugins/main_plugin/modules/main_helper_module/main_helper_module.dart';
import 'package:flush_me_im_famous/plugins/main_plugin/screens/home_screen.dart';
import 'package:flush_me_im_famous/plugins/main_plugin/screens/preferences_screen.dart';
import 'package:flutter/material.dart';
import '../../core/00_base/plugin_base.dart';
import '../../core/managers/module_manager.dart';
import '../../core/managers/hooks_manager.dart';
import '../../tools/logging/logger.dart';
import '../../utils/consts/config.dart';
import 'modules/connections_module/connections_module.dart';

class MainPlugin extends PluginBase {
  MainPlugin(HooksManager hooksManager, ModuleManager moduleManager, NavigationContainer navigationContainer)
      : super(hooksManager, moduleManager) {
    moduleMap.addAll({
      'connection_module': () => ConnectionsModule(Config.apiUrl),
      'animations_module': () => AnimationsModule(),
      'main_helper_module': () => MainHelperModule(),
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
        ));

        navigationContainer.registerNavItem(DrawerItem(
          label: 'Preferences',
          route: '/preferences',
          icon: Icons.settings,
        ));

        Logger().info('MainPlugin: Navigation items registered.');
      },
    });


    Logger().info('MainPlugin instance created.');
  }

  @override
  void initialize() {
    super.initialize();
    Logger().info('MainPlugin initialized.');
  }

  @override
  void dispose() {
    super.dispose();
    Logger().info('MainPlugin disposed.');
  }
}
