import 'package:mixta_guess_who/plugins/game_plugin/modules/function_helper_module/function_helper_module.dart';
import 'package:mixta_guess_who/plugins/game_plugin/modules/leaderboard_module/leaderboard_module.dart';
import 'package:mixta_guess_who/plugins/game_plugin/modules/rewards_module/rewards_module.dart';
import 'package:mixta_guess_who/plugins/game_plugin/screens/game_screen/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:mixta_guess_who/plugins/game_plugin/screens/leaderboard_screen/leaderboard_screen.dart';
import 'package:mixta_guess_who/plugins/game_plugin/screens/level_up_screen/level_up_screen.dart';
import 'package:mixta_guess_who/plugins/game_plugin/screens/progress_screen/progress_screen.dart';

import '../../core/00_base/plugin_base.dart';
import '../../core/managers/hooks_manager.dart';
import '../../core/managers/module_manager.dart';
import '../../core/managers/navigation_manager.dart';
import '../../core/managers/services_manager.dart';
import '../../core/managers/state_manager.dart';
import '../../tools/logging/logger.dart';
import '../main_plugin/modules/connections_module/connections_module.dart';
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
      'functions_helper_module': () => FunctionHelperModule(),
    });

    hookMap.addAll({
      'app_startup': () async {
        Logger().info('GamePlugin initialized.');
        await getCategories(); // ✅ Fetch categories FIRST
        await _initializeUserData(); // ✅ Initialize user data AFTER fetching categories
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
        navigationContainer.registerRoute('/progress', (context) => ProgressScreen());
        navigationContainer.registerNavItem(DrawerItem(
          label: 'My Progress',
          route: '/progress',
          icon: Icons.quiz,
        ));
        navigationContainer.registerRoute('/level-up', (context) => LevelUpScreen());
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
      "game_round": {
        "roundNumber": 0,
        "hint": false,
        "imagesLoaded": false,
        "factLoaded": false,
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


  Future<void> getCategories() async {
    final connectionModule = ModuleManager().getModule<ConnectionsModule>('connection_module');
    final sharedPref = ServicesManager().getService('shared_pref');

    if (connectionModule == null) {
      Logger().error('❌ ConnectionModule not found in ServicesManager.');
      return;
    }

    if (sharedPref == null) {
      Logger().error('❌ SharedPreferences service not available.');
      return;
    }

    try {
      Logger().info('⚡ Sending GET request to `/get-categories`...');
      final response = await connectionModule.sendGetRequest('/get-categories');

      if (response != null && response is Map<String, dynamic> && response.containsKey("categories")) {
        final Map<String, dynamic> categoriesMap = response["categories"];

        // ✅ Extract category names from the response
        List<String> categoryList = categoriesMap.keys.toList();

        Logger().info('✅ Successfully fetched categories: $categoryList');

        // ✅ Save category list in SharedPreferences
        await sharedPref.callServiceMethod('setStringList', ['available_categories', categoryList]);

        // ✅ Store category levels in SharedPreferences
        for (String category in categoriesMap.keys) {
          int levels = categoriesMap[category]["levels"] ?? 2; // Default to 2 if missing
          await sharedPref.callServiceMethod('setInt', ['max_levels_$category', levels]);
          Logger().info("✅ Saved max levels for $category: $levels");
        }

        Logger().info('✅ Categories and levels saved in SharedPreferences.');

        // ✅ Now initialize SharedPreferences keys for levels, points, and guessed names
        await _initializeCategorySystem(categoryList, sharedPref);
      } else {
        Logger().error('❌ Failed to fetch categories. Unexpected response format: $response');
      }
    } catch (e) {
      Logger().error('❌ Error fetching categories: $e', error: e);
    }
  }

  Future<void> _initializeCategorySystem(List<String> categories, dynamic sharedPref) async {
    try {
      Logger().info("⚙️ Initializing SharedPreferences for levels, points, and guessed names...");

      for (String category in categories) {
        // ✅ Fetch max levels from SharedPreferences instead of assuming 5
        int maxLevels = await sharedPref.callServiceMethod('getInt', ['max_levels_$category']) ?? 0;

        // ✅ Default to level 1
        String levelKey = "level_$category";
        int currentLevel = await sharedPref.callServiceMethod('getInt', [levelKey]) ?? 1;
        await sharedPref.callServiceMethod('setInt', [levelKey, currentLevel]);

        for (int level = 1; level <= maxLevels; level++) {
          String pointsKey = "points_${category}_level$level";
          String guessedKey = "guessed_${category}_level$level";

          // ✅ Set default points
          int points = await sharedPref.callServiceMethod('getInt', [pointsKey]) ?? 0;
          await sharedPref.callServiceMethod('setInt', [pointsKey, points]);

          // ✅ Set empty guessed names list
          List<String> guessedNames = await sharedPref.callServiceMethod('getStringList', [guessedKey]) ?? [];
          await sharedPref.callServiceMethod('setStringList', [guessedKey, guessedNames]);

          Logger().info("✅ Initialized keys: $pointsKey, $guessedKey");
        }
      }

      Logger().info("✅ SharedPreferences system initialized successfully.");
    } catch (e) {
      Logger().error("❌ Error initializing category system: $e", error: e);
    }
  }


  Future<void> _initializeUserData() async {
    final sharedPref = servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      Logger().error('❌ SharedPrefManager not found.');
      return;
    }

    // ✅ Store user profile details if not already set
    String? username = await sharedPref.callServiceMethod('getString', ['username']);
    if (username == null) {
      await sharedPref.callServiceMethod('setString', ['username', 'Guest']);
      await sharedPref.callServiceMethod('setString', ['email', '']);
      await sharedPref.callServiceMethod('setString', ['password', '']);
    }

    // ✅ Check if categories are already saved
    List<String> categories = await sharedPref.callServiceMethod('getStringList', ['available_categories']) ?? [];
    if (categories.isEmpty) {
      Logger().info("📜 Categories not found. Fetching from backend...");
      await getCategories();
    } else {
      Logger().info("✅ Categories already initialized in SharedPreferences.");
      await _initializeCategorySystem(categories, sharedPref);
    }
  }


}
