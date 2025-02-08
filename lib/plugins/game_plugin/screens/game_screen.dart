import 'package:flutter/material.dart';
import '../../../core/00_base/screen_base.dart';
import '../../../tools/logging/logger.dart';
import '../modules/game_play_module/game_play_module.dart';

class GameScreen extends BaseScreen {
  const GameScreen({Key? key}) : super(key: key);

  @override
  String computeTitle(BuildContext context) {
    return "Guess The Actor!";
  }

  @override
  GameScreenState createState() => GameScreenState();
}

class GameScreenState extends BaseScreenState<GameScreen> {
  late final GamePlayModule gamePlayModule;
  late final dynamic interstitialAdModule;
  late final dynamic rewardedAdModule;

  @override
  void initState() {
    super.initState();
    Logger().info("Initializing GameScreen...");
    // ✅ Retrieve Managers from AppManager
    moduleManager = appManager.moduleManager;

    // ✅ Retrieve GamePlayModule from ModuleManager
    gamePlayModule = moduleManager.getModule('game_play_module') ?? GamePlayModule();

    // ✅ Fetch question data
    gamePlayModule.fetchQuestion(() {
      setState(() {});
    });

    // ✅ Retrieve Interstitial Ad Module
    interstitialAdModule = moduleManager.getModule('admobs_interstitial_ad_module');

    // ✅ Retrieve Rewarded Ad Module
    rewardedAdModule = moduleManager.getModule('admobs_rewarded_ad_module');
  }

  /// ✅ Handles answer selection, shows appropriate ad
  void _handleAnswer(String selectedImage) {
    gamePlayModule.checkAnswer(selectedImage, () => setState(() {}));

    if (gamePlayModule.feedbackMessage.contains("Correct")) {
      // ✅ Show interstitial ad if correct
      if (interstitialAdModule != null) {
        Logger().info("📢 Showing Interstitial Ad...");
        interstitialAdModule.callMethod("showInterstitialAd");
      } else {
        Logger().error("❌ InterstitialAdModule not found!");
      }
    } else {
      // ✅ Show rewarded ad if incorrect
      if (rewardedAdModule != null) {
        Logger().info("🎬 Showing Rewarded Ad for retry...");
        rewardedAdModule.callMethod("showRewardedAd", {
          "onUserEarnedReward": () {
            Logger().info("🎁 User watched ad and earned a retry!");
          }
        });

      } else {
        Logger().error("❌ RewardedAdModule not found!");
      }
    }
  }



  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: [
        // ✅ Game Content (Uses Expanded to fill space)
        Expanded(
          child: Center(
            child: gamePlayModule.isLoading
                ? const CircularProgressIndicator()
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ 2x2 Grid Layout for 4 images
                GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // ✅ 2 images per row
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: gamePlayModule.imageOptions.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _handleAnswer(gamePlayModule.imageOptions[index]),
                      child: Image.network(
                        gamePlayModule.imageOptions[index],
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ✅ Display the fact below the images
                Text(
                  gamePlayModule.question?['facts']?.join("\n- ") ?? "No facts available",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),

                // ✅ Display Feedback Message
                Text(
                  gamePlayModule.feedbackMessage,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: gamePlayModule.feedbackMessage.contains("Correct")
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ),

      ],
    );
  }
}
