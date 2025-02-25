import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mixta_guess_who/core/00_base/module_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../core/services/shared_preferences.dart';
import '../../../../tools/logging/logger.dart';
import '../connections_module/connections_module.dart';

class LoginModule extends ModuleBase {
  static final Logger _log = Logger(); // ✅ Use a static logger for static methods

  /// ✅ Constructor - No stored instances, dependencies are fetched dynamically
  LoginModule() : super("login_module") {
    _log.info('✅ LoginModule initialized.');
  }

  Future<Map<String, dynamic>> registerUser({
    required BuildContext context,
    required String username,
    required String email,
    required String password,
  }) async {
    final moduleManager = Provider.of<ModuleManager>(context, listen: false);
    final servicesManager = Provider.of<ServicesManager>(context, listen: false);
    final sharedPref = servicesManager.getService<SharedPrefManager>('shared_pref');
    final connectionModule = moduleManager.getLatestModule<ConnectionsModule>();

    if (connectionModule == null || sharedPref == null) {
      _log.error("❌ Missing required modules.");
      return {"error": "Service not available."};
    }

    List<String> categories = sharedPref.getStringList('available_categories') ?? ['mixed'];
    Map<String, int> categoryLevels = {
      for (var category in categories) category: sharedPref.getInt('max_levels_$category') ?? 5
    };

    Map<String, dynamic> categoryProgress = {
      for (var category in categories)
        category: {
          "points": sharedPref.getInt('points_${category}_level1') ?? 0,
          "level": sharedPref.getInt('level_$category') ?? 1
        }
    };

    Map<String, Map<String, List<String>>> guessedNames = {
      for (var category in categories)
        category: {
          for (int level = 1; level <= (categoryLevels[category] ?? 5); level++)
            "level_$level": sharedPref.getStringList("guessed_${category}_level$level") ?? []
        }
    };

    try {
      _log.info("⚡ Sending registration request...");
      final response = await connectionModule.sendPostRequest(
        "/register",
        {
          "username": username,
          "email": email,
          "password": password,
          "category_progress": categoryProgress,
          "guessed_names": guessedNames,
        },
      );

      if (response?["message"] == "User registered successfully") {
        _log.info("✅ User registered successfully. Auto logging in...");
        return await loginUser(context: context, email: email, password: password);
      } else {
        return {"error": response?["error"] ?? "Failed to register user."};
      }
    } catch (e) {
      _log.error("❌ Registration error: $e");
      return {"error": "Server error. Check network connection."};
    }
  }

  Future<Map<String, dynamic>> loginUser({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    final moduleManager = Provider.of<ModuleManager>(context, listen: false);
    final servicesManager = Provider.of<ServicesManager>(context, listen: false);
    final sharedPref = servicesManager.getService<SharedPrefManager>('shared_pref');
    final connectionModule = moduleManager.getLatestModule<ConnectionsModule>();

    if (connectionModule == null || sharedPref == null) {
      _log.error("❌ Missing required modules.");
      return {"error": "Service not available."};
    }

    try {
      _log.info("⚡ Sending login request...");
      final response = await connectionModule.sendPostRequest(
        "/login",
        {"email": email, "password": password},
      );

      if (response?["message"] == "Login successful" && response?["user"]?["id"] != null) {
        final user = response["user"];
        sharedPref.setString('email', email);
        sharedPref.setString('username', user["username"]);
        sharedPref.setString('password', password);
        sharedPref.setInt('user_id', user["id"]);
        sharedPref.setBool('is_logged_in', true);

        if (user.containsKey("category_progress")) {
          user["category_progress"].forEach((category, progress) {
            sharedPref.setInt('points_${category}_level${progress["level"]}', progress["points"]);
            sharedPref.setInt('level_$category', progress["level"]);
          });
        }

        if (user.containsKey("guessed_names")) {
          user["guessed_names"].forEach((category, levels) {
            levels.forEach((levelKey, names) {
              sharedPref.setStringList("guessed_${category}_$levelKey", List<String>.from(names));
            });
          });
        }

        return {"success": "Login Successful!"};
      } else {
        return {"error": response?["error"] ?? "Invalid email or password."};
      }
    } catch (e) {
      _log.error("❌ Login error: $e");
      return {"error": "Server error. Check network connection."};
    }
  }

  Future<Map<String, dynamic>> deleteUser(BuildContext context) async {
    final moduleManager = Provider.of<ModuleManager>(context, listen: false);
    final servicesManager = Provider.of<ServicesManager>(context, listen: false);
    final sharedPref = servicesManager.getService<SharedPrefManager>('shared_pref');
    final connectionModule = moduleManager.getLatestModule<ConnectionsModule>();

    if (connectionModule == null || sharedPref == null) {
      _log.error("❌ Missing required modules.");
      return {"error": "Service not available."};
    }

    int? userId = sharedPref.getInt('user_id');
    if (userId == null) {
      _log.error("❌ No user ID found. Cannot delete account.");
      return {"error": "User not logged in or ID missing."};
    }

    try {
      _log.info("⚡ Sending delete request for User ID: $userId...");
      final response = await connectionModule.sendPostRequest(
        "/delete-user",
        {"user_id": userId},
      );

      if (response?.containsKey('message') == true) {
        sharedPref.remove('user_id');
        sharedPref.remove('username');
        sharedPref.remove('email');
        sharedPref.remove('is_logged_in');

        return {"success": "Account deleted successfully!"};
      } else {
        return {"error": response?["error"] ?? "Failed to delete account."};
      }
    } catch (e) {
      _log.error("❌ Error deleting user: $e");
      return {"error": "Server error. Check network connection."};
    }
  }
}