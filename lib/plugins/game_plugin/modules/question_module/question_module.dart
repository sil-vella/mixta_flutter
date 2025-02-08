import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../tools/logging/logger.dart';

class QuestionModule extends ModuleBase {
  QuestionModule() {
    Logger().info('QuestionModule initialized.');
    registerMethod('getQuestion', getQuestion);
    registerMethod('checkAnswer', checkAnswer);
  }

  /// Fetches a question from the backend based on difficulty level
  Future<Map<String, dynamic>> getQuestion(int difficulty) async {
    final connectionModule = ModuleManager().getModule('connection_module');

    if (connectionModule == null) {
      Logger().error("❌ ConnectionModule not found in QuestionModule.");
      return {"error": "Connection module not available"};
    } else {
      Logger().info("✅ ConnectionModule found in QuestionModule.");
    }

    try {
      Logger().info("⚡ Sending GET request to `/get-question?level=$difficulty`...");
      final response = await connectionModule.callMethod(
          'sendGetRequest',
          ["/get-question?level=$difficulty"]
      );

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
