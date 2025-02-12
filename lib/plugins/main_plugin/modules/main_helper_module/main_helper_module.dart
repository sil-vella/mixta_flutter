import 'dart:async';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../core/managers/state_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../../../utils/consts/theme_consts.dart';

class MainHelperModule extends ModuleBase {
  static MainHelperModule? _instance;
  final ServicesManager _servicesManager = ServicesManager();
  static final Random _random = Random();
  static final Logger _logger = Logger(); // Use a single logger instance

  MainHelperModule._internal() {
    _logger.info('MainHelperModule initialized.');
  }

  /// Factory method to ensure singleton
  factory MainHelperModule() {
    _instance ??= MainHelperModule._internal();
    return _instance!;
  }

  /// Retrieve background by index (looping if out of range)
  static String getBackground(int index) {
    if (AppBackgrounds.backgrounds.isEmpty) {
      _logger.error('No backgrounds available.');
      return ''; // Return an empty string or a default background
    }
    return AppBackgrounds.backgrounds[index % AppBackgrounds.backgrounds.length];
  }

  /// Retrieve a random background
  static String getRandomBackground() {
    if (AppBackgrounds.backgrounds.isEmpty) {
      _logger.error('No backgrounds available.');
      return ''; // Return an empty string or a default background
    }
    return AppBackgrounds.backgrounds[_random.nextInt(AppBackgrounds.backgrounds.length)];
  }

  /// Update user information in Shared Preferences
  Future<void> updateUserInfo(String key, dynamic value) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref != null) {
      try {
        if (value is String) {
          await sharedPref.callServiceMethod('setString', [key, value]);
        } else if (value is int) {
          await sharedPref.callServiceMethod('setInt', [key, value]);
        } else if (value is bool) {
          await sharedPref.callServiceMethod('setBool', [key, value]);
        } else if (value is double) {
          await sharedPref.callServiceMethod('setDouble', [key, value]);
        } else {
          _logger.error('Unsupported value type for key: $key');
          return;
        }
        _logger.info('Updated $key: $value');
      } catch (e) {
        _logger.error('Error updating user info: $e');
      }
    } else {
      _logger.error('SharedPrefManager not available.');
    }
  }

  /// Retrieve stored user information
  Future<dynamic> getUserInfo(String key) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref != null) {
      try {
        dynamic value;
        if (key == 'points') {
          value = await sharedPref.callServiceMethod('getInt', [key]);
        } else {
          value = await sharedPref.callServiceMethod('getString', [key]);
        }
        _logger.info('Retrieved $key: $value');
        return value;
      } catch (e) {
        _logger.error('Error retrieving user info: $e');
      }
    } else {
      _logger.error('SharedPrefManager not available.');
    }
    return null;
  }

  void startTimer(int seconds, Function callback) {
    final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);

    _logger.info("⏳ Timer started for $seconds seconds...");

    // ✅ Set initial state: timer is running
    stateManager.updatePluginState("game_timer", {
      "isRunning": true,
      "duration": seconds,
    });

    int remainingTime = seconds;

    Timer.periodic(Duration(seconds: 1), (timer) {
      remainingTime--;

      // ✅ Update state every second
      stateManager.updatePluginState("game_timer", {
        "isRunning": true,
        "duration": remainingTime,
      });

      if (remainingTime <= 0) {
        timer.cancel();
        _logger.info("✅ Timer completed after $seconds seconds.");

        // ✅ Set final state: timer stopped
        stateManager.updatePluginState("game_timer", {
          "isRunning": false,
          "duration": 0,
        });

        callback(); // Execute callback function
      }
    });
  }


}
