import 'package:guess_the_celebrity/core/00_base/module_base.dart';
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
    required String password,
  }) async {
    final connectionModule = moduleManager.getModule('connection_module');
    final sharedPrefService = servicesManager.getService('shared_pref');

    if (connectionModule == null || sharedPrefService == null) {
      logger.error("❌ Missing required modules.");
      return {"error": "Service not available."};
    }

    try {
      logger.info("⚡ Sending login request to `/login`...");

      final response = await connectionModule.callMethod('sendPostRequest', [
        "/login",
        {
          "email": email,
          "password": password,
        }
      ]);

      if (response != null && response.containsKey('success') && response['success'] == true) {
        if (!response.containsKey("username") || !response.containsKey("points") || !response.containsKey("level")) {
          return {"error": "Invalid server response."};
        }

        // ✅ Save user details to SharedPreferences
        await sharedPrefService.callServiceMethod('setString', ['email', email]);
        await sharedPrefService.callServiceMethod('setString', ['username', response["username"]]);
        await sharedPrefService.callServiceMethod('setInt', ['points', response["points"]]);
        await sharedPrefService.callServiceMethod('setInt', ['level', response["level"]]);
        await sharedPrefService.callServiceMethod('setBool', ['is_logged_in', true]);

        logger.info("✅ User login successful.");
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
