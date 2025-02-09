import 'dart:math';
import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../rewards_module/rewards_module.dart';

class GamePlayModule extends ModuleBase {
  final Logger logger = Logger();
  final ServicesManager servicesManager = ServicesManager(); // ✅ Get Shared Pref Service
  Map<String, dynamic>? question;
  bool isLoading = true;
  String feedbackMessage = "";
  List<String> imageOptions = []; // ✅ Store shuffled images

  /// Fetch user level and request a question from backend
  Future<void> RoundInit(Function updateState) async {
    final sharedPref = servicesManager.getService(
        'shared_pref'); // ✅ Use SharedPref Service
    final questionModule = ModuleManager().getModule('question_module');

    if (sharedPref == null) {
      logger.error("❌ SharedPrefManager not found!");
      return;
    }

    if (questionModule == null) {
      logger.error("❌ QuestionModule not found!");
      return;
    }

    try {
      // ✅ Get user's level using `SharedPrefManager`
      final level = await sharedPref.callServiceMethod('getInt', ['level']) ??
          1;
      logger.info("🏆 User level retrieved from SharedPref: $level");

      // ✅ Fetch question based on level
      final response = await questionModule.callMethod('getQuestion', [level]);

      if (response.containsKey("error")) {
        logger.error("❌ Error fetching question: ${response['error']}");
      } else {
        question = response;
        isLoading = false;

        // ✅ Prepare the shuffled images (correct + 3 distractors)
        imageOptions =
        [response['image_url'], ...response['distractor_images']];
        imageOptions.shuffle(Random()); // ✅ Randomize order

        // ✅ Update UI State in GameScreen
        updateState();
        logger.info("✅ Question retrieved successfully: $response");
      }
    } catch (e) {
      logger.error("❌ Failed to fetch question: $e", error: e);
    }
  }

  void checkAnswer(String selectedImage, Function updateState) async {
    final correctImage = question?['image_url'] ?? "";

    if (selectedImage == correctImage) {
      feedbackMessage = "🎉 Correct!";

      // ✅ Get RewardsModule from ModuleManager
      final rewardsModule = ModuleManager().getModule<RewardsModule>('rewards_module');

      if (rewardsModule != null) {
        // ✅ First, get the points based on the action type
        int points = await rewardsModule.getPoints('no_hint');

        // ✅ Then, save the earned points
        int totalPoints = await rewardsModule.saveReward(points);

        logger.info("🏆 User earned $points points! New total: $totalPoints");
      } else {
        logger.error("❌ RewardsModule not found.");
      }
    } else {
      feedbackMessage = "❌ Wrong! Try Again.";
    }

    // ✅ Update UI State in GameScreen
    updateState();

    logger.info("✅ User selected: $selectedImage | Correct: $correctImage");
  }
}