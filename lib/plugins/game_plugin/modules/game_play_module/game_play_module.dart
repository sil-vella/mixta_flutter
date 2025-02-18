import 'dart:math';
import 'dart:convert'; // ✅ Required for jsonEncode & jsonDecode
import 'package:mixta_guess_who/plugins/main_plugin/modules/main_helper_module/main_helper_module.dart';
import 'package:provider/provider.dart';

import '../../../../core/00_base/module_base.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/managers/module_manager.dart';
import '../../../../core/managers/services_manager.dart';
import '../../../../core/managers/state_manager.dart';
import '../../../../tools/logging/logger.dart';
import '../../../adverts_plugin/modules/admobs/rewarded/rewarded_ad.dart';
import '../rewards_module/rewards_module.dart';
import 'config/gameplaymodule_config.dart';

class GamePlayModule extends ModuleBase {
  final Logger logger = Logger();
  final ServicesManager _servicesManager = ServicesManager();
  final MainHelperModule _mainHelperModule = MainHelperModule();


  Map<String, dynamic>? question;
  bool isLoading = true;
  String feedbackMessage = "";
  List<String> imageOptions = []; // ✅ Store shuffled images

  Future<void> resetState() async {
    final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);

    stateManager.updatePluginState("game_timer", {
      "isRunning": false,
      "duration": 30,
    });

    stateManager.updatePluginState("game_round", {
      "hint": false,
      "imagesLoaded": false,
      "factLoaded": false,
      "levelUp": false,
      "endGame": false,
    });

    logger.info("✅ Game state reset completed.");

    // ✅ Wait a frame to ensure updates are reflected before proceeding
    await Future.delayed(Duration(milliseconds: 50));
  }

  /// Fetch user level and request a question from backend
  Future<void> roundInit(Function updateState) async {
    final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);
    final sharedPref = _servicesManager.getService('shared_pref');
    final questionModule = ModuleManager().getModule('question_module');

    if (sharedPref == null) {
      logger.error("❌ SharedPrefManager not found!");
      return;
    }

    if (questionModule == null) {
      logger.error("❌ QuestionModule not found!");
      return;
    }

    // ✅ Retrieve game round state
    final gameRoundState = stateManager.getPluginState<Map<String, dynamic>>('game_round');
    final int roundNumber = gameRoundState?['roundNumber'] ?? 1;
    int updatedNumber = roundNumber + 1; // ✅ Increment round

    stateManager.updatePluginState("game_round", {
      "roundNumber": updatedNumber, // ✅ Update state
    });

    // ✅ Show an ad every 5 rounds
    if (updatedNumber % 5 == 0) {
      final rewardedAdModule = ModuleManager().getModule<RewardedAdModule>('admobs_rewarded_ad_module');
      final mainHelper = ModuleManager().getModule<MainHelperModule>('main_helper_module');

      if (rewardedAdModule != null && mainHelper != null) {
        mainHelper.pauseTimer(); // ✅ Pause timer for ad

        rewardedAdModule.showAd([
              () => Logger().info("Advert Played."),
              () {
            Future.delayed(const Duration(milliseconds: 500), () {
              mainHelper.resumeTimer(() {
                Logger().info("⏳ Timer resumed after ad.");
              });
            });
          }
        ]);
      } else {
        Logger().info("❌ RewardedAdModule or MainHelperModule not found!");
      }
    }

    await resetState();  // ✅ Ensure state resets before fetching new data

    try {
      // ✅ Get user's level and category from SharedPreferences
      final category = await sharedPref.callServiceMethod('getString', ['category']) ?? "mixed";
      final int level = await sharedPref.callServiceMethod('getInt', ['level_$category']) ?? 1;

      logger.info("🏆 User category: $category | Level: $level");

      final guessedKey = "guessed_${category}_level$level";
      List<String> guessedNames = await sharedPref.callServiceMethod('getStringList', [guessedKey]) ?? [];

// ✅ Log before sending request
      logger.info("📜 Final guessed names sent to backend: $guessedNames");

// ✅ Fetch question with updated guessed list
      final response = await questionModule.callMethod('getQuestion', [level, category, guessedNames]);

      if (response.containsKey("error")) {
        if (response["error"].contains("No more actors left")) {
          logger.info("🏆 All celebrities have been guessed! Consider resetting.");
        } else {
          logger.error("❌ Error fetching question: ${response['error']}");
        }
        return;
      }

      // ✅ Process the received question
      question = response;
      isLoading = false;

      // ✅ Prepare shuffled images (correct + 3 distractors)
      imageOptions = [response['image_url'], ...response['distractor_images']];
      imageOptions.shuffle(Random());

      // ✅ Update UI State in GameScreen
      updateState();
      logger.info("✅ Question retrieved successfully: $response");

    } catch (e) {
      logger.error("❌ Failed to fetch question: $e", error: e);
    }
  }

  Future<void> setTimer(Function onTimeout) async {
    final sharedPref = _servicesManager.getService('shared_pref');

    if (sharedPref == null) {
      logger.error("❌ SharedPrefManager not found!");
      return;
    }

    try {
      // ✅ Get user's level
      final int level = await sharedPref.callServiceMethod('getInt', ['level']) ?? 1;

      // ✅ Don't set a timer if level is 2 or less
      if (level <= 2) {
        logger.info("⏳ Skipping timer. Level is $level.");
        return;
      }

      // ✅ Get the corresponding timer duration for the level (default to 10s if not set)
      final int duration = (GamePlayConfig.levelTimers[level] ?? 10).toInt();

      logger.info("⏳ Starting timer for Level $level: $duration seconds");

      final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);

      // ✅ Update the game timer state before starting
      stateManager.updatePluginState("game_timer", {
        "isRunning": true,
        "duration": duration,
      });

      // ✅ Start timer with dynamic duration
      _mainHelperModule.startTimer(duration, () {
        logger.info("⏰ Timer finished! Triggering timeout answer.");

        // ✅ Update state when timer stops
        stateManager.updatePluginState("game_timer", {
          "isRunning": false,
          "duration": 0,
        });

        onTimeout(); // ✅ Now directly calls _handleAnswer from GameScreen
      });

    } catch (e) {
      logger.error("❌ Failed to start timer: $e", error: e);
    }
  }

  void checkAnswer(String selectedImage, Function updateState, {bool timeUp = false}) async {
    logger.info("🏆 Checking answer...");

    final correctImage = question?['image_url'] ?? "";
    final rewardsModule = ModuleManager().getModule<RewardsModule>('rewards_module');
    final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);

    if (rewardsModule == null || stateManager == null) {
      logger.error("❌ RewardsModule or StateManager not found.");
      return;
    }

    // ✅ Extract category, level, and correct actor
    String category = question?["category"] ?? "mixed";
    int level = int.tryParse(question?["level"]?.toString() ?? "1") ?? 1;
    String correctActor = question?["actor"] ?? "";

    logger.info("📌 Checking answer for: $correctActor (Category: $category, Level: $level)");

    if (selectedImage == correctImage) {
      feedbackMessage = "🎉 Correct!";

      // ✅ Retrieve 'hint' state from StateManager
      final gameRoundState = stateManager.getPluginState<Map<String, dynamic>>('game_round');
      final bool hintUsed = gameRoundState?['hint'] ?? false;

      // ✅ Determine points based on hint usage
      String pointsKey = hintUsed ? 'hint' : 'no_hint';
      int points = await rewardsModule.getPoints(pointsKey, category, level);

      // ✅ Call saveReward with all necessary data
      final rewardData = await rewardsModule.saveReward(
        points: points,
        category: category,
        level: level,
        guessedActor: correctActor,
      );

      logger.info("🏆 Updated Rewards: ${rewardData}");

      // ✅ Update game state with level-up or end-game status
      stateManager.updatePluginState("game_round", {
        if (rewardData["levelUp"]) "levelUp": true,
        if (rewardData["endGame"]) "endGame": true,
      });

    } else {
      feedbackMessage = "❌ Incorrect.";
    }

    updateState();
    logger.info("✅ User selected: $selectedImage | Correct: ${question?['image_url']}");
  }

void showGameOverScreen() {
  logger.info("🎯 Game over! Player reached max level.");
}

}