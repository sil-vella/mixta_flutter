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

    final gameRoundState = stateManager.getPluginState<Map<String, dynamic>>('game_round');
    final int roundNumber = gameRoundState?['roundNumber'] ?? 1;

    int updatedNumber = roundNumber + 1; // ✅ Corrected increment syntax

    stateManager.updatePluginState("game_round", {
      "roundNumber": updatedNumber, // ✅ Correctly updated value
    });

    // ✅ Call method every 4 increments
    if (updatedNumber % 4 == 0) {
      final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);
      final rewardedAdModule = ModuleManager().getModule<RewardedAdModule>('admobs_rewarded_ad_module');
      final mainHelper = ModuleManager().getModule<MainHelperModule>('main_helper_module');

      if (rewardedAdModule != null && mainHelper != null) {
        mainHelper.pauseTimer(); // ✅ Pause timer when ad starts

        rewardedAdModule.showAd([
              () {
                Logger().info("Advert Played.");
          },
              () {
            // ✅ Resume timer only after ad is fully dismissed
            Future.delayed(const Duration(milliseconds: 500), () {
              mainHelper.resumeTimer(() {
                Logger().info("⏳ Timer resumed after ad was closed.");
              });
            });
          }
        ]);

      } else {
        Logger().info("❌ RewardedAdModule or MainHelperModule not found!");
      }
    }

    await resetState();  // ✅ Ensure state resets fully before proceeding

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

    try {
      // ✅ Get user's level using `SharedPrefManager`
      final level = await sharedPref.callServiceMethod('getInt', ['level']) ?? 1;
      logger.info("🏆 User level retrieved from SharedPref: $level");

      // ✅ Fetch question based on level
      final response = await questionModule.callMethod('getQuestion', [level]);

      if (response.containsKey("error")) {
        logger.error("❌ Error fetching question: ${response['error']}");
      } else {
        question = response;
        isLoading = false;

        // ✅ Prepare the shuffled images (correct + 3 distractors)
        imageOptions = [response['image_url'], ...response['distractor_images']];
        imageOptions.shuffle(Random()); // ✅ Randomize order

        // ✅ Update UI State in GameScreen
        updateState();
        logger.info("✅ Question retrieved successfully: $response");
      }
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
    final correctImage = question?['image_url'] ?? "";
    final rewardsModule = ModuleManager().getModule<RewardsModule>('rewards_module');
    final stateManager = Provider.of<StateManager>(AppManager.globalContext, listen: false);

    if (selectedImage == correctImage) {
      feedbackMessage = "🎉 Correct!";

      if (rewardsModule != null && stateManager != null) {
        // ✅ Retrieve 'hint' state from StateManager
        final gameRoundState = stateManager.getPluginState<Map<String, dynamic>>('game_round');
        final bool hintUsed = gameRoundState?['hint'] ?? false;

        // ✅ Determine points based on hint usage
        String pointsKey = hintUsed ? 'hint' : 'no_hint';
        int points = await rewardsModule.getPoints(pointsKey);

        // ✅ Save the earned points and get `points`, `endGame`, and `levelUp`
        final rewardData = await rewardsModule.saveReward(points);
        int totalPoints = rewardData["points"];
        bool endGame = rewardData["endGame"];
        bool levelUp = rewardData["levelUp"];

        logger.info("🏆 User earned $points points with key '$pointsKey'! New total: $totalPoints | EndGame: $endGame | LevelUp: $levelUp");

        // ✅ Update game state with level-up or end-game status
        stateManager.updatePluginState("game_round", {
          if (levelUp) "levelUp": true,
          if (endGame) "endGame": true,
        });

      } else {
        logger.error("❌ RewardsModule or StateManager not found.");
      }
    } else {
      feedbackMessage = "❌ Incorrect.";
    }

    updateState();
    logger.info("✅ User selected: $selectedImage | Correct: ${question?['image_url']}");

    // ✅ Round will reinitialize after user closes the feedback message
  }

void showGameOverScreen() {
  logger.info("🎯 Game over! Player reached max level.");
}

}