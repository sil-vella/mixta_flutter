import 'package:mixta_guess_who/core/00_base/module_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';

class LoginModule extends ModuleBase {
  final Logger logger = Logger();
  final ServicesManager servicesManager = ServicesManager();
  final ModuleManager moduleManager = ModuleManager();

  static LoginModule? _instance;

  /// Factory method for Singleton instance
  factory LoginModule() {
    _instance ??= LoginModule._internal();
    return _instance!;
  }

  LoginModule._internal();

  /// ✅ User Registration Logic (Auto-login after success)
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    final connectionModule = moduleManager.getModule('connection_module');
    final sharedPrefService = servicesManager.getService('shared_pref');

    if (connectionModule == null || sharedPrefService == null) {
      logger.error("❌ Missing required modules.");
      return {"error": "Service not available."};
    }

    final points = await sharedPrefService.callServiceMethod('getInt', ['points']) ?? 0;
    final level = await sharedPrefService.callServiceMethod('getInt', ['level']) ?? 1;

    try {
      logger.info("⚡ Sending registration request to `/register`...");

      final response = await connectionModule.callMethod('sendPostRequest', [
        "/register",
        {
          "username": username,
          "email": email,
          "password": password,
          "points": points,
          "level": level,
        }
      ]);

      if (response != null && response['message'] == "User registered successfully") {
        logger.info("✅ User registered successfully. Auto logging in...");
        return await loginUser(email: email, password: password);
      } else {
        return {"error": response?["error"] ?? "Failed to register user."};
      }
    } catch (e) {
      logger.error("❌ Registration error: $e");
      return {"error": "Server error. Check network connection."};
    }
  }

  /// ✅ User Login Logic
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password, // ✅ Store original password
  }) async {
    final connectionModule = moduleManager.getModule('connection_module');
    final sharedPrefService = servicesManager.getService('shared_pref');

    if (connectionModule == null || sharedPrefService == null) {
      logger.error("❌ Missing required modules.");
      return {"error": "Service not available."};
    }

    try {
      logger.info("⚡ Retrieving user points and level before login...");

      // ✅ Get existing points & level from SharedPreferences
      final existingPoints = await sharedPrefService.callServiceMethod('getInt', ['points']) ?? 0;
      final existingLevel = await sharedPrefService.callServiceMethod('getInt', ['level']) ?? 1;

      logger.info("🔹 Sending login request with: email=$email, level=$existingLevel, points=$existingPoints");

      final response = await connectionModule.callMethod('sendPostRequest', [
        "/login",
        {
          "email": email,
          "password": password, // ✅ Send original password
        }
      ]);

      if (response != null && response.containsKey('message') && response['message'] == "Login successful") {
        if (!response.containsKey("user") || !response["user"].containsKey("id")) {
          return {"error": "Invalid server response."};
        }

        final user = response["user"]; // Extract user object

        // ✅ Store updated user details in SharedPreferences
        await sharedPrefService.callServiceMethod('setString', ['email', email]);
        await sharedPrefService.callServiceMethod('setString', ['username', user["username"]]);
        await sharedPrefService.callServiceMethod('setString', ['password', password]); // ✅ Save original password
        await sharedPrefService.callServiceMethod('setInt', ['user_id', user["id"]]);  // ✅ Save user ID
        await sharedPrefService.callServiceMethod('setBool', ['is_logged_in', true]);

        // ✅ Always update SharedPreferences with backend values (even if higher locally)
        final backendPoints = user.containsKey("points") ? user["points"] : 0;
        final backendLevel = user.containsKey("level") ? user["level"] : 1;

        await sharedPrefService.callServiceMethod('setInt', ['points', backendPoints]); // ✅ Always update points
        await sharedPrefService.callServiceMethod('setInt', ['level', backendLevel]);   // ✅ Always update level

        logger.info("✅ User login successful. User ID: ${user["id"]}");
        return {"success": "Login Successful!"};
      } else {
        return {"error": response?["error"] ?? "Invalid email or password."};
      }
    } catch (e) {
      logger.error("❌ Login error: $e");
      return {"error": "Server error. Check network connection."};
    }
  }
}
