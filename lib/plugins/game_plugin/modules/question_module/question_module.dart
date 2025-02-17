import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';

class QuestionModule extends ModuleBase {
  QuestionModule() {
    Logger().info('QuestionModule initialized.');
    registerMethod('getQuestion', getQuestion);
    registerMethod('checkAnswer', checkAnswer);
  }

  Future<List<String>> getGuessedNames(String category, int level) async {
    final sharedPref = ServicesManager().getService('shared_pref');

    if (sharedPref == null) {
      Logger().error("❌ SharedPreferences service not available.");
      return [];
    }

    String guessedKey = "guessed_${category}_level$level";
    List<String> guessedNames = await sharedPref.callServiceMethod('getStringList', [guessedKey]) ?? [];

    Logger().info("📜 Retrieved guessed names for $category Level $level: $guessedNames");

    return guessedNames;
  }

  Future<Map<String, dynamic>> getQuestion(int difficulty, String category, List<String> guessedNames) async {
    final connectionModule = ModuleManager().getModule('connection_module');

    if (connectionModule == null) {
      Logger().error("❌ ConnectionModule not found in QuestionModule.");
      return {"error": "Connection module not available"};
    }

    try {
      // ✅ Build request payload including guessed names
      final payload = {
        "level": difficulty,
        "category": category,
        "guessed_names": guessedNames,
      };

      Logger().info("⚡ Sending POST request to `/get-question` with payload: $payload");

      final response = await connectionModule.callMethod('sendPostRequest', [
        "/get-question",
        payload,
      ]);

      Logger().info("✅ Response from backend: $response");
      return response;
    } catch (e) {
      Logger().error("❌ Error fetching question from backend: $e", error: e);
      return {"error": "Failed to fetch question from server"};
    }
  }


  /// Checks if the given answer matches the correct answer
  bool checkAnswer(String input, String correctAnswer) {
    return input.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
  }
}
