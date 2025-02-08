import 'package:flutter/material.dart';
import '../../../core/00_base/screen_base.dart';
import '../../../core/managers/app_manager.dart';
import '../../../core/managers/module_manager.dart';
import '../../../core/managers/services_manager.dart';
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
  final Logger logger = Logger();
  final AppManager appManager = AppManager(); // ✅ Get AppManager Instance
  late final ServicesManager servicesManager;
  late final ModuleManager moduleManager;
  late final GamePlayModule gamePlayModule;
  late final dynamic bannerAdModule;

  @override
  void initState() {
    super.initState();

    // ✅ Retrieve Managers from AppManager
    servicesManager = appManager.servicesManager;
    moduleManager = appManager.moduleManager;

    // ✅ Retrieve GamePlayModule from ModuleManager
    gamePlayModule = moduleManager.getModule('game_play_module') ?? GamePlayModule();

    // ✅ Fetch question data
    gamePlayModule.fetchQuestion(() {
      setState(() {});
    });

    // ✅ Retrieve Banner Ad Module
    bannerAdModule = moduleManager.getModule('admobs_banner_ad_module');
    if (bannerAdModule != null) {
      bannerAdModule.callMethod("loadBannerAd");
    } else {
      logger.error("❌ BannerAdModule not found!");
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
                      onTap: () => gamePlayModule.checkAnswer(
                          gamePlayModule.imageOptions[index], () => setState(() {})),
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

        // ✅ Banner Ad at Bottom
        if (bannerAdModule != null)
          Container(
            height: 50, // ✅ Standard banner ad height
            alignment: Alignment.center,
            child: bannerAdModule?.callMethod("getBannerWidget", [context]) ?? const SizedBox(),
            ),
      ],
    );
  }
}
