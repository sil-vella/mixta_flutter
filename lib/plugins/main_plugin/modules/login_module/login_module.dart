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


  /// ✅ Register a new user and store category-based points & levels
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

    // ✅ Fetch available categories from SharedPreferences
    List<String> categories = await sharedPrefService.callServiceMethod('getStringList', ['available_categories']) ?? [];

    if (categories.isEmpty) {
      logger.error("⚠️ No categories found in SharedPreferences. Defaulting to 'mixed'.");
      categories = ['mixed']; // ✅ Ensure at least one category exists
    }

    // ✅ Fetch points & levels for each category from SharedPreferences
    Map<String, dynamic> categoryProgress = {};

    for (String category in categories) {
      int currentLevel = await sharedPrefService.callServiceMethod('getInt', ['level_$category']) ?? 1;
      int categoryPoints = await sharedPrefService.callServiceMethod('getInt', ['points_${category}_level$currentLevel']) ?? 0;

      categoryProgress[category] = {
        "points": categoryPoints,
        "level": currentLevel
      };
    }

    // ✅ Fetch max levels per category from SharedPreferences
    Map<String, Map<String, List<String>>> guessedNames = {};
    Map<String, dynamic> categoryData = await sharedPrefService.callServiceMethod('getMap', ['category_data']) ?? {};

    for (String category in categories) {
      Map<String, List<String>> levelGuessedNames = {};

      int maxLevels = categoryData[category]?["levels"] ?? 5; // ✅ Dynamically get max levels

      for (int lvl = 1; lvl <= maxLevels; lvl++) {
        String guessedKey = "guessed_${category}_level$lvl";
        List<String> guessedList = await sharedPrefService.callServiceMethod('getStringList', [guessedKey]) ?? [];

        levelGuessedNames["level_$lvl"] = guessedList; // ✅ Store empty lists too for consistency
      }

      guessedNames[category] = levelGuessedNames; // ✅ Store all category levels
    }

    try {
      logger.info("⚡ Sending registration request to `/register` with category-based data...");

      final response = await connectionModule.callMethod('sendPostRequest', [
        "/register",
        {
          "username": username,
          "email": email,
          "password": password,
          "category_progress": categoryProgress, // ✅ Points & levels per category
          "guessed_names": guessedNames, // ✅ Guessed names per category & level
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

  /// ✅ User Login Logic (Updated for Category, Level, and Guessed Names)
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
      logger.info("⚡ Sending login request...");

      final response = await connectionModule.callMethod('sendPostRequest', [
        "/login",
        {
          "email": email,
          "password": password,
        }
      ]);

      if (response != null && response.containsKey('message') && response['message'] == "Login successful") {
        if (!response.containsKey("user") || !response["user"].containsKey("id")) {
          return {"error": "Invalid server response."};
        }

        final user = response["user"];

        // ✅ Store updated user details in SharedPreferences
        await sharedPrefService.callServiceMethod('setString', ['email', email]);
        await sharedPrefService.callServiceMethod('setString', ['username', user["username"]]);
        await sharedPrefService.callServiceMethod('setString', ['password', password]); // ✅ Save original password
        await sharedPrefService.callServiceMethod('setInt', ['user_id', user["id"]]);  // ✅ Save user ID
        await sharedPrefService.callServiceMethod('setBool', ['is_logged_in', true]);

        logger.info("✅ User login successful. User ID: ${user["id"]}");

        // ✅ Fetch and update category-based progress
        if (user.containsKey("category_progress") && user["category_progress"] is Map<String, dynamic>) {
          Map<String, dynamic> categoryProgress = user["category_progress"];

          for (String category in categoryProgress.keys) {
            Map<String, dynamic> progress = categoryProgress[category];
            int points = progress.containsKey("points") ? progress["points"] : 0;
            int level = progress.containsKey("level") ? progress["level"] : 1;

            await sharedPrefService.callServiceMethod('setInt', ['points_${category}_level$level', points]);
            await sharedPrefService.callServiceMethod('setInt', ['level_$category', level]);

            logger.info("📊 Updated progress for $category Level $level: Points=$points | Level=$level");
          }
        } else {
          logger.error("⚠️ No category progress found in the login response.");
        }

        // ✅ Fetch and update guessed names from the backend
        if (user.containsKey("guessed_names") && user["guessed_names"] is Map<String, dynamic>) {
          Map<String, dynamic> guessedNames = user["guessed_names"];

          for (String category in guessedNames.keys) {
            Map<String, dynamic> levelGuessedNames = guessedNames[category]; // ✅ Ensure levels exist

            for (String levelKey in levelGuessedNames.keys) {
              List<String> namesList = List<String>.from(levelGuessedNames[levelKey] ?? []);
              if (namesList.isNotEmpty) {
                String guessedKey = "guessed_${category}_${levelKey.replaceAll("level_", "level")}";
                await sharedPrefService.callServiceMethod('setStringList', [guessedKey, namesList]);

                logger.info("📜 Updated guessed names for $category $levelKey: $namesList");
              }
            }
          }
        } else {
          logger.error("⚠️ No guessed names found in the login response.");
        }

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
